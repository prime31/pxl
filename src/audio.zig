//! pxl.audio — a software mixer and asset manager on top of `pxl.saudio`.
//!
//! `AudioManager` loads each sound once (streamed from disk or fully
//! decoded in memory), plays it as independent `Playback` instances, and
//! routes them through buses with optional effect chains (lowpass,
//! highpass, delay).
//!
//! Streamed sounds share a single decode cursor, so they allow only one
//! active playback at a time; in-memory buffers allow unlimited overlap.
//! Call `update()` once per frame to mix and push audio.
//!
//! ```
//! var audio: pxl.audio.AudioManager = .{};
//! audio.init(.{});
//! defer audio.deinit();
//!
//! const music = try audio.load("music.ogg", .{ .streamed = true });
//! const coin = try audio.load("coin.ogg", .{});
//!
//! const music_pb = audio.play(music, .{ .loop = true }) orelse ...;
//! audio.playOneShot(coin, .{ .pan = -0.5, .pitch = 1.2 });
//! ```

const std = @import("std");
const pxl = @import("pxl.zig");

/// Frames decoded per refill for streamed sounds.
pub const ChunkFrames = 4096;

/// Read one channel of an interleaved source frame. Mono buffers
/// (`channels == 1`) are plain sample arrays, so every frame is a single
/// sample regardless of `channel`.
fn sampleAt(channels: usize, samples: []const f32, frame: usize, channel: usize) f32 {
    if (channels <= 1) return samples[frame];
    return samples[frame * channels + channel];
}

/// Equal-power pan gains for placing a mono source in the stereo field.
/// `pan` in [-1, 1]: -1 = left, 0 = center, +1 = right.
fn monoPanGains(pan: f32, volume: f32) struct { l: f32, r: f32 } {
    const p = @max(@as(f32, -1), @min(@as(f32, 1), pan));
    const angle = (p + 1) * @as(f32, std.math.pi) / 4;
    return .{ .l = std.math.cos(angle) * volume, .r = std.math.sin(angle) * volume };
}

/// Balance gains for an already-stereo source: pan attenuates the opposite
/// channel, keeping center loudness unchanged on both sides.
fn stereoPanGains(pan: f32, volume: f32) struct { l: f32, r: f32 } {
    const p = @max(@as(f32, -1), @min(@as(f32, 1), pan));
    const l = if (p >= 0) 1 - p else 1;
    const r = if (p <= 0) 1 + p else 1;
    return .{ .l = l * volume, .r = r * volume };
}

pub const EffectType = enum { lowpass, highpass, delay };

pub const EffectParams = union(EffectType) {
    lowpass: struct { cutoff: f32 = 1000 },
    highpass: struct { cutoff: f32 = 100 },
    delay: struct { time: f32 = 0.3, feedback: f32 = 0.3, wet: f32 = 0.3 },
};

const EffectState = union(EffectType) {
    lowpass: [2]f32,
    highpass: struct { x: [2]f32, y: [2]f32 },
    delay: struct { buffer: []f32, pos: usize, len: usize },
};

pub const EffectInstance = struct {
    params: EffectParams,
    state: EffectState,
};

fn freeEffectState(e: *EffectInstance) void {
    if (e.params == .delay) pxl.mem.free(e.state.delay.buffer);
}

/// An ordered, tiered list of effects applied frame by frame. Playbacks,
/// buses and the master bus each own one chain.
pub const EffectChain = struct {
    items: pxl.util.Vec(EffectInstance) = .empty,

    pub const empty: EffectChain = .{};

    pub fn add(self: *EffectChain, params: EffectParams, sample_rate: u32) void {
        var inst = EffectInstance{ .params = params, .state = undefined };
        switch (params) {
            .lowpass => inst.state = .{ .lowpass = .{ 0, 0 } },
            .highpass => inst.state = .{ .highpass = .{ .x = .{ 0, 0 }, .y = .{ 0, 0 } } },
            .delay => |d| {
                const len = @max(@as(usize, 1), @as(usize, @intFromFloat(@ceil(d.time * @as(f32, @floatFromInt(sample_rate))))));
                const buffer = pxl.mem.alloc(f32, len * 2, .persistent);
                @memset(buffer, 0);
                inst.state = .{ .delay = .{ .buffer = buffer, .pos = 0, .len = len } };
            },
        }
        self.items.append(inst);
    }

    pub fn get(self: *EffectChain, comptime tag: EffectType) ?*EffectInstance {
        for (self.items.items) |*e| {
            if (e.params == tag) return e;
        }
        return null;
    }

    /// Remove the first effect of the given type, freeing any state it owns.
    pub fn remove(self: *EffectChain, comptime tag: EffectType) void {
        for (self.items.items, 0..) |*e, i| {
            if (e.params == tag) {
                freeEffectState(e);
                _ = self.items.swapRemove(i);
                return;
            }
        }
    }

    pub fn clear(self: *EffectChain) void {
        for (self.items.items) |*e| freeEffectState(e);
        self.items.clearRetainingCapacity();
    }

    pub fn deinit(self: *EffectChain) void {
        self.clear();
        if (self.items.capacity > 0) self.items.deinit();
    }

    pub fn process(self: *EffectChain, frames: []f32, channels: usize, sample_rate: f32) void {
        const n = frames.len / channels;
        var i: usize = 0;
        while (i < n) : (i += 1) self.processFrame(frames[i * channels ..][0..channels], channels, sample_rate);
    }

    fn processFrame(self: *EffectChain, frame: []f32, channels: usize, sample_rate: f32) void {
        for (self.items.items) |*e| {
            switch (e.params) {
                .lowpass => |p| {
                    const a = 1.0 - @exp(-2.0 * @as(f32, std.math.pi) * p.cutoff / sample_rate);
                    var c: usize = 0;
                    while (c < channels) : (c += 1) {
                        e.state.lowpass[c] += a * (frame[c] - e.state.lowpass[c]);
                        frame[c] = e.state.lowpass[c];
                    }
                },
                .highpass => |p| {
                    const a = @exp(-2.0 * @as(f32, std.math.pi) * p.cutoff / sample_rate);
                    var c: usize = 0;
                    while (c < channels) : (c += 1) {
                        const x = frame[c];
                        const y = a * (e.state.highpass.y[c] + x - e.state.highpass.x[c]);
                        e.state.highpass.x[c] = x;
                        e.state.highpass.y[c] = y;
                        frame[c] = y;
                    }
                },
                .delay => |p| {
                    const d = &e.state.delay;
                    const w = d.pos * channels;
                    var c: usize = 0;
                    while (c < channels) : (c += 1) {
                        const delayed = d.buffer[w + c];
                        d.buffer[w + c] = frame[c] + delayed * p.feedback;
                        frame[c] = frame[c] * (1.0 - p.wet) + delayed * p.wet;
                    }
                    d.pos = (d.pos + 1) % d.len;
                },
            }
        }
    }
};

pub const Bus = struct {
    volume: f32 = 1,
    pan: f32 = 0,
    pitch: f32 = 1,
    effects: EffectChain = .empty,
    mix: []f32 = &.{},
};

pub const BusId = pxl.util.SlotMap(Bus).Key;

pub const Sound = struct {
    path: []u8,
    data: Data,
    sample_rate: u32,
    channels: u32,
    num_frames: usize,

    pub const Data = union(enum) {
        buffer: []f32,
        stream: *pxl.stb.vorbis.Stream,
    };
};

pub const SoundId = pxl.util.SlotMap(Sound).Key;

pub const Playback = struct {
    sound: SoundId,
    bus: ?BusId,
    volume: f32 = 1,
    pan: f32 = 0,
    pitch: f32 = 1,
    loop: bool = false,
    playing: bool = true,
    ended: bool = false,
    pos: f64 = 0,
    effects: EffectChain = .empty,
    chunk: []f32 = &.{},
    chunk_start: usize = 0,
    chunk_len: usize = 0,
};

pub const PlaybackId = pxl.util.SlotMap(Playback).Key;

pub const LoadOptions = struct {
    streamed: bool = false,
};

pub const PlaybackOptions = struct {
    volume: f32 = 1,
    pan: f32 = 0,
    pitch: f32 = 1,
    loop: bool = false,
    bus: ?BusId = null,
};

pub const AudioInitOptions = struct {
    max_sounds: usize = 64,
    max_playbacks: usize = 64,
    max_buses: usize = 16,
};

pub const AudioManager = struct {
    output_rate: u32 = 44100,
    output_channels: u32 = 2,
    sounds: pxl.util.SlotMap(Sound) = undefined,
    sound_ids: pxl.util.Vec(SoundId) = .empty,
    playbacks: pxl.util.SlotMap(Playback) = undefined,
    active: pxl.util.Vec(PlaybackId) = .empty,
    buses: pxl.util.SlotMap(Bus) = undefined,
    bus_ids: pxl.util.Vec(BusId) = .empty,
    master: Bus = .{},

    pub fn init(self: *AudioManager, opts: AudioInitOptions) void {
        self.* = .{};
        self.output_rate = @intCast(pxl.saudio.sampleRate());
        self.output_channels = @intCast(pxl.saudio.channels());
        self.sounds = pxl.util.SlotMap(Sound).init(opts.max_sounds);
        self.playbacks = pxl.util.SlotMap(Playback).init(opts.max_playbacks);
        self.buses = pxl.util.SlotMap(Bus).init(opts.max_buses);
        self.master = .{ .mix = pxl.mem.alloc(f32, ChunkFrames * @as(usize, self.output_channels), .persistent) };
    }

    pub fn deinit(self: *AudioManager) void {
        self.stopAll();
        self.playbacks.deinit();
        if (self.active.capacity > 0) self.active.deinit();

        for (self.sound_ids.items) |sid| {
            if (self.sounds.get(sid)) |s| self.freeSound(s);
        }
        self.sounds.deinit();
        if (self.sound_ids.capacity > 0) self.sound_ids.deinit();

        for (self.bus_ids.items) |bid| {
            if (self.buses.get(bid)) |b| {
                b.effects.deinit();
                pxl.mem.free(b.mix);
            }
        }
        self.buses.deinit();
        if (self.bus_ids.capacity > 0) self.bus_ids.deinit();

        self.master.effects.deinit();
        pxl.mem.free(self.master.mix);
        self.* = undefined;
    }

    /// Load (or return the already-loaded id for) an ogg file. Streamed
    /// sounds keep only the compressed bytes plus a decode chunk; loaded
    /// sounds decode the whole file to memory up front.
    pub fn load(self: *AudioManager, path: []const u8, opts: LoadOptions) !SoundId {
        if (self.findSoundByPath(path)) |id| return id;
        const bytes = try pxl.fs.read(path, .persistent);
        defer pxl.mem.free(bytes);

        var sound: Sound = undefined;
        if (opts.streamed) {
            const stream = pxl.mem.create(pxl.stb.vorbis.Stream, .persistent);
            stream.* = pxl.stb.vorbis.Stream.open(bytes, pxl.mem.allocator) catch |err| {
                pxl.mem.destroy(stream);
                return err;
            };
            sound = .{
                .path = pxl.mem.dupe(u8, path, .persistent),
                .data = .{ .stream = stream },
                .sample_rate = stream.sample_rate,
                .channels = stream.channels,
                .num_frames = stream.num_samples,
            };
        } else {
            const decoded = try pxl.stb.vorbis.decodeMemory(bytes, pxl.mem.allocator);
            sound = .{
                .path = pxl.mem.dupe(u8, path, .persistent),
                .data = .{ .buffer = decoded.samples },
                .sample_rate = decoded.sample_rate,
                .channels = decoded.channels,
                .num_frames = decoded.num_samples,
            };
        }

        const id = self.sounds.put(sound);
        if (id.generation == .invalid) {
            self.freeSound(&sound);
            return error.TooManySounds;
        }
        self.sound_ids.append(id);
        return id;
    }

    /// Register an in-memory interleaved buffer as a sound (the samples are
    /// copied, so the caller may free its slice afterwards). `channels` is
    /// 1 for mono or 2 for stereo. Useful for procedural audio such as
    /// rendered sfxr sounds.
    pub fn addBuffer(self: *AudioManager, samples: []const f32, channels: u32, sample_rate: u32) ?SoundId {
        if (samples.len == 0 or channels == 0) return null;
        var sound = Sound{
            .path = pxl.mem.dupe(u8, "", .persistent),
            .data = .{ .buffer = pxl.mem.dupe(f32, samples, .persistent) },
            .sample_rate = sample_rate,
            .channels = channels,
            .num_frames = samples.len / @as(usize, channels),
        };
        const id = self.sounds.put(sound);
        if (id.generation == .invalid) {
            self.freeSound(&sound);
            return null;
        }
        self.sound_ids.append(id);
        return id;
    }

    pub fn unload(self: *AudioManager, id: SoundId) void {
        const sound = self.sounds.get(id) orelse return;
        var i: usize = 0;
        while (i < self.active.items.len) {
            const pid = self.active.items[i];
            if (self.playbacks.get(pid)) |pb| {
                if (pb.sound == id) {
                    self.stop(pid);
                    continue;
                }
            }
            i += 1;
        }
        self.freeSound(sound);
        self.sounds.remove(id);
        self.removeSoundId(id);
    }

    pub fn createBus(self: *AudioManager) ?BusId {
        const new_bus = Bus{ .mix = pxl.mem.alloc(f32, ChunkFrames * @as(usize, self.output_channels), .persistent) };
        const id = self.buses.put(new_bus);
        if (id.generation == .invalid) {
            pxl.mem.free(new_bus.mix);
            return null;
        }
        self.bus_ids.append(id);
        return id;
    }

    /// Play a sound. Streamed sounds allow only one active playback at a
    /// time (they share a single decode cursor), so this returns null if
    /// that stream is already playing.
    pub fn play(self: *AudioManager, id: SoundId, opts: PlaybackOptions) ?PlaybackId {
        const sound = self.sounds.get(id) orelse return null;
        if (sound.data == .stream) {
            for (self.active.items) |pid| {
                if (self.playbacks.get(pid)) |pb| {
                    if (pb.sound == id) return null;
                }
            }
        }

        var pb = Playback{
            .sound = id,
            .bus = opts.bus,
            .volume = opts.volume,
            .pan = opts.pan,
            .pitch = @max(opts.pitch, 0.01),
            .loop = opts.loop,
        };
        if (sound.data == .stream) {
            sound.data.stream.seek(0) catch {};
            pb.chunk = pxl.mem.alloc(f32, ChunkFrames * @as(usize, sound.channels), .persistent);
        }

        const pid = self.playbacks.put(pb);
        if (pid.generation == .invalid) {
            if (pb.chunk.len > 0) pxl.mem.free(pb.chunk);
            return null;
        }
        self.active.append(pid);
        return pid;
    }

    pub fn playOneShot(self: *AudioManager, id: SoundId, opts: PlaybackOptions) void {
        var o = opts;
        o.loop = false;
        _ = self.play(id, o);
    }

    pub fn pause(self: *AudioManager, id: PlaybackId) void {
        if (self.playbacks.get(id)) |pb| pb.playing = false;
    }

    pub fn unpause(self: *AudioManager, id: PlaybackId) void {
        if (self.playbacks.get(id)) |pb| pb.playing = true;
    }

    pub fn isPlaying(self: *AudioManager, id: PlaybackId) bool {
        return if (self.playbacks.get(id)) |pb| pb.playing and !pb.ended else false;
    }

    pub fn position(self: *AudioManager, id: PlaybackId) f64 {
        const pb = self.playbacks.get(id) orelse return 0;
        const sound = self.sounds.get(pb.sound) orelse return 0;
        return pb.pos / @as(f64, @floatFromInt(sound.sample_rate));
    }

    pub fn duration(self: *AudioManager, id: PlaybackId) f64 {
        const pb = self.playbacks.get(id) orelse return 0;
        return self.soundDuration(pb.sound);
    }

    pub fn getSound(self: *AudioManager, id: SoundId) ?*Sound {
        return self.sounds.get(id);
    }

    /// Length of a sound in seconds, whether or not it is currently playing.
    pub fn soundDuration(self: *AudioManager, id: SoundId) f64 {
        const sound = self.sounds.get(id) orelse return 0;
        return @as(f64, @floatFromInt(sound.num_frames)) / @as(f64, @floatFromInt(sound.sample_rate));
    }

    pub fn seek(self: *AudioManager, id: PlaybackId, seconds: f64) void {
        const pb = self.playbacks.get(id) orelse return;
        const sound = self.sounds.get(pb.sound) orelse return;
        pb.pos = @max(0, seconds * @as(f64, @floatFromInt(sound.sample_rate)));
        if (sound.data == .stream) {
            sound.data.stream.seek(@intFromFloat(pb.pos)) catch {};
            pb.chunk_start = @intFromFloat(pb.pos);
            pb.chunk_len = 0;
        }
    }

    pub fn stop(self: *AudioManager, id: PlaybackId) void {
        const pb = self.playbacks.get(id) orelse return;
        self.releasePlayback(pb);
        self.playbacks.remove(id);
        self.removeActive(id);
    }

    pub fn stopAll(self: *AudioManager) void {
        for (self.active.items) |pid| {
            if (self.playbacks.get(pid)) |pb| {
                self.releasePlayback(pb);
                self.playbacks.remove(pid);
            }
        }
        self.active.clearRetainingCapacity();
    }

    pub fn playback(self: *AudioManager, id: PlaybackId) ?*Playback {
        return self.playbacks.get(id);
    }

    pub fn bus(self: *AudioManager, id: BusId) ?*Bus {
        return self.buses.get(id);
    }

    pub fn masterBus(self: *AudioManager) *Bus {
        return &self.master;
    }

    /// Mix all active playbacks into their buses, run bus/master effects,
    /// and push the result. Call once per frame.
    pub fn update(self: *AudioManager) void {
        const out_channels: usize = @intCast(self.output_channels);
        const available = pxl.saudio.expect();
        if (available <= 0) return;
        const frames = @min(@as(usize, @intCast(available)), ChunkFrames);
        if (frames == 0) return;
        const sample_count = frames * out_channels;
        const rate: f32 = @floatFromInt(self.output_rate);

        @memset(self.master.mix[0..sample_count], 0);
        for (self.bus_ids.items) |bid| {
            @memset(self.buses.get(bid).?.mix[0..sample_count], 0);
        }

        for (self.active.items) |pid| {
            const pb = self.playbacks.get(pid) orelse continue;
            if (!pb.playing) continue;
            const sound = self.sounds.get(pb.sound) orelse continue;
            const target_bus = if (pb.bus) |bid| self.buses.get(bid).? else &self.master;
            self.mixPlayback(pb, sound, target_bus.mix[0..sample_count], frames, pb.pitch * target_bus.pitch);
        }

        for (self.bus_ids.items) |bid| {
            const out_bus = self.buses.get(bid).?;
            out_bus.effects.process(out_bus.mix[0..sample_count], out_channels, rate);
            self.applyBusGain(out_bus.mix[0..sample_count], out_channels, out_bus.volume, out_bus.pan);
            for (out_bus.mix[0..sample_count], self.master.mix[0..sample_count]) |src, *dst| dst.* += src;
        }

        self.master.effects.process(self.master.mix[0..sample_count], out_channels, rate);
        self.applyBusGain(self.master.mix[0..sample_count], out_channels, self.master.volume, self.master.pan);

        for (self.master.mix[0..sample_count]) |*s| {
            if (s.* > 1.0) {
                s.* = 1.0;
            } else if (s.* < -1.0) {
                s.* = -1.0;
            }
        }
        _ = pxl.saudio.push(&self.master.mix[0], @intCast(frames));

        self.reapEnded();
    }

    fn findSoundByPath(self: *AudioManager, path: []const u8) ?SoundId {
        for (self.sound_ids.items) |id| {
            if (self.sounds.get(id)) |s| {
                if (std.mem.eql(u8, s.path, path)) return id;
            }
        }
        return null;
    }

    fn removeSoundId(self: *AudioManager, id: SoundId) void {
        for (self.sound_ids.items, 0..) |sid, i| {
            if (sid == id) {
                _ = self.sound_ids.swapRemove(i);
                return;
            }
        }
    }

    fn freeSound(self: *AudioManager, sound: *Sound) void {
        _ = self;
        switch (sound.data) {
            .buffer => |s| pxl.mem.free(s),
            .stream => |st| {
                st.close();
                pxl.mem.destroy(st);
            },
        }
        pxl.mem.free(sound.path);
    }

    fn releasePlayback(self: *AudioManager, pb: *Playback) void {
        _ = self;
        if (pb.chunk.len > 0) pxl.mem.free(pb.chunk);
        pb.effects.deinit();
    }

    fn removeActive(self: *AudioManager, id: PlaybackId) void {
        for (self.active.items, 0..) |pid, i| {
            if (pid == id) {
                _ = self.active.swapRemove(i);
                return;
            }
        }
    }

    fn reapEnded(self: *AudioManager) void {
        var i: usize = 0;
        while (i < self.active.items.len) {
            const pid = self.active.items[i];
            if (self.playbacks.get(pid)) |pb| {
                if (pb.ended) {
                    self.releasePlayback(pb);
                    self.playbacks.remove(pid);
                    _ = self.active.swapRemove(i);
                    continue;
                }
            }
            i += 1;
        }
    }

    fn applyBusGain(self: *AudioManager, buf: []f32, channels: usize, volume: f32, pan: f32) void {
        _ = self;
        if (channels == 1) {
            for (buf) |*s| s.* *= volume;
            return;
        }
        const g = stereoPanGains(pan, volume);
        const n = buf.len / channels;
        var i: usize = 0;
        while (i < n) : (i += 1) {
            buf[i * channels] *= g.l;
            buf[i * channels + 1] *= g.r;
        }
    }

    fn mixPlayback(self: *AudioManager, pb: *Playback, sound: *const Sound, out: []f32, frames: usize, pitch: f32) void {
        const out_channels: usize = @intCast(self.output_channels);
        const channels: usize = @intCast(sound.channels);
        const ratio = @as(f64, @floatFromInt(sound.sample_rate)) / @as(f64, @floatFromInt(self.output_rate)) * @as(f64, pitch);
        const rate: f32 = @floatFromInt(self.output_rate);
        const g_mono = monoPanGains(pb.pan, pb.volume);
        const g_stereo = stereoPanGains(pb.pan, pb.volume);

        var i: usize = 0;
        while (i < frames) : (i += 1) {
            var frame: [2]f32 = .{ 0, 0 };
            switch (sound.data) {
                .buffer => |samples| {
                    const idx = @as(usize, @intFromFloat(pb.pos));
                    if (idx >= sound.num_frames) {
                        if (pb.loop) {
                            pb.pos = 0;
                            continue;
                        }
                        pb.ended = true;
                        pb.playing = false;
                        return;
                    }
                    const frac: f32 = @floatCast(pb.pos - @as(f64, @floatFromInt(idx)));
                    if (channels == 1) {
                        const a = samples[idx];
                        const b = if (idx + 1 < sound.num_frames) samples[idx + 1] else a;
                        const s = a + (b - a) * frac;
                        if (out_channels == 1) {
                            frame[0] = s * pb.volume;
                        } else {
                            frame[0] = s * g_mono.l;
                            frame[1] = s * g_mono.r;
                        }
                    } else {
                        const a0 = samples[idx * channels];
                        const b0 = if (idx + 1 < sound.num_frames) samples[(idx + 1) * channels] else a0;
                        const a1 = samples[idx * channels + 1];
                        const b1 = if (idx + 1 < sound.num_frames) samples[(idx + 1) * channels + 1] else a1;
                        const l = a0 + (b0 - a0) * frac;
                        const r = a1 + (b1 - a1) * frac;
                        if (out_channels == 1) {
                            frame[0] = (l + r) * 0.5 * pb.volume;
                        } else {
                            frame[0] = l * g_stereo.l;
                            frame[1] = r * g_stereo.r;
                        }
                    }
                },
                .stream => |stream| {
                    while (@as(usize, @intFromFloat(pb.pos)) >= pb.chunk_start + pb.chunk_len) {
                        const n = stream.readFrames(pb.chunk) catch 0;
                        pb.chunk_start += pb.chunk_len;
                        pb.chunk_len = n;
                        if (n == 0) {
                            if (pb.loop) {
                                stream.seek(0) catch {};
                                pb.pos = 0;
                                pb.chunk_start = 0;
                                pb.chunk_len = 0;
                                continue;
                            }
                            pb.ended = true;
                            pb.playing = false;
                            return;
                        }
                    }
                    const idx = @as(usize, @intFromFloat(pb.pos));
                    const idx_in = idx - pb.chunk_start;
                    const frac: f32 = @floatCast(pb.pos - @as(f64, @floatFromInt(idx)));
                    const next = idx_in + 1 < pb.chunk_len;
                    if (channels == 1) {
                        const a = pb.chunk[idx_in];
                        const b = if (next) pb.chunk[idx_in + 1] else a;
                        const s = a + (b - a) * frac;
                        if (out_channels == 1) {
                            frame[0] = s * pb.volume;
                        } else {
                            frame[0] = s * g_mono.l;
                            frame[1] = s * g_mono.r;
                        }
                    } else {
                        const a0 = sampleAt(channels, pb.chunk, idx_in, 0);
                        const b0 = if (next) sampleAt(channels, pb.chunk, idx_in + 1, 0) else a0;
                        const a1 = sampleAt(channels, pb.chunk, idx_in, 1);
                        const b1 = if (next) sampleAt(channels, pb.chunk, idx_in + 1, 1) else a1;
                        const l = a0 + (b0 - a0) * frac;
                        const r = a1 + (b1 - a1) * frac;
                        if (out_channels == 1) {
                            frame[0] = (l + r) * 0.5 * pb.volume;
                        } else {
                            frame[0] = l * g_stereo.l;
                            frame[1] = r * g_stereo.r;
                        }
                    }
                },
            }
            pb.effects.processFrame(frame[0..out_channels], out_channels, rate);
            const o = i * out_channels;
            var c: usize = 0;
            while (c < out_channels) : (c += 1) out[o + c] += frame[c];
            pb.pos += ratio;
        }
    }
};

test "sampleAt reads interleaved channels" {
    const stereo = [_]f32{ 1, 2, 3, 4 };
    try std.testing.expectEqual(@as(f32, 1.0), sampleAt(2, &stereo, 0, 0));
    try std.testing.expectEqual(@as(f32, 2.0), sampleAt(2, &stereo, 0, 1));
    try std.testing.expectEqual(@as(f32, 3.0), sampleAt(2, &stereo, 1, 0));
    try std.testing.expectEqual(@as(f32, 4.0), sampleAt(2, &stereo, 1, 1));

    const mono = [_]f32{ 5, 6 };
    try std.testing.expectEqual(@as(f32, 5.0), sampleAt(1, &mono, 0, 0));
    try std.testing.expectEqual(@as(f32, 6.0), sampleAt(1, &mono, 1, 0));
}

test "monoPanGains places a source left/center/right" {
    const center = monoPanGains(0, 1);
    try std.testing.expect(@abs(center.l - 0.70710678) < 0.000001);
    try std.testing.expect(@abs(center.r - 0.70710678) < 0.000001);

    const left = monoPanGains(-1, 1);
    try std.testing.expect(@abs(left.l - 1.0) < 0.000001);
    try std.testing.expect(@abs(left.r) < 0.000001);

    const right = monoPanGains(1, 1);
    try std.testing.expect(@abs(right.l) < 0.000001);
    try std.testing.expect(@abs(right.r - 1.0) < 0.000001);
}

test "stereoPanGains balances channels" {
    const center = stereoPanGains(0, 1);
    try std.testing.expectEqual(@as(f32, 1.0), center.l);
    try std.testing.expectEqual(@as(f32, 1.0), center.r);

    const left = stereoPanGains(-1, 1);
    try std.testing.expectEqual(@as(f32, 1.0), left.l);
    try std.testing.expectEqual(@as(f32, 0.0), left.r);

    const right = stereoPanGains(1, 1);
    try std.testing.expectEqual(@as(f32, 0.0), right.l);
    try std.testing.expectEqual(@as(f32, 1.0), right.r);
}
