const std = @import("std");

const pxl = @import("pxl");
const mu = pxl.mu;
const vorbis = pxl.stb.vorbis;
const sfxr = pxl.sfxr;

// --- tracks ---------------------------------------------------------------

const MaxTracks = 16;

const Track = struct {
    /// Owned filename, e.g. "tester.ogg".
    name: []u8,
    /// Owned streaming decoder.
    stream: *vorbis.Stream,
};

/// Auto-discovered .ogg files in examples/assets.
var tracks: [MaxTracks]?Track = [_]?Track{null} ** MaxTracks;
var track_count: usize = 0;

var scan_error: ?[:0]const u8 = null;
var scan_error_buf: [256]u8 = undefined;

/// Find every .ogg in examples/assets and open a streaming decoder for it.
fn scanTracks() !void {
    var dir = try std.Io.Dir.openDir(.cwd(), pxl.io, "examples/assets", .{ .iterate = true });
    defer dir.close(pxl.io);

    var iter = dir.iterate();
    while (try iter.next(pxl.io)) |entry| {
        if (track_count >= MaxTracks) break;
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.name, ".ogg")) continue;

        // entry.name lives in the iterator's buffer (reused each step), so
        // copy it before doing anything else.
        var path_buf: [512]u8 = undefined;
        const path = std.fmt.bufPrint(&path_buf, "examples/assets/{s}", .{entry.name}) catch continue;

        const file = pxl.fs.read(path, .persistent) catch |err| {
            scan_error = std.fmt.bufPrintZ(&scan_error_buf, "Failed to read {s}: {s}", .{ entry.name, @errorName(err) }) catch null;
            continue;
        };
        defer pxl.mem.free(file);

        const stream = pxl.mem.create(vorbis.Stream, .persistent);
        stream.* = vorbis.Stream.open(file, pxl.mem.allocator) catch |err| {
            pxl.mem.destroy(stream);
            scan_error = std.fmt.bufPrintZ(&scan_error_buf, "Failed to decode {s}: {s}", .{ entry.name, @errorName(err) }) catch null;
            continue;
        };

        tracks[track_count] = .{
            .name = pxl.mem.dupe(u8, entry.name, .persistent),
            .stream = stream,
        };
        track_count += 1;
    }

    if (track_count == 0) {
        scan_error = "No .ogg files found in examples/assets";
    } else {
        std.debug.print("vorbis: found {d} ogg track(s): ", .{track_count});
        for (0..track_count) |i| std.debug.print("{s} ", .{tracks[i].?.name});
        std.debug.print("\n", .{});
    }
}

// --- playback state ---------------------------------------------------------

var mixer: pxl.audio.Mixer = .{};

var current: usize = 0; // index into tracks
var voice_idx: ?usize = null; // mixer voice playing `current`
var is_playing: bool = false;
var loop_track: bool = true;
/// Fractional source frame position while paused (null = not paused).
var paused_at: ?f32 = null;
var track_volume: f32 = 1.0;

// one-shot sfxr sounds, mixed on top of the track
var sfx_voice: ?usize = null;
var sfx_samples: ?[]f32 = null;

fn playTrack(idx: usize) void {
    if (track_count == 0) return;
    stopVoice();
    current = idx;
    const t = tracks[idx].?;
    voice_idx = mixer.playStream(t.stream, .{ .volume = track_volume, .loop = loop_track }) catch null;
    is_playing = voice_idx != null;
}

fn stopVoice() void {
    if (voice_idx) |vi| mixer.stop(vi);
    voice_idx = null;
    is_playing = false;
    paused_at = null;
}

fn togglePlayPause() void {
    if (is_playing) {
        // pause: remember where we were, then stop the voice
        paused_at = mixer.voicePosition(voice_idx.?);
        mixer.stop(voice_idx.?);
        voice_idx = null;
        is_playing = false;
    } else {
        const t = tracks[current].?;
        if (paused_at) |pos| t.stream.seek(@intFromFloat(pos)) catch {};
        paused_at = null;
        voice_idx = mixer.playStream(t.stream, .{ .volume = track_volume, .loop = loop_track }) catch null;
        is_playing = voice_idx != null;
    }
}

fn playSfx(preset: sfxr.Preset) void {
    if (sfx_voice) |vi| mixer.stop(vi);
    if (sfx_samples) |s| pxl.mem.free(s);
    sfx_voice = null;
    sfx_samples = null;

    var p = sfxr.Params{};
    p.apply(preset);
    var sound = sfxr.Sound.init(p, mixer.output_rate);
    var vec: pxl.util.Vec(f32) = .empty;
    while (sound.nextSample()) |s| vec.append(s);
    sfx_samples = vec.toOwnedSlice();
    sfx_voice = mixer.playBuffer(sfx_samples.?, .{ .volume = 0.8 });
}

fn currentPosition() f32 {
    if (paused_at) |pos| return pos;
    if (voice_idx) |vi| return mixer.voicePosition(vi) orelse 0;
    return 0;
}

pub fn setup() !void {
    try scanTracks();
    try mixer.init();
    if (track_count > 0) playTrack(0);
}

pub fn shutdown() !void {
    if (sfx_samples) |s| pxl.mem.free(s);
    mixer.deinit();
    for (0..track_count) |i| {
        const t = tracks[i].?;
        pxl.mem.free(t.name);
        t.stream.close();
        pxl.mem.destroy(t.stream);
        tracks[i] = null;
    }
}

// --- microui helpers --------------------------------------------------------

/// Layout a row of `count` equal-width items spanning the available row
/// width. microui's `-1` width means "fill the *remaining* row width", so
/// using several `-1`s in one row makes the first item eat the whole row
/// and pushes the rest off screen — compute explicit widths instead.
fn equalWidths(count: usize, out: *[4]c_int) c_int {
    const body = mu.getCurrentContainer().*.body;
    const spacing = mu.mu_ctx.style.*.spacing;
    // Rows inside a header/treenode are indented by the current layout's
    // indent; subtract it so the row doesn't overflow the right edge.
    const layout = mu.mu_ctx.layout_stack.items[@intCast(mu.mu_ctx.layout_stack.idx - 1)];
    const indent = layout.indent;
    const n: c_int = @intCast(count);
    const avail = body.w - indent - spacing * (n - 1);
    const w = @max(1, @divTrunc(avail, n));
    for (0..count) |i| out[i] = w;
    return n;
}

// --- callbacks --------------------------------------------------------------

pub fn update() !void {
    // If a voice ended on its own (stream EOF without loop, sfx finished),
    // reap it so the UI doesn't show stale state.
    if (voice_idx) |vi| {
        if (!mixer.voices[vi].active) {
            voice_idx = null;
            is_playing = false;
        }
    }
    if (sfx_voice) |vi| {
        if (!mixer.voices[vi].active) {
            sfx_voice = null;
            if (sfx_samples) |s| pxl.mem.free(s);
            sfx_samples = null;
        }
    }

    mixer.update();

    if (mu.beginWindowEx("Ogg Player", .{ .x = 20, .y = 20, .w = 380, .h = 480 }, .{ .no_close = true })) {
        if (scan_error) |err| {
            mu.layoutRow(1, &[_]c_int{-1}, 0);
            mu.label(err);
        }

        // Track list
        mu.layoutRow(2, &[_]c_int{ 24, -1 }, 0);
        mu.label(" ");
        mu.label("Tracks");
        for (0..track_count) |i| {
            const t = tracks[i].?;
            mu.layoutRow(2, &[_]c_int{ 24, -1 }, 0);
            mu.label(if (i == current) "=>" else " ");

            var name_buf: [256]u8 = undefined;
            const duration = @as(f32, @floatFromInt(t.stream.num_samples)) / @as(f32, @floatFromInt(t.stream.sample_rate));
            const name = std.fmt.bufPrintZ(&name_buf, "{s}  ({d:.1}s)", .{ t.name, duration }) catch "?";
            mu.pushId(&i, @sizeOf(usize));
            if (mu.button(name, .none)) playTrack(i);
            mu.popId();
        }

        mu.layoutRow(1, &[_]c_int{-1}, 0);
        mu.label(" ");

        // Transport
        var row: [4]c_int = undefined;
        mu.layoutRow(equalWidths(3, &row), &row, 0);
        const play_label = if (paused_at != null) "Resume" else if (is_playing) "Pause" else "Play";
        if (mu.button(play_label, .none)) togglePlayPause();
        if (mu.button("Stop", .none)) stopVoice();
        if (mu.button(if (loop_track) "Loop: On" else "Loop: Off", .none)) {
            loop_track = !loop_track;
            if (voice_idx) |vi| mixer.voices[vi].loop = loop_track;
        }

        // Position
        mu.layoutRow(2, &[_]c_int{ 70, -1 }, 0);
        mu.label("Position");
        var pos_buf: [48]u8 = undefined;
        const duration = if (track_count > 0)
            @as(f32, @floatFromInt(tracks[current].?.stream.num_samples)) / @as(f32, @floatFromInt(tracks[current].?.stream.sample_rate))
        else
            0;
        const pos_sec = if (track_count > 0)
            currentPosition() / @as(f32, @floatFromInt(tracks[current].?.stream.sample_rate))
        else
            0;
        const pos_str = std.fmt.bufPrintZ(&pos_buf, "{d:.1}s / {d:.1}s", .{ pos_sec, duration }) catch "?";
        mu.label(pos_str);

        // Volume
        mu.layoutRow(2, &[_]c_int{ 70, -1 }, 0);
        mu.label("Volume");
        if (mu.slider(&track_volume, 0, 1, 0.01)) {
            if (voice_idx) |vi| mixer.voices[vi].volume = track_volume;
        }

        // SFX demo — played through the same mixer, on top of the track
        if (mu.headerEx("SFX (mixed on top)", .{ .expanded = true })) {
            const SfxBtn = struct { label: [:0]const u8, preset: sfxr.Preset };
            mu.layoutRow(equalWidths(3, &row), &row, 0);
            for ([_]SfxBtn{
                .{ .label = "Coin", .preset = .pickup_coin },
                .{ .label = "Laser", .preset = .laser_shoot },
                .{ .label = "Explosion", .preset = .explosion },
            }) |btn| {
                mu.pushId(&btn.preset, @sizeOf(sfxr.Preset));
                if (mu.button(btn.label, .none)) playSfx(btn.preset);
                mu.popId();
            }
        }

        mu.endWindow();
    }
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = pxl.math.Color.fromBytes(16, 18, 24, 255) });
    pxl.endPass();
}
