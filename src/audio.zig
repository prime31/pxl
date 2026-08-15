//! pxl.audio — a tiny software mixer on top of `pxl.saudio`.
//!
//! Mixes up to `MaxVoices` simultaneous voices into the sokol audio ring
//! buffer (push model). Two kinds of sources are supported:
//!
//!   - `.buffer` — a fully decoded mono buffer, e.g. a rendered `pxl.sfxr`
//!     sound or a decoded wav.
//!   - `.stream` — a `pxl.stb.vorbis.Stream`, decoded in small chunks on
//!     demand so memory stays bounded for long tracks.
//!
//! Voices are resampled (linear interpolation) from their native sample
//! rate to the audio output rate, so mixed sources can have different
//! rates. Call `update()` once per frame; it fills whatever room the audio
//! device currently has and pushes the mix.
//!
//! ```
//! var mixer: pxl.audio.Mixer = .{};
//! try mixer.init(pxl.mem.allocator);
//! defer mixer.deinit(pxl.mem.allocator);
//!
//! const vi = mixer.playBuffer(my_sfx, .{ .volume = 0.8 }) orelse ...;
//! const vi2 = try mixer.playStream(&track.stream, .{ .loop = true });
//! ```

const std = @import("std");
const pxl = @import("pxl.zig");

pub const MaxVoices = 16;
/// Frames decoded per refill for stream voices.
pub const ChunkFrames = 4096;

pub const Source = union(enum) {
    /// A fully decoded mono buffer (borrowed; the caller keeps it alive
    /// until the voice stops).
    buffer: []const f32,
    /// A streaming decoder; chunks are pulled on demand.
    stream: *pxl.stb.vorbis.Stream,
};

pub const Voice = struct {
    active: bool = false,
    source: Source = .{ .buffer = &.{} },
    /// Native sample rate of the source.
    sample_rate: u32 = 44100,
    volume: f32 = 1.0,
    /// Stereo position: -1 = left, 0 = center, +1 = right.
    pan: f32 = 0,
    /// Playback rate multiplier (1 = normal, 2 = one octave up).
    pitch: f32 = 1,
    loop: bool = false,
    /// Fractional position in the source (allows resampling). f64 keeps
    /// exact integer precision for tracks far longer than an f32 could
    /// (f32 loses integer precision past 2^24 frames ≈ 6 minutes @ 44.1kHz).
    pos: f64 = 0,
    // stream-only state
    chunk: []f32 = &.{},
    chunk_start: usize = 0,
    chunk_len: usize = 0,
};

pub const PlayOptions = struct {
    volume: f32 = 1.0,
    loop: bool = false,
    /// Stereo position: -1 = left, 0 = center, +1 = right.
    pan: f32 = 0,
    /// Playback rate multiplier (1 = normal, 2 = one octave up).
    pitch: f32 = 1,
    /// 0 (default) = the mixer's output rate (no resampling).
    sample_rate: u32 = 0,
};

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

pub const Mixer = struct {
    output_rate: u32 = 44100,
    output_channels: u32 = 1,
    voices: [MaxVoices]Voice = [_]Voice{.{}} ** MaxVoices,
    /// Scratch space for one mixed push (interleaved, `ChunkFrames` frames).
    mix: []f32 = &.{},

    pub fn init(self: *Mixer) !void {
        self.* = .{};
        self.output_rate = @intCast(pxl.saudio.sampleRate());
        self.output_channels = @intCast(pxl.saudio.channels());
        self.mix = pxl.mem.alloc(f32, ChunkFrames * self.output_channels, .persistent);
    }

    pub fn deinit(self: *Mixer) void {
        self.stopAll();
        pxl.mem.free(self.mix);
        self.* = undefined;
    }

    /// Play a pre-decoded mono buffer. Returns the voice index (or null
    /// when the pool is exhausted / the buffer is empty).
    pub fn playBuffer(self: *Mixer, samples: []const f32, opts: PlayOptions) ?usize {
        if (samples.len == 0) return null;
        const idx = self.findFreeVoice() orelse return null;
        self.voices[idx] = .{
            .active = true,
            .source = .{ .buffer = samples },
            .sample_rate = if (opts.sample_rate == 0) self.output_rate else opts.sample_rate,
            .volume = opts.volume,
            .pan = opts.pan,
            .pitch = @max(opts.pitch, 0.01),
            .loop = opts.loop,
        };
        return idx;
    }

    /// Play a streaming source. Returns the voice index (or null when the
    /// pool is exhausted).
    pub fn playStream(self: *Mixer, stream: *pxl.stb.vorbis.Stream, opts: PlayOptions) !?usize {
        const idx = self.findFreeVoice() orelse return null;
        const v = &self.voices[idx];
        v.* = .{
            .active = true,
            .source = .{ .stream = stream },
            .sample_rate = if (opts.sample_rate == 0) stream.sample_rate else opts.sample_rate,
            .volume = opts.volume,
            .pan = opts.pan,
            .pitch = @max(opts.pitch, 0.01),
            .loop = opts.loop,
        };
        v.chunk = pxl.mem.alloc(f32, ChunkFrames * stream.channels, .persistent);
        return idx;
    }

    pub fn stop(self: *Mixer, idx: usize) void {
        if (idx >= self.voices.len) return;
        self.deactivateVoice(&self.voices[idx]);
    }

    pub fn stopAll(self: *Mixer) void {
        for (&self.voices) |*v| self.deactivateVoice(v);
    }

    /// Fractional source position of a voice, or null if it's inactive.
    /// Useful for pausing a stream: read the position, stop, then seek the
    /// stream and play again.
    pub fn voicePosition(self: *Mixer, idx: usize) ?f64 {
        if (idx >= self.voices.len) return null;
        const v = &self.voices[idx];
        if (!v.active) return null;
        return v.pos;
    }

    /// Mix all active voices into the audio device's available space and
    /// push. Call once per frame.
    pub fn update(self: *Mixer) void {
        const out_channels: usize = @intCast(self.output_channels);
        const available = pxl.saudio.expect();
        if (available <= 0) return;
        const frames = @min(@as(usize, @intCast(available)), self.mix.len / out_channels);
        if (frames == 0) return;
        const sample_count = frames * out_channels;

        @memset(self.mix[0..sample_count], 0);
        var any_active = false;
        for (&self.voices) |*v| {
            if (!v.active) continue;
            any_active = true;
            self.fillVoice(v, self.mix[0..sample_count]);
        }
        if (!any_active) return;

        // soft clamp against inter-sample clipping
        for (self.mix[0..sample_count]) |*s| {
            if (s.* > 1.0) {
                s.* = 1.0;
            } else if (s.* < -1.0) {
                s.* = -1.0;
            }
        }
        _ = pxl.saudio.push(&self.mix[0], @intCast(frames));
    }

    fn findFreeVoice(self: *Mixer) ?usize {
        for (&self.voices, 0..) |*v, i| {
            if (!v.active) return i;
        }
        return null;
    }

    /// Free stream resources and reset the voice to inactive.
    fn deactivateVoice(_: *Mixer, v: *Voice) void {
        if (v.active and v.source == .stream and v.chunk.len > 0) {
            pxl.mem.free(v.chunk);
        }
        v.* = .{};
    }

    /// Add the voice's next `out.len / output_channels` frames (resampled
    /// to the output rate and pitched) into `out`, which holds interleaved
    /// output frames. Voices that end early leave the remainder at 0.
    fn fillVoice(self: *Mixer, v: *Voice, out: []f32) void {
        const ratio = @as(f64, @floatFromInt(v.sample_rate)) / @as(f64, @floatFromInt(self.output_rate)) * @as(f64, v.pitch);
        const out_channels: usize = @intCast(self.output_channels);
        const frames = out.len / out_channels;
        switch (v.source) {
            .buffer => |samples| {
                const g = monoPanGains(v.pan, v.volume);
                var i: usize = 0;
                while (i < frames) : (i += 1) {
                    const idx = @as(usize, @intFromFloat(v.pos));
                    if (idx >= samples.len) {
                        if (v.loop) {
                            v.pos = 0;
                            continue;
                        }
                        self.deactivateVoice(v);
                        return;
                    }
                    const frac: f32 = @floatCast(v.pos - @as(f64, @floatFromInt(idx)));
                    const a = samples[idx];
                    const b = if (idx + 1 < samples.len) samples[idx + 1] else a;
                    const s = a + (b - a) * frac;
                    const o = i * out_channels;
                    if (out_channels == 1) {
                        out[o] += s * v.volume;
                    } else if (out_channels == 2) {
                        out[o] += s * g.l;
                        out[o + 1] += s * g.r;
                    } else {
                        var c: usize = 0;
                        while (c < out_channels) : (c += 1) out[o + c] += s * v.volume;
                    }
                    v.pos += ratio;
                }
            },
            .stream => |stream| {
                const channels: usize = @intCast(stream.channels);
                const g_mono = monoPanGains(v.pan, v.volume);
                const g_stereo = stereoPanGains(v.pan, v.volume);
                var i: usize = 0;
                while (i < frames) : (i += 1) {
                    // refill whenever the read position has left the chunk
                    while (@as(usize, @intFromFloat(v.pos)) >= v.chunk_start + v.chunk_len) {
                        const n = stream.readFrames(v.chunk) catch 0;
                        v.chunk_start += v.chunk_len;
                        v.chunk_len = n;
                        if (n == 0) {
                            if (v.loop) {
                                stream.seek(0) catch {};
                                v.pos = 0;
                                v.chunk_start = 0;
                                v.chunk_len = 0;
                                continue;
                            }
                            self.deactivateVoice(v);
                            return;
                        }
                    }
                    const idx = @as(usize, @intFromFloat(v.pos));
                    const idx_in = idx - v.chunk_start;
                    const frac: f32 = @floatCast(v.pos - @as(f64, @floatFromInt(idx)));
                    const next = idx_in + 1 < v.chunk_len;
                    const o = i * out_channels;
                    if (channels == 1) {
                        const a = v.chunk[idx_in];
                        const b = if (next) v.chunk[idx_in + 1] else a;
                        const s = a + (b - a) * frac;
                        if (out_channels == 1) {
                            out[o] += s * v.volume;
                        } else if (out_channels == 2) {
                            out[o] += s * g_mono.l;
                            out[o + 1] += s * g_mono.r;
                        } else {
                            var c: usize = 0;
                            while (c < out_channels) : (c += 1) out[o + c] += s * v.volume;
                        }
                    } else if (out_channels == 1) {
                        // downmix a multichannel source to mono
                        var sum: f32 = 0;
                        var c: usize = 0;
                        while (c < channels) : (c += 1) {
                            const a = sampleAt(channels, v.chunk, idx_in, c);
                            const b = if (next) sampleAt(channels, v.chunk, idx_in + 1, c) else a;
                            sum += a + (b - a) * frac;
                        }
                        out[o] += (sum / @as(f32, @floatFromInt(channels))) * v.volume;
                    } else if (out_channels == 2) {
                        // pan a stereo source by balancing left/right
                        const a0 = sampleAt(channels, v.chunk, idx_in, 0);
                        const b0 = if (next) sampleAt(channels, v.chunk, idx_in + 1, 0) else a0;
                        out[o] += (a0 + (b0 - a0) * frac) * g_stereo.l;
                        const a1 = sampleAt(channels, v.chunk, idx_in, 1);
                        const b1 = if (next) sampleAt(channels, v.chunk, idx_in + 1, 1) else a1;
                        out[o + 1] += (a1 + (b1 - a1) * frac) * g_stereo.r;
                    } else {
                        // direct map, using the min(channels, out_channels) channels
                        const n = @min(channels, out_channels);
                        var c: usize = 0;
                        while (c < n) : (c += 1) {
                            const a = sampleAt(channels, v.chunk, idx_in, c);
                            const b = if (next) sampleAt(channels, v.chunk, idx_in + 1, c) else a;
                            out[o + c] += (a + (b - a) * frac) * v.volume;
                        }
                    }
                    v.pos += ratio;
                }
            },
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
