const std = @import("std");

const pxl = @import("pxl");
const mu = pxl.mu;

// --- assets & playback state -------------------------------------------------

var music: pxl.audio.SoundId = undefined;
var sfx_gun: pxl.audio.SoundId = undefined;
var sfx_drips: pxl.audio.SoundId = undefined;
var music_pb: ?pxl.audio.PlaybackId = null;

var sfx_bus: pxl.audio.BusId = undefined;

var music_vol: f32 = 1.0;
var music_pitch: f32 = 1.0;
var music_pan: f32 = 0.0;
var bus_vol: f32 = 1.0;

// SFX bus effect settings (all live-editable while sounds play)
var lpf_on: bool = true;
var lpf_cutoff: f32 = 900;
var hpf_on: bool = false;
var hpf_cutoff: f32 = 400;
var delay_on: bool = false;
var delay_time: f32 = 0.25;
var delay_feedback: f32 = 0.35;
var delay_wet: f32 = 0.3;

var rng_state: u32 = 12345;
fn nextRand() f32 {
    rng_state = rng_state *% 1664525 +% 1013904223;
    return @as(f32, @floatFromInt(rng_state >> 8)) / 16777216.0;
}

fn startMusic() void {
    if (music_pb) |id| pxl.audio.stop(id);
    music_pb = pxl.audio.play(music, .{
        .loop = true,
        .volume = music_vol,
        .pitch = music_pitch,
        .pan = music_pan,
    });
}

fn playGunshot() void {
    pxl.audio.playOneShot(sfx_gun, .{
        .bus = sfx_bus,
        .pitch = 0.8 + 0.4 * nextRand(),
        .pan = 2.0 * nextRand() - 1.0,
    });
}

fn playDrips() void {
    pxl.audio.playOneShot(sfx_drips, .{
        .bus = sfx_bus,
        .pitch = 0.8 + 0.4 * nextRand(),
        .pan = 2.0 * nextRand() - 1.0,
    });
}

/// Toggle one effect on the SFX bus. `build` produces the params to add;
/// `on` is the checkbox state that changed.
fn setEffect(comptime tag: pxl.audio.EffectType, on: bool, build: pxl.audio.EffectParams) void {
    const b = pxl.audio.bus(sfx_bus).?;
    if (on) {
        if (b.effects.get(tag) == null) b.effects.add(build, pxl.audio.outputRate());
    } else {
        b.effects.remove(tag);
    }
}

pub fn setup() !void {
    music = try pxl.audio.load("examples/assets/tester.ogg", .{ .streamed = true });
    sfx_gun = try pxl.audio.load("examples/assets/gunshot.ogg", .{});
    sfx_drips = try pxl.audio.load("examples/assets/drips.ogg", .{});

    sfx_bus = pxl.audio.createBus() orelse @panic("out of buses");
    pxl.audio.bus(sfx_bus).?.effects.add(.{ .lowpass = .{ .cutoff = lpf_cutoff } }, pxl.audio.outputRate());

    startMusic();
}

// --- microui helpers ---------------------------------------------------------

fn labelSlider(label: [:0]const u8, value: *f32, low: f32, high: f32) bool {
    mu.layoutRow(2, &[_]c_int{ 110, -1 }, 0);
    mu.label(label);
    return mu.slider(value, low, high, 0.01);
}

/// microui's `-1` width fills the *remaining* row width, so two `-1`s in
/// one row make the first item eat the whole row. Compute equal widths.
fn equalWidths(count: usize, out: *[4]c_int) c_int {
    const body = mu.getCurrentContainer().*.body;
    const spacing = mu.mu_ctx.style.*.spacing;
    const layout = mu.mu_ctx.layout_stack.items[@intCast(mu.mu_ctx.layout_stack.idx - 1)];
    const indent = layout.indent;
    const n: c_int = @intCast(count);
    const avail = body.w - indent - spacing * (n - 1);
    const w = @max(1, @divTrunc(avail, n));
    for (0..count) |i| out[i] = w;
    return n;
}

// --- callbacks ---------------------------------------------------------------

pub fn update() !void {
    if (music_pb) |id| {
        if (!pxl.audio.isPlaying(id)) music_pb = null;
    }

    if (mu.beginWindowEx("Audio Manager", .{ .x = 20, .y = 20, .w = 400, .h = 600 }, .{ .no_close = true })) {
        // Music transport
        var row: [4]c_int = undefined;
        mu.layoutRow(equalWidths(2, &row), &row, 0);
        if (mu.button("Restart music", .none)) startMusic();
        if (mu.button("Stop all", .none)) {
            pxl.audio.stopAll();
            music_pb = null;
        }

        // Position readout (seek is also available via pxl.audio.seek)
        var buf: [64]u8 = undefined;
        const pos = if (music_pb) |id| pxl.audio.position(id) else 0;
        const dur = if (music_pb) |id| pxl.audio.duration(id) else 0;
        const pos_str = std.fmt.bufPrintZ(&buf, "music {d:.1}s / {d:.1}s", .{ pos, dur }) catch "?";
        mu.layoutRow(1, &[_]c_int{-1}, 0);
        mu.label(pos_str);

        // Music controls
        if (labelSlider("Music Vol", &music_vol, 0, 1)) {
            if (music_pb) |id| {
                if (pxl.audio.playback(id)) |pb| pb.volume = music_vol;
            }
        }
        if (labelSlider("Music Pitch", &music_pitch, 0.5, 2)) {
            if (music_pb) |id| {
                if (pxl.audio.playback(id)) |pb| pb.pitch = music_pitch;
            }
        }
        if (labelSlider("Music Pan", &music_pan, -1, 1)) {
            if (music_pb) |id| {
                if (pxl.audio.playback(id)) |pb| pb.pan = music_pan;
            }
        }

        // SFX bus
        mu.layoutRow(1, &[_]c_int{-1}, 0);
        mu.label("SFX bus");
        if (labelSlider("SFX Vol", &bus_vol, 0, 1)) {
            pxl.audio.bus(sfx_bus).?.volume = bus_vol;
        }

        mu.layoutRow(equalWidths(2, &row), &row, 0);
        if (mu.button("Gunshot", .none)) playGunshot();
        if (mu.button("Drips", .none)) playDrips();

        // Effect chain on the SFX bus
        mu.layoutRow(1, &[_]c_int{-1}, 0);
        mu.label("SFX bus effects");

        mu.layoutRow(1, &[_]c_int{-1}, 0);
        if (mu.checkbox("Lowpass", &lpf_on)) setEffect(.lowpass, lpf_on, .{ .lowpass = .{ .cutoff = lpf_cutoff } });
        if (lpf_on) {
            if (labelSlider("LPF cutoff", &lpf_cutoff, 50, 12000)) {
                if (pxl.audio.bus(sfx_bus).?.effects.get(.lowpass)) |e| e.params.lowpass.cutoff = lpf_cutoff;
            }
        }

        mu.layoutRow(1, &[_]c_int{-1}, 0);
        if (mu.checkbox("Highpass", &hpf_on)) setEffect(.highpass, hpf_on, .{ .highpass = .{ .cutoff = hpf_cutoff } });
        if (hpf_on) {
            if (labelSlider("HPF cutoff", &hpf_cutoff, 20, 4000)) {
                if (pxl.audio.bus(sfx_bus).?.effects.get(.highpass)) |e| e.params.highpass.cutoff = hpf_cutoff;
            }
        }

        mu.layoutRow(1, &[_]c_int{-1}, 0);
        if (mu.checkbox("Delay", &delay_on)) setEffect(.delay, delay_on, .{ .delay = .{ .time = delay_time, .feedback = delay_feedback, .wet = delay_wet } });
        if (delay_on) {
            // Changing the delay time reallocates the ring buffer, so rebuild
            // the delay effect instead of editing its params in place.
            if (labelSlider("Delay time", &delay_time, 0.02, 1.0)) {
                const b = pxl.audio.bus(sfx_bus).?;
                b.effects.remove(.delay);
                b.effects.add(.{ .delay = .{ .time = delay_time, .feedback = delay_feedback, .wet = delay_wet } }, pxl.audio.outputRate());
            }
            if (labelSlider("Delay feedback", &delay_feedback, 0, 0.9)) {
                if (pxl.audio.bus(sfx_bus).?.effects.get(.delay)) |e| e.params.delay.feedback = delay_feedback;
            }
            if (labelSlider("Delay wet", &delay_wet, 0, 1)) {
                if (pxl.audio.bus(sfx_bus).?.effects.get(.delay)) |e| e.params.delay.wet = delay_wet;
            }
        }

        mu.endWindow();
    }
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = pxl.math.Color.fromBytes(16, 18, 24, 255) });
    pxl.endPass();
}
