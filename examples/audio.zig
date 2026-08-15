const std = @import("std");

const pxl = @import("pxl");
const mu = pxl.mu;
const sfxr = pxl.sfxr;

// --- sfxr generator state ------------------------------------------------

var params: sfxr.Params = .{};
var generated: pxl.util.Vec(f32) = .empty;
var dirty: bool = true;
var auto_play: bool = true;
var is_playing: bool = false;
var play_pos: usize = 0;

fn sampleRate() u32 {
    return @intCast(pxl.saudio.sampleRate());
}

/// Rerender the current params into `generated` (mono f32 samples).
fn regenerate() void {
    generated.clearRetainingCapacity();
    var sound = sfxr.Sound.init(params, sampleRate());
    while (sound.nextSample()) |s| generated.append(s);
}

fn play() void {
    if (generated.items.len == 0) regenerate();
    play_pos = 0;
    is_playing = generated.items.len > 0;
}

/// Stream whatever remains of `generated` into the sokol audio ring buffer.
fn streamAudio() void {
    if (!is_playing) return;
    while (play_pos < generated.items.len) {
        const available = pxl.saudio.expect();
        if (available <= 0) break;
        const n = @min(@as(usize, @intCast(available)), generated.items.len - play_pos);
        const pushed = pxl.saudio.push(&generated.items[play_pos], @intCast(n));
        if (pushed <= 0) break;
        play_pos += @intCast(pushed);
        if (@as(usize, @intCast(pushed)) < n) break;
    }
    if (play_pos >= generated.items.len) is_playing = false;
}

pub fn setup() !void {
    params.apply(.pickup_coin);
}

pub fn shutdown() !void {
    generated.deinit();
}

// --- microui helpers ------------------------------------------------------

fn labelSlider(label: [:0]const u8, value: *f32, low: f32, high: f32) bool {
    mu.layoutRow(2, &[_]c_int{ 110, -1 }, 0);
    mu.label(label);
    return mu.slider(value, low, high, 0.01);
}

/// Buttons scope their id by the preset/wave value so they can never
/// collide with other widgets that derive their id from the same label
/// (e.g. a section header named "Tone"). Without this, a same-id control
/// drawn later in the frame clears the button's hover state and the
/// button becomes unclickable.
fn presetButton(label: [:0]const u8, preset: sfxr.Preset) void {
    mu.pushId(&preset, @sizeOf(sfxr.Preset));
    defer mu.popId();
    if (mu.button(label, .none)) {
        params.apply(preset);
        dirty = true;
    }
}

fn waveButton(label: [:0]const u8, wave: sfxr.WaveType) void {
    mu.pushId(&wave, @sizeOf(sfxr.WaveType));
    defer mu.popId();
    if (mu.button(label, .none)) {
        params.wave_type = wave;
        dirty = true;
    }
}

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

// --- callbacks -------------------------------------------------------------

pub fn update() !void {
    // (Re)generate whenever a param changed, then preview if auto-play is on.
    if (dirty) {
        regenerate();
        dirty = false;
        if (auto_play) play();
    }

    streamAudio();

    if (mu.beginWindowEx("SFXR Generator", .{ .x = 20, .y = 20, .w = 360, .h = 600 }, .{ .no_close = true })) {
        // Presets — all of them randomize their values, so every press is new
        var row: [4]c_int = undefined;
        mu.layoutRow(equalWidths(3, &row), &row, 0);
        presetButton("Random", .random);
        presetButton("Coin", .pickup_coin);
        presetButton("Laser", .laser_shoot);
        mu.layoutRow(equalWidths(3, &row), &row, 0);
        presetButton("Explosion", .explosion);
        presetButton("Powerup", .power_up);
        presetButton("Hit/Hurt", .hit_hurt);
        mu.layoutRow(equalWidths(3, &row), &row, 0);
        presetButton("Jump", .jump);
        presetButton("Blip", .blip_select);
        presetButton("Synth", .synth);
        mu.layoutRow(equalWidths(3, &row), &row, 0);
        presetButton("Tone", .tone);
        presetButton("Click", .click);
        if (mu.button("Mutate", .none)) {
            params.mutate();
            dirty = true;
        }

        mu.layoutRow(2, &[_]c_int{ 100, -1 }, 0);
        if (mu.button("Play", .none)) play();
        _ = mu.checkbox("Auto", &auto_play);

        // Waveform selector
        mu.layoutRow(equalWidths(4, &row), &row, 0);
        waveButton("Square", .square);
        waveButton("Saw", .sawtooth);
        waveButton("Sine", .sine);
        waveButton("Noise", .noise);

        // Info line
        mu.layoutRow(2, &[_]c_int{ 110, -1 }, 0);
        mu.label("Duration");
        var info_buf: [48]u8 = undefined;
        const dur: f32 = @as(f32, @floatFromInt(generated.items.len)) / @as(f32, @floatFromInt(sampleRate()));
        const info = std.fmt.bufPrintZ(&info_buf, "{d:.2}s  {d} samples", .{ dur, generated.items.len }) catch "?";
        mu.label(info);

        // Parameter groups
        if (mu.headerEx("Envelope", .{ .expanded = true })) {
            if (labelSlider("Attack", &params.env_attack, 0, 1)) dirty = true;
            if (labelSlider("Sustain", &params.env_sustain, 0, 1)) dirty = true;
            if (labelSlider("Punch", &params.env_punch, 0, 1)) dirty = true;
            if (labelSlider("Decay", &params.env_decay, 0, 1)) dirty = true;
        }

        if (mu.headerEx("Tone", .{})) {
            if (labelSlider("Base Freq", &params.base_freq, 0, 1)) dirty = true;
            if (labelSlider("Freq Limit", &params.freq_limit, 0, 1)) dirty = true;
            if (labelSlider("Slide", &params.freq_ramp, -1, 1)) dirty = true;
            if (labelSlider("Delta Slide", &params.freq_dramp, -1, 1)) dirty = true;
        }

        if (mu.headerEx("Vibrato", .{})) {
            if (labelSlider("Strength", &params.vib_strength, 0, 1)) dirty = true;
            if (labelSlider("Speed", &params.vib_speed, 0, 1)) dirty = true;
        }

        if (mu.headerEx("Arpeggio", .{})) {
            if (labelSlider("Amount", &params.arp_mod, -1, 1)) dirty = true;
            if (labelSlider("Speed", &params.arp_speed, -1, 1)) dirty = true;
        }

        if (mu.headerEx("Square Duty", .{})) {
            if (labelSlider("Duty", &params.duty, -1, 1)) dirty = true;
            if (labelSlider("Sweep", &params.duty_ramp, -1, 1)) dirty = true;
        }

        if (mu.headerEx("Repeat", .{})) {
            if (labelSlider("Speed", &params.repeat_speed, -1, 1)) dirty = true;
        }

        if (mu.headerEx("Flanger", .{})) {
            if (labelSlider("Offset", &params.pha_offset, -1, 1)) dirty = true;
            if (labelSlider("Sweep", &params.pha_ramp, -1, 1)) dirty = true;
        }

        if (mu.headerEx("Filters", .{})) {
            if (labelSlider("LP Cutoff", &params.lpf_freq, 0, 1)) dirty = true;
            if (labelSlider("LP Sweep", &params.lpf_ramp, -1, 1)) dirty = true;
            if (labelSlider("LP Reso", &params.lpf_resonance, -1, 1)) dirty = true;
            if (labelSlider("HP Cutoff", &params.hpf_freq, 0, 1)) dirty = true;
            if (labelSlider("HP Sweep", &params.hpf_ramp, -1, 1)) dirty = true;
        }

        if (mu.headerEx("Mixer", .{})) {
            if (labelSlider("Volume", &params.sound_vol, 0, 1)) dirty = true;
        }

        mu.endWindow();
    }
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = pxl.math.Color.fromBytes(16, 18, 24, 255) });
    pxl.endPass();
}
