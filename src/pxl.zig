const std = @import("std");
const builtin = @import("builtin");

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
    sample_count: i32 = 0,
    swap_interval: i32 = 0,
    high_dpi: bool = false,
    fullscreen: bool = false,
    width: i32 = 1024,
    height: i32 = 768,
    window_title: [*c]const u8 = "Pxl",
    debug_render_enabled: bool = true,
    gfx: gpu.Config = .{},
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

/// Called from the root module's exported `sokol_main` on Android. Sets up
/// pxl state (io, mem, stb, cfg) and returns the sapp.Desc for sokol's event loop.
pub fn androidEntry(config: Config) sapp.Desc {
    io = std.Io.Threaded.global_single_threaded.io();
    cfg = config;
    mem.init();
    stb.init(mem.allocator);
    // Give Android a truly full-screen app: hide the system status + nav bars.
    if (builtin.target.abi.isAndroid()) androidImmersive();
    return buildSappDesc(config);
}

fn buildSappDesc(c: Config) sapp.Desc {
    // Mobile should always run fullscreen (no window chrome) and at the device's
    // native resolution so the whole screen is used.
    const use_fullscreen = if (comptime builtin.target.abi.isAndroid()) true else c.fullscreen;
    const use_high_dpi = if (comptime builtin.target.abi.isAndroid()) true else c.high_dpi;

    return .{
        .init_cb = sokolInit,
        .frame_cb = sokolFrame,
        .cleanup_cb = sokolCleanup,
        .event_cb = sokolEvent,
        .sample_count = c.sample_count,
        .swap_interval = c.swap_interval,
        .high_dpi = use_high_dpi,
        .fullscreen = use_fullscreen,
        .window_title = c.window_title,
        .width = c.width,
        .height = c.height,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = sokol.log.func },
    };
}

/// Logs a formatted message. On Android this writes to logcat (visible with
/// `adb logcat -s pxl:V`); everywhere else it behaves like `std.debug.print`.
pub fn log(comptime fmt: []const u8, args: anytype) void {
    if (comptime !builtin.target.abi.isAndroid()) {
        std.debug.print(fmt, args);
        std.debug.print("\n", .{});
        return;
    }
    androidLogWrite(fmt ++ "\n", args);
}

extern "log" fn __android_log_write(prio: c_int, tag: [*:0]const u8, text: [*:0]const u8) c_int;

fn androidLogWrite(comptime fmt: []const u8, args: anytype) void {
    var buf: [1024]u8 = undefined;
    const msg = std.fmt.bufPrintZ(&buf, fmt, args) catch return;
    _ = __android_log_write(6, "pxl", msg.ptr); // ANDROID_LOG_ERROR
}

// ---------------------------------------------------------------------------
// Android immersive fullscreen (hide status + navigation bars) via JNI.
// Only analyzed/used on Android targets.
// ---------------------------------------------------------------------------
const jobject = ?*anyopaque;
const jclass = ?*anyopaque;
const jmethodID = ?*anyopaque;

const JValue = extern union {
    z: bool,
    b: i8,
    c: u16,
    s: i16,
    i: i32,
    j: i64,
    f: f32,
    d: f64,
    l: jobject,
};

/// JNINativeInterface (from jni.h). The real table begins with 4 reserved
/// pointer slots before GetVersion, so field offsets line up with the framework.
/// Only the entries we use are typed; the rest are pointer-sized placeholders.
const JNINativeInterface = extern struct {
    reserved0: *const anyopaque,
    reserved1: *const anyopaque,
    reserved2: *const anyopaque,
    reserved3: *const anyopaque,
    getVersion: *const anyopaque,
    defineClass: *const anyopaque,
    findClass: *const anyopaque,
    fromReflectedMethod: *const anyopaque,
    fromReflectedField: *const anyopaque,
    toReflectedMethod: *const anyopaque,
    getSuperclass: *const anyopaque,
    isAssignableFrom: *const anyopaque,
    toReflectedField: *const anyopaque,
    throw_1: *const anyopaque,
    throwNew: *const anyopaque,
    exceptionOccurred: *const anyopaque,
    exceptionDescribe: *const anyopaque,
    exceptionClear: *const anyopaque,
    fatalError: *const anyopaque,
    pushLocalFrame: *const anyopaque,
    popLocalFrame: *const anyopaque,
    newGlobalRef: *const anyopaque,
    deleteGlobalRef: *const anyopaque,
    deleteLocalRef: *const anyopaque, // 23
    isSameObject: *const anyopaque,
    newLocalRef: *const anyopaque,
    ensureLocalCapacity: *const anyopaque,
    allocObject: *const anyopaque, // 27
    newObject: *const anyopaque,
    newObjectV: *const anyopaque,
    newObjectA: *const anyopaque,
    getObjectClass: *const fn (env: *JNIEnv, obj: jobject) callconv(.c) jclass, // 31
    isInstanceOf: *const anyopaque,
    getMethodID: *const fn (env: *JNIEnv, clazz: jclass, name: [*:0]const u8, sig: [*:0]const u8) callconv(.c) jmethodID, // 33
    callObjectMethod: *const fn (env: *JNIEnv, obj: jobject, method: jmethodID) callconv(.c) jobject, // 34
    callObjectMethodV: *const anyopaque,
    callObjectMethodA: *const anyopaque,
    callBooleanMethod: *const anyopaque,
    callBooleanMethodV: *const anyopaque,
    callBooleanMethodA: *const anyopaque,
    callByteMethod: *const anyopaque,
    callByteMethodV: *const anyopaque,
    callByteMethodA: *const anyopaque,
    callCharMethod: *const anyopaque,
    callCharMethodV: *const anyopaque,
    callCharMethodA: *const anyopaque,
    callShortMethod: *const anyopaque,
    callShortMethodV: *const anyopaque,
    callShortMethodA: *const anyopaque,
    callIntMethod: *const anyopaque, // 49
    callIntMethodV: *const anyopaque,
    callIntMethodA: *const anyopaque, // 51
    callLongMethod: *const anyopaque,
    callLongMethodV: *const anyopaque,
    callLongMethodA: *const anyopaque,
    callFloatMethod: *const anyopaque,
    callFloatMethodV: *const anyopaque,
    callFloatMethodA: *const anyopaque,
    callDoubleMethod: *const anyopaque,
    callDoubleMethodV: *const anyopaque,
    callDoubleMethodA: *const anyopaque,
    callVoidMethod: *const anyopaque, // 61
    callVoidMethodV: *const anyopaque,
    callVoidMethodA: *const fn (env: *JNIEnv, obj: jobject, method: jmethodID, args: [*]const JValue) callconv(.c) void, // 63
};

const JNIEnv = extern struct {
    functions: *const JNINativeInterface,
};

/// Minimal ANativeActivity (native_activity.h) — only needs env + clazz here.
const AndroidActivity = extern struct {
    callbacks: *const anyopaque,
    vm: ?*anyopaque,
    env: ?*anyopaque,
    clazz: jobject,
    internal_data_path: [*:0]const u8,
    external_data_path: [*:0]const u8,
    sdk_version: i32,
    instance: ?*anyopaque,
    asset_manager: ?*anyopaque,
    obb_path: [*:0]const u8,
};

/// Hides the Android system status and navigation bars (immersive-sticky) so the
/// render surface uses the entire display. Must run on the JNI thread (androidEntry
/// runs inside ANativeActivity_onCreate, which is attached).
fn androidImmersive() void {
    const activity_ptr = sapp.androidGetNativeActivity() orelse return;
    const activity: *const AndroidActivity = @ptrCast(@alignCast(activity_ptr));
    // activity.env is the thread's JNIEnv*; dereference once to reach the
    // JNINativeInterface function table (C JNI model).
    const env: *JNIEnv = @ptrCast(@alignCast(activity.env orelse return));
    const fn_table = env.functions;

    const act_cls = fn_table.getObjectClass(env, activity.clazz) orelse return;
    const get_window = fn_table.getMethodID(env, act_cls, "getWindow", "()Landroid/view/Window;") orelse return;
    const window = fn_table.callObjectMethod(env, activity.clazz, get_window) orelse return;

    const win_cls = fn_table.getObjectClass(env, window) orelse return;
    const get_decor = fn_table.getMethodID(env, win_cls, "getDecorView", "()Landroid/view/View;") orelse return;
    const decor = fn_table.callObjectMethod(env, window, get_decor) orelse return;

    const view_cls = fn_table.getObjectClass(env, decor) orelse return;
    const set_ui = fn_table.getMethodID(env, view_cls, "setSystemUiVisibility", "(I)V") orelse return;

    // SYSTEM_UI_FLAG_IMMERSIVE_STICKY | HIDE_NAVIGATION | FULLSCREEN | LAYOUT_STABLE | LAYOUT_HIDE_NAVIGATION
    const flags: i32 = 0x00001000 | 0x00000002 | 0x00000004 | 0x00000100 | 0x00000800;
    const args = [_]JValue{.{ .i = flags }};
    fn_table.callVoidMethodA(env, decor, set_ui, &args);
}

pub fn run(init: std.process.Init, config: Config) !void {
    io = init.io;
    cfg = config;

    // setup
    mem.init();
    stb.init(mem.allocator);

    if (comptime builtin.target.abi.isAndroid()) {
        // sapp.run() is a no-op stub on Android; sokol_main already provided the
        // desc and sokol handles the event loop. Returning here prevents the
        // spurious shutdown/teardown that would fire immediately after the no-op.
        return;
    }

    sapp.run(buildSappDesc(config));

    if (config.shutdown) |cb| try cb();

    // teardown
    mem.deinit();
    stb.deinit();
}

export fn sokolInit() void {
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
