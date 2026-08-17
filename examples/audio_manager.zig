const std = @import("std");

const pxl = @import("pxl");
const assets = pxl.assets;
const mu = pxl.mu;

// --- assets & playback state -------------------------------------------------

var music: pxl.audio.SoundId = undefined;
var sfx_gun: pxl.audio.SoundId = undefined;
var sfx_drips: pxl.audio.SoundId = undefined;
var ambience: pxl.audio.SoundId = undefined;
var music_pb: ?pxl.audio.PlaybackId = null;
var ambience_pb: ?pxl.audio.PlaybackId = null;

var sfx_bus: pxl.audio.BusId = undefined;
var ambience_bus: pxl.audio.BusId = undefined;

var music_vol: f32 = 1.0;
var music_pitch: f32 = 1.0;
var music_pan: f32 = 0.0;
var bus_vol: f32 = 1.0;
var ambience_vol: f32 = 1.0;
var master_vol: f32 = 1.0;

// SFX bus effects
var lpf_on: bool = true;
var lpf_cutoff: f32 = 900;
var hpf_on: bool = false;
var hpf_cutoff: f32 = 400;
var delay_on: bool = false;
var delay_time: f32 = 0.25;
var delay_feedback: f32 = 0.35;
var delay_wet: f32 = 0.3;

// Ambience bus effects (a distinct stack from the SFX bus)
var amb_lpf_on: bool = true;
var amb_lpf_cutoff: f32 = 600;
var amb_delay_on: bool = false;
var amb_delay_time: f32 = 0.4;
var amb_delay_feedback: f32 = 0.5;
var amb_delay_wet: f32 = 0.4;

// Master effects
var master_lpf_on: bool = false;
var master_lpf_cutoff: f32 = 4000;

// Presets: named stacks of effects
var underwater_on: bool = false;
var drugged_on: bool = false;

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

fn toggleAmbience() void {
    if (ambience_pb) |id| {
        pxl.audio.stop(id);
        ambience_pb = null;
    } else {
        ambience_pb = pxl.audio.play(ambience, .{
            .bus = ambience_bus,
            .loop = true,
            .volume = ambience_vol,
        });
    }
}

/// Add or remove one effect on a bus. `build` produces the params to add;
/// `on` is the checkbox state that changed.
fn setBusEffect(b: *pxl.audio.Bus, comptime tag: pxl.audio.EffectType, on: bool, build: pxl.audio.EffectParams) void {
    if (on) {
        if (b.effects.get(tag) == null) b.effects.add(build, pxl.audio.outputRate());
    } else {
        b.effects.remove(tag);
    }
}

/// "Underwater" preset on the ambience bus: the bus's own lowpass provides
/// the muffling, reverb adds enclosed space, and a slow tremolo adds the
/// bubbling wobble.
fn setUnderwater(on: bool) void {
    const b = pxl.audio.bus(ambience_bus).?;
    if (on) {
        if (b.effects.get(.reverb) == null) b.effects.add(.{ .reverb = .{ .time = 0.5, .damping = 0.6, .wet = 0.5 } }, pxl.audio.outputRate());
        if (b.effects.get(.tremolo) == null) b.effects.add(.{ .tremolo = .{ .rate = 1.5, .depth = 0.2 } }, pxl.audio.outputRate());
    } else {
        b.effects.remove(.reverb);
        b.effects.remove(.tremolo);
    }
}

/// "Drugged" preset on the SFX bus: a phaser sweep plus a slow tremolo,
/// layered over the bus's own lowpass.
fn setDrugged(on: bool) void {
    const b = pxl.audio.bus(sfx_bus).?;
    if (on) {
        if (b.effects.get(.phaser) == null) b.effects.add(.{ .phaser = .{ .rate = 0.4, .depth = 0.8, .feedback = 0.4 } }, pxl.audio.outputRate());
        if (b.effects.get(.tremolo) == null) b.effects.add(.{ .tremolo = .{ .rate = 0.8, .depth = 0.3 } }, pxl.audio.outputRate());
    } else {
        b.effects.remove(.phaser);
        b.effects.remove(.tremolo);
    }
}

pub fn setup() !void {
    music = try assets.loadAudio(.tester, .{ .streamed = true });
    sfx_gun = try assets.loadAudio(.gunshot, .{});
    sfx_drips = try assets.loadAudio(.drips, .{});
    ambience = try assets.loadAudio(.drum_loop, .{ .streamed = true });

    sfx_bus = pxl.audio.createBus() orelse @panic("out of buses");
    pxl.audio.bus(sfx_bus).?.effects.add(.{ .lowpass = .{ .cutoff = lpf_cutoff } }, pxl.audio.outputRate());

    ambience_bus = pxl.audio.createBus() orelse @panic("out of buses");
    pxl.audio.bus(ambience_bus).?.effects.add(.{ .lowpass = .{ .cutoff = amb_lpf_cutoff } }, pxl.audio.outputRate());

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

/// Render a delay effect's three sliders for a bus. `b` supplies the chain;
/// rebuilding on time changes reallocates the delay ring buffer.
fn delaySliders(b: *pxl.audio.Bus, time: *f32, feedback: *f32, wet: *f32) void {
    if (labelSlider("Delay time", time, 0.02, 1.0)) {
        b.effects.remove(.delay);
        b.effects.add(.{ .delay = .{ .time = time.*, .feedback = feedback.*, .wet = wet.* } }, pxl.audio.outputRate());
    }
    if (labelSlider("Delay feedback", feedback, 0, 0.9)) {
        if (b.effects.get(.delay)) |e| e.params.delay.feedback = feedback.*;
    }
    if (labelSlider("Delay wet", wet, 0, 1)) {
        if (b.effects.get(.delay)) |e| e.params.delay.wet = wet.*;
    }
}

// --- callbacks ---------------------------------------------------------------

pub fn update() !void {
    if (music_pb) |id| {
        if (!pxl.audio.isPlaying(id)) music_pb = null;
    }
    if (ambience_pb) |id| {
        if (pxl.audio.playback(id) == null) ambience_pb = null;
    }

    if (mu.beginWindowEx("Audio Manager", .{ .x = 20, .y = 20, .w = 400, .h = 700 }, .{ .no_close = true })) {
        var row: [4]c_int = undefined;

        // Global transport
        mu.layoutRow(equalWidths(2, &row), &row, 0);
        if (mu.button("Restart music", .none)) startMusic();
        if (mu.button("Stop all", .none)) {
            pxl.audio.stopAll();
            music_pb = null;
            ambience_pb = null;
        }

        // Music
        if (mu.headerEx("Music", .{ .expanded = true })) {
            var buf: [64]u8 = undefined;
            const pos = if (music_pb) |id| pxl.audio.position(id) else 0;
            const dur = if (music_pb) |id| pxl.audio.duration(id) else 0;
            const pos_str = std.fmt.bufPrintZ(&buf, "{d:.1}s / {d:.1}s", .{ pos, dur }) catch "?";
            mu.layoutRow(1, &[_]c_int{-1}, 0);
            mu.label(pos_str);

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
        }

        // SFX bus
        if (mu.headerEx("SFX bus", .{ .expanded = true })) {
            if (labelSlider("SFX Vol", &bus_vol, 0, 1)) {
                pxl.audio.bus(sfx_bus).?.volume = bus_vol;
            }

            mu.layoutRow(equalWidths(2, &row), &row, 0);
            if (mu.button("Gunshot", .none)) playGunshot();
            if (mu.button("Drips", .none)) playDrips();

            mu.layoutRow(1, &[_]c_int{-1}, 0);
            if (mu.checkbox("Lowpass", &lpf_on)) setBusEffect(pxl.audio.bus(sfx_bus).?, .lowpass, lpf_on, .{ .lowpass = .{ .cutoff = lpf_cutoff } });
            if (lpf_on) {
                if (labelSlider("LPF cutoff", &lpf_cutoff, 50, 12000)) {
                    if (pxl.audio.bus(sfx_bus).?.effects.get(.lowpass)) |e| e.params.lowpass.cutoff = lpf_cutoff;
                }
            }

            mu.layoutRow(1, &[_]c_int{-1}, 0);
            if (mu.checkbox("Highpass", &hpf_on)) setBusEffect(pxl.audio.bus(sfx_bus).?, .highpass, hpf_on, .{ .highpass = .{ .cutoff = hpf_cutoff } });
            if (hpf_on) {
                if (labelSlider("HPF cutoff", &hpf_cutoff, 20, 4000)) {
                    if (pxl.audio.bus(sfx_bus).?.effects.get(.highpass)) |e| e.params.highpass.cutoff = hpf_cutoff;
                }
            }

            mu.layoutRow(1, &[_]c_int{-1}, 0);
            if (mu.checkbox("Delay", &delay_on)) setBusEffect(pxl.audio.bus(sfx_bus).?, .delay, delay_on, .{ .delay = .{ .time = delay_time, .feedback = delay_feedback, .wet = delay_wet } });
            if (delay_on) delaySliders(pxl.audio.bus(sfx_bus).?, &delay_time, &delay_feedback, &delay_wet);

            mu.layoutRow(1, &[_]c_int{-1}, 0);
            if (mu.checkbox("Drugged (phaser + wobble)", &drugged_on)) setDrugged(drugged_on);
        }

        // Ambience bus
        if (mu.headerEx("Ambience bus", .{ .expanded = true })) {
            mu.layoutRow(1, &[_]c_int{-1}, 0);
            if (mu.button(if (ambience_pb != null) "Stop ambience" else "Play ambience", .none)) toggleAmbience();

            if (labelSlider("Ambience Vol", &ambience_vol, 0, 1)) {
                pxl.audio.bus(ambience_bus).?.volume = ambience_vol;
            }

            mu.layoutRow(1, &[_]c_int{-1}, 0);
            if (mu.checkbox("Lowpass", &amb_lpf_on)) setBusEffect(pxl.audio.bus(ambience_bus).?, .lowpass, amb_lpf_on, .{ .lowpass = .{ .cutoff = amb_lpf_cutoff } });
            if (amb_lpf_on) {
                if (labelSlider("LPF cutoff", &amb_lpf_cutoff, 50, 12000)) {
                    if (pxl.audio.bus(ambience_bus).?.effects.get(.lowpass)) |e| e.params.lowpass.cutoff = amb_lpf_cutoff;
                }
            }

            mu.layoutRow(1, &[_]c_int{-1}, 0);
            if (mu.checkbox("Delay", &amb_delay_on)) setBusEffect(pxl.audio.bus(ambience_bus).?, .delay, amb_delay_on, .{ .delay = .{ .time = amb_delay_time, .feedback = amb_delay_feedback, .wet = amb_delay_wet } });
            if (amb_delay_on) delaySliders(pxl.audio.bus(ambience_bus).?, &amb_delay_time, &amb_delay_feedback, &amb_delay_wet);

            mu.layoutRow(1, &[_]c_int{-1}, 0);
            if (mu.checkbox("Underwater (reverb + wobble)", &underwater_on)) setUnderwater(underwater_on);
        }

        // Master
        if (mu.headerEx("Master", .{ .expanded = true })) {
            if (labelSlider("Master Vol", &master_vol, 0, 1)) {
                pxl.audio.masterBus().volume = master_vol;
            }

            mu.layoutRow(1, &[_]c_int{-1}, 0);
            if (mu.checkbox("Master lowpass", &master_lpf_on)) setBusEffect(pxl.audio.masterBus(), .lowpass, master_lpf_on, .{ .lowpass = .{ .cutoff = master_lpf_cutoff } });
            if (master_lpf_on) {
                if (labelSlider("LPF cutoff", &master_lpf_cutoff, 50, 12000)) {
                    if (pxl.audio.masterBus().effects.get(.lowpass)) |e| e.params.lowpass.cutoff = master_lpf_cutoff;
                }
            }
        }

        mu.endWindow();
    }
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = pxl.math.Color.fromBytes(16, 18, 24, 255) });
    pxl.endPass();
}
