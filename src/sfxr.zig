//! Procedural retro sound effects — a Zig port of the classic sfxr
//! chip-tune generator by DrPetter (Tomas Pettersson), following the
//! jsfxr 1.0 parameter model.
//!
//! Everything here is pure DSP: give it a `Params`, get back a stream of
//! mono `f32` samples. Feed the samples into `pxl.saudio` (or any audio
//! backend) to play them.
//!
//! ```
//! var p = pxl.sfxr.Params{};
//! p.apply(.pickup_coin);
//! var sound = pxl.sfxr.Sound.init(p, sample_rate);
//! while (sound.nextSample()) |s| { /* push s into the audio stream */ }
//! ```

const std = @import("std");
const pxl = @import("pxl.zig");

const Oversampling = 8;
const MaxFlangerDelay = 1024;
const NoiseBufferSize = 32;

pub const WaveType = enum(u8) {
    square,
    sawtooth,
    sine,
    noise,
};

pub const Preset = enum {
    pickup_coin,
    laser_shoot,
    explosion,
    power_up,
    hit_hurt,
    jump,
    blip_select,
    synth,
    tone,
    click,
    random,
};

/// All parameters live in [0, 1] (or [-1, 1] where noted "signed"),
/// exactly like the original sfxr tool, so they map 1:1 onto UI sliders.
pub const Params = struct {
    wave_type: WaveType = .square,

    // envelope
    env_attack: f32 = 0.0,
    env_sustain: f32 = 0.3,
    env_punch: f32 = 0.0,
    env_decay: f32 = 0.4,

    // tone
    base_freq: f32 = 0.3,
    freq_limit: f32 = 0.0,
    freq_ramp: f32 = 0.0, // signed
    freq_dramp: f32 = 0.0, // signed

    // vibrato
    vib_strength: f32 = 0.0,
    vib_speed: f32 = 0.0,

    // arpeggio
    arp_mod: f32 = 0.0, // signed
    arp_speed: f32 = 0.0,

    // square wave duty
    duty: f32 = 0.0, // signed
    duty_ramp: f32 = 0.0, // signed

    // repeat
    repeat_speed: f32 = 0.0, // signed

    // flanger
    pha_offset: f32 = 0.0, // signed
    pha_ramp: f32 = 0.0, // signed

    // filters
    lpf_freq: f32 = 1.0,
    lpf_ramp: f32 = 0.0, // signed
    lpf_resonance: f32 = 0.0, // signed
    hpf_freq: f32 = 0.0,
    hpf_ramp: f32 = 0.0, // signed

    /// Output level, [0, 1]. Maps to `gain = exp(sound_vol) - 1`.
    sound_vol: f32 = 0.5,

    /// Reset to defaults (keeping the current volume) and roll a fresh
    /// sound for the given preset. Presets randomize their parameters,
    /// so every call produces a different sound.
    pub fn apply(self: *Params, preset: Preset) void {
        const vol = self.sound_vol;
        self.* = .{ .sound_vol = vol };
        switch (preset) {
            .pickup_coin => self.pickupCoin(),
            .laser_shoot => self.laserShoot(),
            .explosion => self.explosion(),
            .power_up => self.powerUp(),
            .hit_hurt => self.hitHurt(),
            .jump => self.jump(),
            .blip_select => self.blipSelect(),
            .synth => self.synth(),
            .tone => self.tone(),
            .click => self.click(),
            .random => self.randomize(),
        }
    }

    /// Randomize every parameter.
    pub fn randomize(self: *Params) void {
        self.wave_type = intToWaveType(rnd(3));
        if (rnd(1) == 1) {
            self.base_freq = cube(randSigned()) + 0.5;
        } else {
            self.base_freq = sqr(rand());
        }
        self.freq_limit = 0;
        self.freq_ramp = pow5(randSigned());
        if (self.base_freq > 0.7 and self.freq_ramp > 0.2) self.freq_ramp = -self.freq_ramp;
        if (self.base_freq < 0.2 and self.freq_ramp < -0.05) self.freq_ramp = -self.freq_ramp;
        self.freq_dramp = cube(randSigned());
        self.duty = randSigned();
        self.duty_ramp = cube(randSigned());
        self.vib_strength = cube(randSigned());
        self.vib_speed = randSigned();
        self.env_attack = cube(randSigned());
        self.env_sustain = sqr(randSigned());
        self.env_decay = randSigned();
        self.env_punch = sqr(rand() * 0.8);
        if (self.env_attack + self.env_sustain + self.env_decay < 0.2) {
            self.env_sustain += 0.2 + rand() * 0.3;
            self.env_decay += 0.2 + rand() * 0.3;
        }
        self.lpf_resonance = randSigned();
        self.lpf_freq = 1.0 - cube(rand());
        self.lpf_ramp = cube(randSigned());
        if (self.lpf_freq < 0.1 and self.lpf_ramp < -0.05) self.lpf_ramp = -self.lpf_ramp;
        self.hpf_freq = pow5(rand());
        self.hpf_ramp = pow5(randSigned());
        self.pha_offset = cube(randSigned());
        self.pha_ramp = cube(randSigned());
        self.repeat_speed = randSigned();
        self.arp_speed = randSigned();
        self.arp_mod = randSigned();
    }

    /// Randomly nudge a handful of parameters, keeping the sound in the
    /// same family. Great for building variations on a preset.
    pub fn mutate(self: *Params) void {
        maybeNudge(&self.base_freq);
        maybeNudge(&self.freq_ramp);
        maybeNudge(&self.freq_dramp);
        maybeNudge(&self.duty);
        maybeNudge(&self.duty_ramp);
        maybeNudge(&self.vib_strength);
        maybeNudge(&self.vib_speed);
        maybeNudge(&self.env_attack);
        maybeNudge(&self.env_sustain);
        maybeNudge(&self.env_decay);
        maybeNudge(&self.env_punch);
        maybeNudge(&self.lpf_resonance);
        maybeNudge(&self.lpf_freq);
        maybeNudge(&self.lpf_ramp);
        maybeNudge(&self.hpf_freq);
        maybeNudge(&self.hpf_ramp);
        maybeNudge(&self.pha_offset);
        maybeNudge(&self.pha_ramp);
        maybeNudge(&self.repeat_speed);
        maybeNudge(&self.arp_speed);
        maybeNudge(&self.arp_mod);
    }

    pub fn pickupCoin(self: *Params) void {
        self.wave_type = .sawtooth;
        self.base_freq = 0.4 + rand() * 0.5;
        self.env_attack = 0;
        self.env_sustain = rand() * 0.1;
        self.env_decay = 0.1 + rand() * 0.4;
        self.env_punch = 0.3 + rand() * 0.3;
        if (rnd(1) == 1) {
            self.arp_speed = 0.5 + rand() * 0.2;
            self.arp_mod = 0.2 + rand() * 0.4;
        }
    }

    pub fn laserShoot(self: *Params) void {
        self.wave_type = intToWaveType(rnd(2));
        if (self.wave_type == .sine and rnd(1) == 1)
            self.wave_type = intToWaveType(rnd(1));
        if (rnd(2) == 0) {
            self.base_freq = 0.3 + rand() * 0.6;
            self.freq_limit = rand() * 0.1;
            self.freq_ramp = -0.35 - rand() * 0.3;
        } else {
            self.base_freq = 0.5 + rand() * 0.5;
            self.freq_limit = self.base_freq - 0.2 - rand() * 0.6;
            if (self.freq_limit < 0.2) self.freq_limit = 0.2;
            self.freq_ramp = -0.15 - rand() * 0.2;
        }
        if (self.wave_type == .sawtooth) self.duty = 1;
        if (rnd(1) == 1) {
            self.duty = rand() * 0.5;
            self.duty_ramp = rand() * 0.2;
        } else {
            self.duty = 0.4 + rand() * 0.5;
            self.duty_ramp = -rand() * 0.7;
        }
        self.env_attack = 0;
        self.env_sustain = 0.1 + rand() * 0.2;
        self.env_decay = rand() * 0.4;
        if (rnd(1) == 1) self.env_punch = rand() * 0.3;
        if (rnd(2) == 0) {
            self.pha_offset = rand() * 0.2;
            self.pha_ramp = -rand() * 0.2;
        }
        self.hpf_freq = rand() * 0.3;
    }

    pub fn explosion(self: *Params) void {
        self.wave_type = .noise;
        if (rnd(1) == 1) {
            self.base_freq = sqr(0.1 + rand() * 0.4);
            self.freq_ramp = -0.1 + rand() * 0.4;
        } else {
            self.base_freq = sqr(0.2 + rand() * 0.7);
            self.freq_ramp = -0.2 - rand() * 0.2;
        }
        if (rnd(4) == 0) self.freq_ramp = 0;
        if (rnd(2) == 0) self.repeat_speed = 0.3 + rand() * 0.5;
        self.env_attack = 0;
        self.env_sustain = 0.1 + rand() * 0.3;
        self.env_decay = rand() * 0.5;
        if (rnd(1) == 1) {
            self.pha_offset = -0.3 + rand() * 0.9;
            self.pha_ramp = -rand() * 0.3;
        }
        self.env_punch = 0.2 + rand() * 0.6;
        if (rnd(1) == 1) {
            self.vib_strength = rand() * 0.7;
            self.vib_speed = rand() * 0.6;
        }
        if (rnd(2) == 0) {
            self.arp_speed = 0.6 + rand() * 0.3;
            self.arp_mod = 0.8 - rand() * 1.6;
        }
    }

    pub fn powerUp(self: *Params) void {
        if (rnd(1) == 1) {
            self.wave_type = .sawtooth;
            self.duty = 1;
        } else {
            self.duty = rand() * 0.6;
        }
        self.base_freq = 0.2 + rand() * 0.3;
        if (rnd(1) == 1) {
            self.freq_ramp = 0.1 + rand() * 0.4;
            self.repeat_speed = 0.4 + rand() * 0.4;
        } else {
            self.freq_ramp = 0.05 + rand() * 0.2;
            if (rnd(1) == 1) {
                self.vib_strength = rand() * 0.7;
                self.vib_speed = rand() * 0.6;
            }
        }
        self.env_attack = 0;
        self.env_sustain = rand() * 0.4;
        self.env_decay = 0.1 + rand() * 0.4;
    }

    pub fn hitHurt(self: *Params) void {
        self.wave_type = intToWaveType(rnd(2));
        if (self.wave_type == .sine) self.wave_type = .noise;
        if (self.wave_type == .square) self.duty = rand() * 0.6;
        if (self.wave_type == .sawtooth) self.duty = 1;
        self.base_freq = 0.2 + rand() * 0.6;
        self.freq_ramp = -0.3 - rand() * 0.4;
        self.env_attack = 0;
        self.env_sustain = rand() * 0.1;
        self.env_decay = 0.1 + rand() * 0.2;
        if (rnd(1) == 1) self.hpf_freq = rand() * 0.3;
    }

    pub fn jump(self: *Params) void {
        self.wave_type = .square;
        self.duty = rand() * 0.6;
        self.base_freq = 0.3 + rand() * 0.3;
        self.freq_ramp = 0.1 + rand() * 0.2;
        self.env_attack = 0;
        self.env_sustain = 0.1 + rand() * 0.3;
        self.env_decay = 0.1 + rand() * 0.2;
        if (rnd(1) == 1) self.hpf_freq = rand() * 0.3;
        if (rnd(1) == 1) self.lpf_freq = 1 - rand() * 0.6;
    }

    pub fn blipSelect(self: *Params) void {
        self.wave_type = intToWaveType(rnd(1));
        if (self.wave_type == .square) self.duty = rand() * 0.6 else self.duty = 1;
        self.base_freq = 0.2 + rand() * 0.4;
        self.env_attack = 0;
        self.env_sustain = 0.1 + rand() * 0.1;
        self.env_decay = rand() * 0.2;
        self.hpf_freq = 0.1;
    }

    pub fn synth(self: *Params) void {
        self.wave_type = intToWaveType(rnd(1));
        const freqs = [_]f32{ 0.2723171360931539, 0.19255692561524382, 0.13615778746815113 };
        self.base_freq = freqs[rnd(2)];
        self.env_attack = if (rnd(4) > 3) rand() * 0.5 else 0;
        self.env_sustain = rand();
        self.env_punch = rand();
        self.env_decay = rand() * 0.9 + 0.1;
        const arp_mods = [_]f32{ 0, 0, 0, 0, -0.3162, 0.7454, 0.7454 };
        self.arp_mod = arp_mods[rnd(6)];
        self.arp_speed = rand() * 0.5 + 0.4;
        self.duty = rand();
        self.duty_ramp = if (rnd(2) == 2) rand() else 0;
        self.lpf_freq = if (rnd(1) == 0) 1 else 0.9 * sqr(rand()) + 0.1;
        self.lpf_ramp = randSigned();
        self.lpf_resonance = rand();
        self.hpf_freq = if (rnd(3) == 3) rand() else 0;
        self.hpf_ramp = if (rnd(3) == 3) rand() else 0;
    }

    /// A pure 440 Hz sine for 1 second (reference tone).
    pub fn tone(self: *Params) void {
        self.wave_type = .sine;
        self.base_freq = 0.35173364; // 440 Hz
        self.env_attack = 0;
        self.env_sustain = 0.6641; // ~1 sec
        self.env_decay = 0;
        self.env_punch = 0;
    }

    pub fn click(self: *Params) void {
        if (rnd(1) == 0) {
            self.explosion();
        } else {
            self.hitHurt();
        }
        if (rnd(1) == 1) self.freq_ramp = -0.5 + rand();
        if (rnd(1) == 1) {
            self.env_sustain = (rand() * 0.4 + 0.2) * self.env_sustain;
            self.env_decay = (rand() * 0.4 + 0.2) * self.env_decay;
        }
        if (rnd(3) == 0) self.env_attack = rand() * 0.3;
        self.base_freq = 1 - rand() * 0.25;
        self.hpf_freq = 1 - rand() * 0.1;
    }
};

/// A streaming sfxr voice. Initialize once per sound, then pull samples
/// with `nextSample()` until it returns `null`.
pub const Sound = struct {
    params: Params,
    sample_rate: u32,

    // init-time state (derived from params)
    wave_shape: WaveType,
    fltw: f32,
    enable_lpf: bool,
    fltw_d: f32,
    fltdmp: f32,
    flthp: f32,
    flthp_d: f32,
    vibrato_speed: f32,
    vibrato_amp: f32,
    envelope_length: [3]u32,
    envelope_punch: f32,
    flanger_offset: f32,
    flanger_offset_slide: f32,
    repeat_time: u32,
    gain: f32,
    summands: u32,

    // run state
    period: f32,
    period_max: f32,
    enable_freq_cutoff: bool,
    period_mult: f32,
    period_mult_slide: f32,
    duty_cycle: f32,
    duty_cycle_slide: f32,
    arpeggio_multiplier: f32,
    arpeggio_time: u32,
    elapsed_since_repeat: u32,
    fltp: f32,
    fltdp: f32,
    fltphp: f32,
    noise_buffer: [NoiseBufferSize]f32,
    envelope_stage: u8,
    envelope_elapsed: u32,
    vibrato_phase: f32,
    phase: u32,
    ipp: u32,
    flanger_buffer: [MaxFlangerDelay]f32,
    t: u32,
    sample_sum: f32,
    num_summed: u32,
    sample: f32,
    done: bool,

    pub fn init(params: Params, sample_rate: u32) Sound {
        const fltw = cube(params.lpf_freq) * 0.1;
        var s = Sound{
            .params = params,
            .sample_rate = sample_rate,
            .wave_shape = params.wave_type,
            .fltw = fltw,
            .enable_lpf = params.lpf_freq != 1.0,
            .fltw_d = 1.0 + params.lpf_ramp * 0.0001,
            .fltdmp = 5.0 / (1.0 + sqr(params.lpf_resonance) * 20.0) * (0.01 + fltw),
            .flthp = sqr(params.hpf_freq) * 0.1,
            .flthp_d = 1.0 + params.hpf_ramp * 0.0003,
            .vibrato_speed = sqr(params.vib_speed) * 0.01,
            .vibrato_amp = params.vib_strength * 0.5,
            .envelope_length = .{
                @intFromFloat(params.env_attack * params.env_attack * 100000.0),
                @intFromFloat(params.env_sustain * params.env_sustain * 100000.0),
                @intFromFloat(params.env_decay * params.env_decay * 100000.0),
            },
            .envelope_punch = params.env_punch,
            .flanger_offset = signedSquare(params.pha_offset, 1020.0),
            .flanger_offset_slide = signedSquare(params.pha_ramp, 1.0),
            .repeat_time = if (params.repeat_speed == 0.0)
                0
            else
                @intFromFloat(sqr(1.0 - params.repeat_speed) * 20000.0 + 32.0),
            .gain = std.math.exp(params.sound_vol) - 1.0,
            .summands = @max(1, 44100 / @max(sample_rate, 1)),
            .noise_buffer = [_]f32{0} ** NoiseBufferSize,
            .flanger_buffer = [_]f32{0} ** MaxFlangerDelay,
            .period = 0,
            .period_max = 0,
            .enable_freq_cutoff = false,
            .period_mult = 0,
            .period_mult_slide = 0,
            .duty_cycle = 0,
            .duty_cycle_slide = 0,
            .arpeggio_multiplier = 1,
            .arpeggio_time = 0,
            .elapsed_since_repeat = 0,
            .fltp = 0,
            .fltdp = 0,
            .fltphp = 0,
            .envelope_stage = 0,
            .envelope_elapsed = 0,
            .vibrato_phase = 0,
            .phase = 0,
            .ipp = 0,
            .t = 0,
            .sample_sum = 0,
            .num_summed = 0,
            .sample = 0,
            .done = false,
        };
        if (s.fltdmp > 0.8) s.fltdmp = 0.8;
        s.refillNoise();
        s.initForRepeat();
        return s;
    }

    /// Produce the next mono sample, or `null` when the sound is done.
    pub fn nextSample(self: *Sound) ?f32 {
        if (self.done) return null;
        while (true) {
            self.step();
            if (self.done) return null;

            self.sample_sum += self.sample;
            self.num_summed += 1;
            if (self.num_summed >= self.summands) {
                self.num_summed = 0;
                const s = self.sample_sum / @as(f32, @floatFromInt(self.summands));
                self.sample_sum = 0;
                return s / @as(f32, Oversampling) * self.gain;
            }
        }
    }

    /// Advance one 44100 Hz "tick" (8 oversampled sub-samples) and store
    /// the summed result in `self.sample`.
    fn step(self: *Sound) void {
        // repeat
        if (self.repeat_time != 0) {
            self.elapsed_since_repeat += 1;
            if (self.elapsed_since_repeat >= self.repeat_time) self.initForRepeat();
        }
        // arpeggio
        if (self.arpeggio_time != 0 and self.t >= self.arpeggio_time) {
            self.arpeggio_time = 0;
            self.period *= self.arpeggio_multiplier;
        }
        // frequency slide
        self.period_mult += self.period_mult_slide;
        self.period *= self.period_mult;
        if (self.period > self.period_max) {
            self.period = self.period_max;
            if (self.enable_freq_cutoff) {
                self.done = true;
                return;
            }
        }
        // vibrato
        var rfperiod = self.period;
        if (self.vibrato_amp > 0) {
            self.vibrato_phase += self.vibrato_speed;
            rfperiod = self.period * (1.0 + @sin(self.vibrato_phase) * self.vibrato_amp);
        }
        var iperiod: u32 = @intFromFloat(@floor(rfperiod));
        if (iperiod < Oversampling) iperiod = Oversampling;
        // duty
        self.duty_cycle += self.duty_cycle_slide;
        if (self.duty_cycle < 0.0) self.duty_cycle = 0.0;
        if (self.duty_cycle > 0.5) self.duty_cycle = 0.5;
        // volume envelope (skip zero-length stages to avoid 0/0 NaNs)
        self.envelope_elapsed += 1;
        if (self.envelope_elapsed > self.envelope_length[self.envelope_stage]) {
            self.envelope_elapsed = 0;
            self.envelope_stage += 1;
            if (self.envelope_stage > 2) {
                self.done = true;
                return;
            }
            while (self.envelope_length[self.envelope_stage] == 0) {
                self.envelope_stage += 1;
                if (self.envelope_stage > 2) {
                    self.done = true;
                    return;
                }
            }
        }
        const envf = @as(f32, @floatFromInt(self.envelope_elapsed)) /
            @as(f32, @floatFromInt(self.envelope_length[self.envelope_stage]));
        const env_vol: f32 = switch (self.envelope_stage) {
            0 => envf,
            1 => 1.0 + (1.0 - envf) * 2.0 * self.envelope_punch,
            else => 1.0 - envf,
        };
        // flanger step
        self.flanger_offset += self.flanger_offset_slide;
        var iphase: u32 = @intFromFloat(@abs(@floor(self.flanger_offset)));
        if (iphase > MaxFlangerDelay - 1) iphase = MaxFlangerDelay - 1;
        // high-pass cutoff sweep
        self.flthp *= self.flthp_d;
        if (self.flthp < 0.00001) self.flthp = 0.00001;
        if (self.flthp > 0.1) self.flthp = 0.1;
        // oversampling
        var sample: f32 = 0;
        var si: u32 = 0;
        while (si < Oversampling) : (si += 1) {
            var sub_sample: f32 = 0;
            self.phase += 1;
            if (self.phase >= iperiod) {
                self.phase %= iperiod;
                if (self.wave_shape == .noise) self.refillNoise();
            }
            const fp = @as(f32, @floatFromInt(self.phase)) / @as(f32, @floatFromInt(iperiod));
            switch (self.wave_shape) {
                .square => sub_sample = if (fp < self.duty_cycle) 0.5 else -0.5,
                .sawtooth => {
                    if (fp < self.duty_cycle) {
                        sub_sample = -1.0 + 2.0 * fp / self.duty_cycle;
                    } else {
                        sub_sample = 1.0 - 2.0 * (fp - self.duty_cycle) / (1.0 - self.duty_cycle);
                    }
                },
                .sine => sub_sample = @sin(fp * std.math.tau),
                .noise => {
                    const idx = @as(u32, @intFromFloat(@floor(
                        @as(f32, @floatFromInt(self.phase)) * @as(f32, @floatFromInt(NoiseBufferSize)) /
                            @as(f32, @floatFromInt(iperiod)),
                    )));
                    sub_sample = self.noise_buffer[idx];
                },
            }
            // low-pass filter
            const pp = self.fltp;
            self.fltw *= self.fltw_d;
            if (self.fltw < 0.0) self.fltw = 0.0;
            if (self.fltw > 0.1) self.fltw = 0.1;
            if (self.enable_lpf) {
                self.fltdp += (sub_sample - self.fltp) * self.fltw;
                self.fltdp -= self.fltdp * self.fltdmp;
            } else {
                self.fltp = sub_sample;
                self.fltdp = 0;
            }
            self.fltp += self.fltdp;
            // high-pass filter
            self.fltphp += self.fltp - pp;
            self.fltphp -= self.fltphp * self.flthp;
            sub_sample = self.fltphp;
            // flanger
            self.flanger_buffer[self.ipp & (MaxFlangerDelay - 1)] = sub_sample;
            sub_sample += self.flanger_buffer[(self.ipp -% iphase +% MaxFlangerDelay) & (MaxFlangerDelay - 1)];
            self.ipp = (self.ipp + 1) & (MaxFlangerDelay - 1);
            sample += sub_sample * env_vol;
        }
        self.sample = sample;
        self.t += 1;
    }

    /// (Re)start the frequency/period state from the stored params. Also
    /// used by the repeat feature to restart the sound periodically.
    fn initForRepeat(self: *Sound) void {
        const p = self.params;
        self.elapsed_since_repeat = 0;
        self.period = 100.0 / (p.base_freq * p.base_freq + 0.001);
        self.period_max = 100.0 / (p.freq_limit * p.freq_limit + 0.001);
        self.enable_freq_cutoff = p.freq_limit > 0.0;
        self.period_mult = 1.0 - cube(p.freq_ramp) * 0.01;
        self.period_mult_slide = -cube(p.freq_dramp) * 0.000001;
        self.duty_cycle = 0.5 - p.duty * 0.5;
        self.duty_cycle_slide = -p.duty_ramp * 0.00005;
        if (p.arp_mod >= 0.0) {
            self.arpeggio_multiplier = 1.0 - sqr(p.arp_mod) * 0.9;
        } else {
            self.arpeggio_multiplier = 1.0 + sqr(p.arp_mod) * 10.0;
        }
        self.arpeggio_time = if (p.arp_speed == 1.0)
            0
        else
            @intFromFloat(sqr(1.0 - p.arp_speed) * 20000.0 + 32.0);
    }

    fn refillNoise(self: *Sound) void {
        for (&self.noise_buffer) |*n| n.* = randSigned();
    }
};

/// Render a sound into `out` (mono f32 samples). Returns the number of
/// samples written; the sound may be shorter than `out`.
pub fn render(params: Params, sample_rate: u32, out: []f32) usize {
    var sound = Sound.init(params, sample_rate);
    var n: usize = 0;
    while (n < out.len) {
        const s = sound.nextSample() orelse break;
        out[n] = s;
        n += 1;
    }
    return n;
}

// --- random helpers -----------------------------------------------------

/// (Re)seed the global RNG. Presets and noise use it, so seeding makes
/// generated sounds reproducible.
pub fn seed(new_seed: u64) void {
    pxl.math.rand.seed(new_seed);
}

/// Uniform float in [0, 1).
fn rand() f32 {
    return pxl.math.rand.float(f32);
}

/// Uniform float in [-1, 1).
fn randSigned() f32 {
    return pxl.math.rand.float(f32) * 2.0 - 1.0;
}

/// Uniform int in [0, max] (inclusive).
fn rnd(max: u32) u32 {
    return pxl.math.rand.uintLessThan(u32, max + 1);
}

fn maybeNudge(value: *f32) void {
    if (rnd(1) == 1) value.* += rand() * 0.1 - 0.05;
}

// --- math helpers -------------------------------------------------------

fn sqr(x: f32) f32 {
    return x * x;
}

fn cube(x: f32) f32 {
    return x * x * x;
}

fn pow5(x: f32) f32 {
    const x2 = x * x;
    return x2 * x2 * x;
}

/// Signed square: keeps the sign of x, squares the magnitude, scaled by `scale`.
fn signedSquare(x: f32, scale: f32) f32 {
    const mag = sqr(x) * scale;
    return if (x < 0.0) -mag else mag;
}

fn intToWaveType(v: u32) WaveType {
    return switch (v) {
        0 => .square,
        1 => .sawtooth,
        2 => .sine,
        else => .noise,
    };
}

// --- tests --------------------------------------------------------------

test "tone preset renders an expected length of finite samples" {
    var p = Params{};
    p.apply(.tone);
    // attack=0, sustain=0.6641 -> floor(0.6641^2 * 100000) = 44102 samples,
    // decay=0 is skipped entirely, so we get 44103 ticks (one envelope sample each).
    var sound = Sound.init(p, 44100);
    var count: usize = 0;
    var max_abs: f32 = 0;
    while (sound.nextSample()) |s| {
        count += 1;
        max_abs = @max(max_abs, @abs(s));
        try std.testing.expect(std.math.isFinite(s));
    }
    try std.testing.expectEqual(@as(usize, 44103), count);
    try std.testing.expect(max_abs > 0.0);
}

test "presets always produce finite samples" {
    var p = Params{};
    inline for (std.meta.tags(Preset)) |preset| {
        p.apply(preset);
        var sound = Sound.init(p, 44100);
        var count: usize = 0;
        var max_abs: f32 = 0;
        while (sound.nextSample()) |s| : (count += 1) {
            try std.testing.expect(std.math.isFinite(s));
            max_abs = @max(max_abs, @abs(s));
        }
        try std.testing.expect(count > 0);
        // Sustain punch and the flanger can legitimately push peaks past
        // unity; just make sure nothing exploded into huge values.
        try std.testing.expect(max_abs < 10.0);
    }
}

test "randomize produces valid params and keeps volume" {
    var p = Params{ .sound_vol = 0.8 };
    p.apply(.random);
    try std.testing.expect(std.math.isFinite(p.base_freq));
    try std.testing.expect(std.math.isFinite(p.freq_ramp));
    try std.testing.expect(std.math.isFinite(p.env_sustain));
    try std.testing.expectEqual(@as(f32, 0.8), p.sound_vol);
    // negative base_freq is legal (it is squared internally)
    if (p.base_freq < 0.0) try std.testing.expect(p.base_freq >= -1.0);
}

test "seeded generation is reproducible" {
    seed(1234);
    var p1 = Params{};
    p1.apply(.random);
    const a1 = p1.base_freq;
    const b1 = p1.freq_ramp;

    seed(1234);
    var p2 = Params{};
    p2.apply(.random);
    try std.testing.expectEqual(a1, p2.base_freq);
    try std.testing.expectEqual(b1, p2.freq_ramp);
}
