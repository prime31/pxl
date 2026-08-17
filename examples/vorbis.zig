const std = @import("std");

const pxl = @import("pxl");
const mu = pxl.mu;
const sfxr = pxl.sfxr;

// --- tracks ---------------------------------------------------------------

const MaxTracks = 16;

const Track = struct {
    /// Manifest id, e.g. .tester for "assets/audio/tester.ogg".
    name: []const u8,
    sound: pxl.audio.SoundId,
    /// Track length in seconds (from the decoded stream header).
    duration: f64,
};

/// Every audio asset in the generated manifest, loaded as a streamed sound.
var tracks: [MaxTracks]?Track = [_]?Track{null} ** MaxTracks;
var track_count: usize = 0;

var scan_error: ?[:0]const u8 = null;
var scan_error_buf: [256]u8 = undefined;

/// Load every .ogg in the manifest as a streamed sound.
fn scanTracks() !void {
    for (std.meta.tags(pxl.assets.AudioId)) |id| {
        if (track_count >= MaxTracks) break;
        const name = @tagName(id);
        const sound = pxl.assets.loadAudio(id, .{ .streamed = true }) catch |err| {
            scan_error = std.fmt.bufPrintZ(&scan_error_buf, "Failed to load {s}: {s}", .{ name, @errorName(err) }) catch null;
            continue;
        };

        tracks[track_count] = .{
            .name = name,
            .sound = sound,
            .duration = pxl.audio.soundDuration(sound),
        };
        track_count += 1;
    }

    if (track_count == 0) {
        scan_error = "No audio assets in the manifest";
    } else {
        std.debug.print("vorbis: found {d} ogg track(s): ", .{track_count});
        for (0..track_count) |i| std.debug.print("{s} ", .{tracks[i].?.name});
        std.debug.print("\n", .{});
    }
}

// --- playback state ---------------------------------------------------------

var current: usize = 0; // index into tracks
var playback_id: ?pxl.audio.PlaybackId = null; // the playing/paused track
var loop_track: bool = true;
var track_volume: f32 = 1.0;
var track_pan: f32 = 0;
var track_pitch: f32 = 1;

// one-shot sfxr sounds, registered as in-memory buffers
const Sfx = struct {
    label: [:0]const u8,
    preset: sfxr.Preset,
    sound: ?pxl.audio.SoundId = null,
};
var sfx_sounds = [_]Sfx{
    .{ .label = "Coin", .preset = .pickup_coin },
    .{ .label = "Laser", .preset = .laser_shoot },
    .{ .label = "Explosion", .preset = .explosion },
};

fn playTrack(idx: usize) void {
    if (track_count == 0) return;
    stopPlayback();
    current = idx;
    playback_id = pxl.audio.play(tracks[idx].?.sound, .{
        .volume = track_volume,
        .pan = track_pan,
        .pitch = track_pitch,
        .loop = loop_track,
    });
}

fn stopPlayback() void {
    if (playback_id) |id| pxl.audio.stop(id);
    playback_id = null;
}

fn togglePlayPause() void {
    const id = playback_id orelse {
        // fresh start (this also rewinds a track that reached EOF)
        playTrack(current);
        return;
    };
    if (pxl.audio.isPlaying(id)) {
        pxl.audio.pause(id);
    } else {
        pxl.audio.unpause(id);
    }
}

fn setupSfx() void {
    for (&sfx_sounds) |*s| {
        var p = sfxr.Params{};
        p.apply(s.preset);
        var gen = sfxr.Sound.init(p, pxl.audio.outputRate());
        var vec: pxl.util.Vec(f32) = .empty;
        while (gen.nextSample()) |sample| vec.append(sample);
        defer vec.deinit();
        s.sound = pxl.audio.addBuffer(vec.items, 1, pxl.audio.outputRate());
    }
}

fn currentPosition() f64 {
    if (playback_id) |id| return pxl.audio.position(id);
    return 0;
}

pub fn setup() !void {
    try scanTracks();
    setupSfx();
    if (track_count > 0) playTrack(0);
}

pub fn shutdown() !void {
    for (0..track_count) |i| {
        pxl.assets.destroy(tracks[i].?.sound);
        tracks[i] = null;
    }
    track_count = 0;
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
    // The manager reaps a playback when a non-looping track reaches EOF;
    // mirror that here so the UI shows "Play" again.
    if (playback_id) |id| {
        if (pxl.audio.playback(id) == null) playback_id = null;
    }

    if (mu.beginWindowEx("Ogg Player", .{ .x = 20, .y = 20, .w = 380, .h = 560 }, .{ .no_close = true })) {
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
            const name = std.fmt.bufPrintZ(&name_buf, "{s}  ({d:.1}s)", .{ t.name, t.duration }) catch "?";
            mu.pushId(&i, @sizeOf(usize));
            if (mu.button(name, .none)) playTrack(i);
            mu.popId();
        }

        mu.layoutRow(1, &[_]c_int{-1}, 0);
        mu.label(" ");

        // Transport
        var row: [4]c_int = undefined;
        mu.layoutRow(equalWidths(3, &row), &row, 0);
        const play_label = if (playback_id) |id|
            (if (pxl.audio.isPlaying(id)) "Pause" else "Resume")
        else
            "Play";
        if (mu.button(play_label, .none)) togglePlayPause();
        if (mu.button("Stop", .none)) stopPlayback();
        if (mu.button(if (loop_track) "Loop: On" else "Loop: Off", .none)) {
            loop_track = !loop_track;
            if (playback_id) |id| {
                if (pxl.audio.playback(id)) |pb| pb.loop = loop_track;
            }
        }

        // Position
        mu.layoutRow(2, &[_]c_int{ 70, -1 }, 0);
        mu.label("Position");
        var pos_buf: [48]u8 = undefined;
        const duration = if (track_count > 0) tracks[current].?.duration else 0;
        const pos_str = std.fmt.bufPrintZ(&pos_buf, "{d:.1}s / {d:.1}s", .{ currentPosition(), duration }) catch "?";
        mu.label(pos_str);

        // Volume
        mu.layoutRow(2, &[_]c_int{ 70, -1 }, 0);
        mu.label("Volume");
        if (mu.slider(&track_volume, 0, 1, 0.01)) {
            if (playback_id) |id| {
                if (pxl.audio.playback(id)) |pb| pb.volume = track_volume;
            }
        }

        // Pan (-1 left .. +1 right)
        mu.layoutRow(2, &[_]c_int{ 70, -1 }, 0);
        mu.label("Pan");
        if (mu.slider(&track_pan, -1, 1, 0.01)) {
            if (playback_id) |id| {
                if (pxl.audio.playback(id)) |pb| pb.pan = track_pan;
            }
        }

        // Pitch (0.5 = octave down, 2 = octave up)
        mu.layoutRow(2, &[_]c_int{ 70, -1 }, 0);
        mu.label("Pitch");
        if (mu.slider(&track_pitch, 0.5, 2, 0.01)) {
            if (playback_id) |id| {
                if (pxl.audio.playback(id)) |pb| pb.pitch = track_pitch;
            }
        }

        // SFX demo — one-shot buffers played on top of the track
        if (mu.headerEx("SFX (mixed on top)", .{ .expanded = true })) {
            mu.layoutRow(equalWidths(3, &row), &row, 0);
            for (&sfx_sounds) |*s| {
                mu.pushId(&s.preset, @sizeOf(sfxr.Preset));
                if (mu.button(s.label, .none)) {
                    if (s.sound) |id| pxl.audio.playOneShot(id, .{ .volume = 0.8 });
                }
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
