const std = @import("std");

const pxl = @import("pxl");
const mu = pxl.mu;
const vorbis = pxl.stb.vorbis;

// decoded track (interleaved f32, persistent allocation, freed in shutdown)
var track: ?vorbis.Decoded = null;

// mono downmix for sokol audio, which is configured for a single channel
var playback: []f32 = &.{};
var play_pos: usize = 0;
var is_playing: bool = false;
var loop: bool = false;

// set when the ogg fails to load, so the UI can say why
var load_error: ?[:0]const u8 = null;
var load_error_buf: [128]u8 = undefined;

pub fn setup() !void {
    // .persistent: the ogg is ~1MB, too big for the wrapping temp/scratch
    // arena used by pxl.fs.read(.temp) without aliasing. Free it after decode.
    const file = try pxl.fs.read("examples/assets/tester.ogg", .persistent);
    defer pxl.mem.free(file);
    track = vorbis.decodeMemory(file, pxl.mem.allocator) catch |err| {
        load_error = std.fmt.bufPrintZ(
            &load_error_buf,
            "Failed to load tester.ogg: {s}",
            .{@errorName(err)},
        ) catch "Failed to load tester.ogg";
        return;
    };

    const t = track.?;
    playback = pxl.mem.alloc(f32, t.num_samples, .persistent);
    if (t.channels == 1) {
        @memcpy(playback, t.samples);
    } else {
        // mix all channels down to mono
        const channel_count: f32 = @floatFromInt(t.channels);
        for (0..t.num_samples) |i| {
            var sum: f32 = 0;
            for (0..t.channels) |c| sum += t.samples[i * t.channels + c];
            playback[i] = sum / channel_count;
        }
    }

    is_playing = true;

    if (t.sample_rate != @as(u32, @intCast(pxl.saudio.sampleRate()))) {
        std.debug.print(
            "vorbis: track sample rate {d} Hz differs from audio output rate {d} Hz; playback pitch will be off\n",
            .{ t.sample_rate, pxl.saudio.sampleRate() },
        );
    }
}

pub fn shutdown() !void {
    if (track) |t| pxl.mem.free(t.samples);
    if (playback.len > 0) pxl.mem.free(playback);
}

/// Stream the mono playback buffer into the sokol audio ring buffer.
/// Loops seamlessly by restarting from the top as soon as the tail of
/// the current pass has been queued.
fn streamAudio() void {
    if (!is_playing or playback.len == 0) return;
    while (play_pos < playback.len) {
        const available = pxl.saudio.expect();
        if (available <= 0) break;
        const n = @min(@as(usize, @intCast(available)), playback.len - play_pos);
        const pushed = pxl.saudio.push(&playback[play_pos], @intCast(n));
        if (pushed <= 0) break;
        play_pos += @intCast(pushed);
        if (@as(usize, @intCast(pushed)) < n) break;
    }
    if (play_pos >= playback.len) {
        if (loop) play_pos = 0 else is_playing = false;
    }
}

/// Layout a row of `count` equal-width items spanning the window body.
/// microui's `-1` width means "fill the *remaining* row width", so using
/// several `-1`s in one row pushes everything past the first item off
/// screen — compute explicit widths instead.
fn equalWidths(count: usize, out: *[4]c_int) c_int {
    const body = mu.getCurrentContainer().*.body;
    const spacing = mu.mu_ctx.style.*.spacing;
    const n: c_int = @intCast(count);
    const w = @divTrunc(body.w - spacing * (n - 1), n);
    for (0..count) |i| out[i] = w;
    return n;
}

pub fn update() !void {
    streamAudio();

    if (mu.beginWindowEx("Vorbis Player", .{ .x = 20, .y = 20, .w = 340, .h = 200 }, .{ .no_close = true })) {
        if (load_error) |err| {
            mu.layoutRow(1, &[_]c_int{-1}, 0);
            mu.label(err);
        } else if (track) |t| {
            // track info
            mu.layoutRow(2, &[_]c_int{ 100, -1 }, 0);
            mu.label("File");
            mu.label("tester.ogg");

            var rate_buf: [32]u8 = undefined;
            const rate_str = std.fmt.bufPrintZ(&rate_buf, "{d} Hz", .{t.sample_rate}) catch "?";
            mu.label("Sample Rate");
            mu.label(rate_str);

            var ch_buf: [32]u8 = undefined;
            const ch_str = std.fmt.bufPrintZ(&ch_buf, "{d} ({s})", .{
                t.channels,
                if (t.channels == 1) "mono" else "stereo",
            }) catch "?";
            mu.label("Channels");
            mu.label(ch_str);

            const duration = @as(f32, @floatFromInt(t.num_samples)) / @as(f32, @floatFromInt(t.sample_rate));
            var dur_buf: [32]u8 = undefined;
            const dur_str = std.fmt.bufPrintZ(&dur_buf, "{d:.2}s", .{duration}) catch "?";
            mu.label("Duration");
            mu.label(dur_str);

            // transport
            var row: [4]c_int = undefined;
            mu.layoutRow(equalWidths(3, &row), &row, 0);
            if (mu.button(if (is_playing) "Pause" else "Play", .none)) {
                if (!is_playing and play_pos >= playback.len) play_pos = 0;
                is_playing = !is_playing;
            }
            if (mu.button("Stop", .none)) {
                is_playing = false;
                play_pos = 0;
            }
            if (mu.button(if (loop) "Loop: On" else "Loop: Off", .none)) loop = !loop;

            // progress
            mu.layoutRow(2, &[_]c_int{ 100, -1 }, 0);
            mu.label("Position");
            var pos_buf: [32]u8 = undefined;
            const pos_sec = @as(f32, @floatFromInt(@min(play_pos, playback.len))) /
                @as(f32, @floatFromInt(t.sample_rate));
            const pos_str = std.fmt.bufPrintZ(&pos_buf, "{d:.2}s / {d:.2}s", .{ pos_sec, duration }) catch "?";
            mu.label(pos_str);
        } else {
            mu.layoutRow(1, &[_]c_int{-1}, 0);
            mu.label("Loading...");
        }
        mu.endWindow();
    }
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = pxl.math.Color.fromBytes(16, 18, 24, 255) });
    pxl.endPass();
}
