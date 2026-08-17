const std = @import("std");
const builtin = @import("builtin");

const has_imgui = @import("build_options").imgui;
const has_imgui_docking = @import("build_options").docking;
pub const ig = if (@import("build_options").imgui) @import("cimgui") else struct {};

pub const sokol = @import("sokol");
pub const saudio = sokol.audio;
pub const sg = sokol.gfx;
pub const sapp = sokol.app;
pub const simgui = sokol.imgui;

pub const api = @import("api.zig");
pub const dbg = @import("util/debug.zig");
pub const input = @import("input/input.zig");
pub const mu = @import("microui");
pub const shaders = @import("shaders");
pub const stb = @import("stb");
pub const time = @import("time.zig");

/// The engine's 2D batching renderer. Drive it through `pxl.api.*`.
pub var batcher: gpu.Batcher = undefined;

// top level imports
pub const android = @import("android.zig");
pub const assets = @import("assets/assets.zig");
pub const audio = @import("audio.zig");
pub const fs = @import("fs.zig");
pub const math = @import("math/math.zig");
pub const mem = @import("mem.zig");
pub const sfxr = @import("sfxr.zig");
pub const util = @import("util/util.zig");
pub const gpu = @import("gpu/gpu.zig");
pub const text = @import("text/text.zig");
pub const tilemap = @import("tilemap/tilemap.zig");

pub var io: std.Io = undefined;

const Callbacks = struct {
    setup: ?*const fn () anyerror!void = null,
    update: ?*const fn () anyerror!void = null,
    render: ?*const fn () anyerror!void = null,
    shutdown: ?*const fn () anyerror!void = null,
};

pub const Config = struct {
    win: WindowConfig = .{},
    gfx: gpu.Config = .{},
    audio: audio.AudioInitOptions = .{},
    debug_render_enabled: bool = true,
};

pub const WindowConfig = struct {
    sample_count: i32 = 0,
    swap_interval: i32 = 0,
    high_dpi: bool = false,
    fullscreen: bool = false,
    width: i32 = 1024,
    height: i32 = 768,
    window_title: [*c]const u8 = "Pxl",
};

pub const Camera = gpu.Camera;
pub const Transform = gpu.Transform;
pub const Anchor = gpu.Anchor;
pub const Sprite = gpu.Sprite;
pub const ParticleSystem = gpu.ParticleSystem;
pub const Particle = gpu.Particle;
pub const EmitterParams = gpu.EmitterParams;

pub const Pass = struct {
    /// if null performs a .load else a .clear with clear_color
    clear_color: ?math.Color = null,
    camera: ?Camera = null,
};

pub var font: text.BMFont = undefined;
var current_pass: ?Pass = null;
var cfg: Config = undefined;
var cbs: Callbacks = undefined;

pub fn run(io_arg: std.Io, config: Config, callbacks: Callbacks) sapp.Desc {
    io = io_arg;
    cfg = config;
    cbs = callbacks;

    if (builtin.target.abi.isAndroid())
        android.hideSystemBars(sapp.androidGetNativeActivity());

    const desc = sapp.Desc{
        .init_cb = sokolInit,
        .frame_cb = sokolFrame,
        .cleanup_cb = sokolCleanup,
        .event_cb = sokolEvent,
        .sample_count = config.win.sample_count,
        .swap_interval = config.win.swap_interval,
        .high_dpi = if (builtin.target.abi.isAndroid()) true else config.win.high_dpi,
        .fullscreen = if (builtin.target.abi.isAndroid()) true else config.win.fullscreen,
        .window_title = config.win.window_title,
        .srgb = false,
        .hdr = false,
        .disable_vsync = false,
        .enable_clipboard = false,
        .enable_dragndrop = false,
        .width = config.win.width,
        .height = config.win.height,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
        .android = .{ .native_event_cb = @import("gamepad").getAndroidInputHandler() },
    };
    sapp.run(desc);
    return desc;
}

export fn sokolInit() void {
    mem.init();

    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });
    if (!sg.isvalid()) @panic("failed to create sokol context");

    // Low-latency push model: 1024-frame backend buffer (≈23ms) and an 8-packet
    // ring (1024 frames ≈ 23ms). A new sound starts ~46ms after play() instead of
    // ~116ms with the 32-packet default, at the cost of stalling if a frame hitch
    // exceeds ~23ms.
    saudio.setup(.{
        .sample_rate = 44100,
        .num_channels = 2,
        .buffer_frames = 1024,
        .packet_frames = 128,
        .num_packets = 8,
        .logger = .{ .func = sokol.log.func },
    });
    if (!saudio.isvalid()) @panic("failed to setup sokol audio");

    audio.init(cfg.audio);

    mu.init();

    // optionally, initialize sokol-imgui
    if (has_imgui) {
        simgui.setup(.{
            .logger = .{ .func = sokol.log.func },
        });

        if (has_imgui_docking)
            ig.igGetIO().*.ConfigFlags |= ig.ImGuiConfigFlags_DockingEnable;
    }

    batcher = gpu.Batcher.init(cfg.gfx.batcher) catch unreachable;
    font = text.BMFont.init() catch unreachable;
    gpu.init(cfg.gfx);
    time.init();
    input.init();

    if (cbs.setup) |cb| cb() catch unreachable;
}

export fn sokolFrame() void {
    if (has_imgui) {
        simgui.newFrame(.{
            .width = sapp.width(),
            .height = sapp.height(),
            .delta_time = sapp.frameDuration(),
            .dpi_scale = sapp.dpiScale(),
        });
    }

    mu.begin();
    if (cbs.update) |cb| cb() catch unreachable;
    audio.update();
    if (cbs.render) |cb| cb() catch unreachable;
    mu.end();

    gpu.blitRenderTexture(has_imgui);

    sg.commit();
    input.newFrame();
    time.update();
}

export fn sokolEvent(evt: [*c]const sapp.Event) void {
    if (evt.*.type == .KEY_DOWN and evt.*.key_code == .Q and evt.*.modifiers > 0 and evt.*.modifiers % sapp.modifier_super == 0) {
        sapp.requestQuit();
        return;
    }

    if (has_imgui) if (simgui.handleEvent(evt.*)) return;

    if (mu.handleEvent(evt)) return;

    if (evt.*.type == .RESIZED) gpu.createOffscreenAttachments();
    input.handleEvent(evt);
}

export fn sokolCleanup() void {
    if (cbs.shutdown) |cb| cb() catch {};

    assets.deinit();
    audio.deinit();

    input.deinit();
    gpu.deinit();

    batcher.deinit();
    font.deinit();

    dbg.deinit();
    if (has_imgui) simgui.shutdown();
    sg.shutdown();
    saudio.shutdown();

    mem.deinit();
}

pub fn beginPass(pass: Pass) void {
    std.debug.assert(current_pass == null);
    current_pass = pass;

    gpu.offscreen.pass.action.colors[0].load_action = if (pass.clear_color == null) .LOAD else .CLEAR;
    if (pass.clear_color) |col| gpu.offscreen.pass.action.colors[0].clear_value = col.asSokol();
    sg.beginPass(gpu.offscreen.pass);

    const target_w = gpu.renderWidthf();
    const target_h = gpu.renderHeightf();
    const mat = if (pass.camera) |cam|
        cam.getMatrix(target_w, target_h)
    else
        math.Mat32.orthographic(target_w, target_h);

    batcher.begin(mat);
}

pub fn endPass() void {
    std.debug.assert(current_pass != null);

    dbg.render(cfg.debug_render_enabled);
    batcher.end();
    sg.endPass();

    current_pass = null;
}

test {
    std.testing.refAllDecls(@This());
    _ = @import("util/util.zig");
    _ = @import("util/slotmap.zig");
}
