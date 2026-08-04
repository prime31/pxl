const std = @import("std");

pub const android = @import("android.zig");

pub const has_imgui = @import("build_options").imgui;
pub const has_imgui_docking = @import("build_options").docking;
pub const ig = if (@import("build_options").imgui) @import("cimgui") else struct {};

pub const sokol = @import("sokol");
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
pub const fs = @import("fs.zig");
pub const math = @import("math/math.zig");
pub const mem = @import("mem.zig");
pub const util = @import("util/util.zig");
pub const gpu = @import("gpu/gpu.zig");
pub const text = @import("text/text.zig");
pub const tilemap = @import("tilemap/tilemap.zig");

pub var io: std.Io = undefined;

pub const Config = struct {
    setup: ?*const fn () anyerror!void = null,
    update: ?*const fn () anyerror!void = null,
    render: ?*const fn () anyerror!void = null,
    shutdown: ?*const fn () anyerror!void = null,
    win: WindowConfig = .{},
    gfx: gpu.Config = .{},
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

pub fn run(init: std.process.Init, config: Config) !void {
    io = init.io;
    cfg = config;

    sapp.run(buildSappDesc(config));
}

pub fn runAndroid(config: Config) sapp.Desc {
    io = std.Io.Threaded.global_single_threaded.io();
    cfg = config;

    android.hideSystemBars(sapp.androidGetNativeActivity());

    return buildSappDesc(config);
}

fn buildSappDesc(c: Config) sapp.Desc {
    return .{
        .init_cb = sokolInit,
        .frame_cb = sokolFrame,
        .cleanup_cb = sokolCleanup,
        .event_cb = sokolEvent,
        .sample_count = c.win.sample_count,
        .swap_interval = c.win.swap_interval,
        .high_dpi = if (android.is_android) true else c.win.high_dpi,
        .fullscreen = if (android.is_android) true else c.win.fullscreen,
        .window_title = c.win.window_title,
        .srgb = false,
        .hdr = false,
        .disable_vsync = false,
        .enable_clipboard = false,
        .enable_dragndrop = false,
        .width = c.win.width,
        .height = c.win.height,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    };
}

/// Logs a formatted message. On Android this writes to logcat (visible with `adb logcat -s pxl:V`
pub fn log(comptime fmt: []const u8, args: anytype) void {
    if (!android.is_android) {
        std.debug.print(fmt ++ "\n", args);
        return;
    }
    android.log(fmt, args);
}

export fn sokolInit() void {
    mem.init();
    stb.init(mem.allocator);

    sg.setup(.{
        .environment = sokol.glue.environment(),
        .logger = .{ .func = sokol.log.func },
    });
    if (!sg.isvalid()) @panic("failed to create sokol context");

    mu.setup();

    // optionally, initialize sokol-imgui
    if (has_imgui) {
        simgui.setup(.{
            .logger = .{ .func = sokol.log.func },
        });

        if (has_imgui_docking)
            ig.igGetIO().*.ConfigFlags |= ig.ImGuiConfigFlags_DockingEnable;
    }

    batcher = gpu.Batcher.init(cfg.gfx.batcher) catch unreachable;
    font = text.BMFont.init("examples/assets/minecraftia.fnt") catch unreachable;
    gpu.init(cfg.gfx);
    time.init();

    if (cfg.setup) |cb| cb() catch unreachable;
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
    if (cfg.update) |cb| cb() catch unreachable;
    if (cfg.render) |cb| cb() catch unreachable;
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
    if (cfg.shutdown) |cb| cb() catch {};

    gpu.deinit();

    batcher.deinit();
    font.deinit();
    sokol.gl.shutdown();
    dbg.deinit();
    if (has_imgui) simgui.shutdown();
    sg.shutdown();

    stb.deinit();
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
}
