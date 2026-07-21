const std = @import("std");

pub const has_imgui = @import("build_options").imgui;
pub const has_imgui_docking = @import("build_options").docking;
pub const ig = if (@import("build_options").imgui) @import("cimgui") else struct {};

pub const sokol = @import("sokol");
pub const slog = sokol.log;
pub const sg = sokol.gfx;
pub const sgl = sokol.gl;
pub const sshape = sokol.shape;
pub const sapp = sokol.app;
pub const sglue = sokol.glue;
pub const simgui = sokol.imgui;
pub const sdtx = sokol.sdtx;

pub const gamepad = @import("gamepad");
pub const stb = @import("stb");
pub const sgp = @import("painter");
pub const shaders = @import("shaders");
pub var input: Input = undefined;
pub var time: Time = undefined;

// top level imports
pub const fs = @import("fs.zig");
pub const math = @import("math/math.zig");
pub const mem = @import("mem.zig");
pub const util = @import("util/util.zig");
pub const gpu = @import("gpu/gpu.zig");

pub var io: std.Io = undefined;

const Input = @import("input.zig").Input;
const Time = @import("time.zig").Time;

pub const Config = struct {
    setup: ?*const fn () anyerror!void = null,
    update: ?*const fn () anyerror!void = null,
    render: ?*const fn () anyerror!void = null,
    shutdown: ?*const fn () anyerror!void = null,
    sample_count: i32 = 0,
    swap_interval: i32 = 0,
    high_dpi: bool = false,
    fullscreen: bool = false,
    width: i32 = 1024,
    height: i32 = 768,
    window_title: [*c]const u8 = "Zig Render",
    clear_color: sg.Color = .{ .r = 0.8, .g = 0.2, .b = 0.3, .a = 1.0 },
};

pub const Pass = struct {
    action: enum { load, clear } = .load,
};

const cbs = struct {
    pub var init: ?*const fn () anyerror!void = null;
    pub var update: ?*const fn () anyerror!void = null;
    pub var render: ?*const fn () anyerror!void = null;
    pub var shutdown: ?*const fn () anyerror!void = null;
};

var clear_color: sg.Color = undefined;
var current_pass: ?Pass = null;

pub fn run(init: std.process.Init, comptime config: Config) !void {
    io = init.io;
    cbs.init = config.setup;
    cbs.update = config.update;
    cbs.render = config.render;
    cbs.shutdown = config.shutdown;
    clear_color = config.clear_color;

    // setup
    mem.init();
    stb.init(mem.allocator);

    sapp.run(.{
        .init_cb = sokolInit,
        .frame_cb = sokolFrame,
        .cleanup_cb = sokolCleanup,
        .event_cb = sokolEvent,
        .sample_count = config.sample_count,
        .swap_interval = config.swap_interval,
        .high_dpi = config.high_dpi,
        .fullscreen = config.fullscreen,
        .window_title = config.window_title,
        .width = config.width,
        .height = config.height,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = slog.func },
    });

    if (config.shutdown) |cb| try cb();

    // teardown
    mem.deinit();
    stb.deinit();
}

export fn sokolInit() void {
    // initialize sokol-gfx
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });
    if (!sg.isvalid()) @panic("failed to create sokol context");

    // initialize sokol-gl
    sgl.setup(.{
        // .color_format = gpu.offscreen_pixel_format,
        .depth_format = .NONE, // keep in sync with gpu.createOffscreenAttachments
        // .sample_count = gpu.offscreen_sample_count,
        .logger = .{ .func = slog.func },
    });

    sdtx.setup(.{
        .fonts = init: {
            var f: [8]sdtx.FontDesc = @splat(.{});
            f[0] = sdtx.fontKc854();
            break :init f;
        },
        .logger = .{ .func = slog.func },
    });

    sgp.setup(&.{
        .max_vertices = 10000000,
        // .color_format = gpu.offscreen_pixel_format,
        .depth_format = .NONE, // keep in sync with gpu.createOffscreenAttachments
    });
    if (!sgp.is_valid()) @panic(sgp.get_error_message(sgp.get_last_error()));

    // optionally, initialize sokol-imgui
    if (has_imgui) {
        simgui.setup(.{
            .logger = .{ .func = slog.func },
        });

        if (has_imgui_docking)
            ig.igGetIO().*.ConfigFlags |= ig.ImGuiConfigFlags_DockingEnable;
    }

    gpu.init();
    input = Input.init(1);
    time = Time.init();

    if (cbs.init) |cb| cb() catch {};
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

    if (cbs.update) |cb| cb() catch {};
    if (cbs.render) |cb| cb() catch {};

    gpu.offscreen.pass.action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.75, .g = 0.25, .b = 0.25, .a = 1.0 },
    };

    gpu.blitRenderTexture();

    if (has_imgui) {
        var pass_action: sg.PassAction = .{};
        pass_action.colors[0] = .{ .load_action = .LOAD };

        sg.beginPass(.{ .action = pass_action, .swapchain = sglue.swapchain() });
        simgui.render();
        sg.endPass();
    }

    // sokol debug text, it flickers for some reason...
    // var pass_action: sg.PassAction = .{};
    // pass_action.colors[0] = .{ .load_action = .LOAD };
    // sg.beginPass(.{ .action = pass_action, .swapchain = sglue.swapchain() });
    // sdtx.draw();
    // sg.endPass();

    sg.commit();
    input.newFrame();
    time.update();
}

export fn sokolEvent(evt: [*c]const sapp.Event) void {
    if (has_imgui) if (simgui.handleEvent(evt.*)) return;

    if (evt.*.type == .RESIZED) gpu.createOffscreenAttachments(evt.*.framebuffer_width, evt.*.framebuffer_height);
    input.handleEvent(evt);
}

export fn sokolCleanup() void {
    if (cbs.shutdown) |cb| cb() catch {};

    gpu.deinit();

    sgp.shutdown();
    sgl.shutdown();
    if (has_imgui) simgui.shutdown();
    sg.shutdown();
}

pub fn beginPass(pass: Pass) void {
    std.debug.assert(current_pass == null);
    current_pass = pass;

    sgp.begin(sapp.width(), sapp.height());
    sgp.viewport(0, 0, sapp.width(), sapp.height());
    const ratio = @as(f32, @floatFromInt(sapp.width())) / @as(f32, @floatFromInt(sapp.height()));
    sgp.project(-ratio, ratio, -1.0, 1.0);
}

pub fn endPass() void {
    std.debug.assert(current_pass != null);

    gpu.offscreen.pass.action.colors[0].load_action = if (current_pass.?.action == .load) .LOAD else .CLEAR;
    sg.beginPass(gpu.offscreen.pass);
    sgl.draw();
    sgp.flush();
    sgp.end();
    sg.endPass();

    current_pass = null;
}

test {
    std.testing.refAllDecls(@This());
    // std.testing.refAllDecls(math);
}
