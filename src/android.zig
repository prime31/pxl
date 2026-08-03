//! Android platform support for pxl: logcat logging and immersive fullscreen.
//!
//! Kept out of the engine core (pxl.zig) so the main module stays
//! platform-agnostic; all the Android-specific JNI / NDK bits live here. The
//! extern symbols resolve against `libandroid` and `liblog`, which are linked
//! for Android targets (see build.zig::buildAndroid).

const std = @import("std");
const builtin = @import("builtin");

/// Comptime-known: are we compiling for Android?
pub const is_android = builtin.target.abi.isAndroid();

// ---------------------------------------------------------------------------
// Logging
// ---------------------------------------------------------------------------

/// Logs a formatted message. On Android this writes to logcat (visible with
/// `adb logcat -s pxl:V`); everywhere else it behaves like `std.debug.print`.
pub fn log(comptime fmt: []const u8, args: anytype) void {
    logcatWrite(fmt ++ "\n", args);
}

extern "log" fn __android_log_write(prio: c_int, tag: [*:0]const u8, text: [*:0]const u8) c_int;

fn logcatWrite(comptime fmt: []const u8, args: anytype) void {
    var buf: [1024]u8 = undefined;
    const msg = std.fmt.bufPrintZ(&buf, fmt, args) catch return;
    _ = __android_log_write(6, "pxl", msg.ptr); // ANDROID_LOG_ERROR
}

// ---------------------------------------------------------------------------
// Immersive fullscreen via JNI
//
// Only analyzed/linked on Android: `hideSystemBars` is referenced solely from
// the Android-only branch of `pxl.androidEntry`, so on other targets neither it
// nor the JNI externs below are pulled in.
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
/// pointer slots before GetVersion, so the field offsets line up with the
/// framework. Only the entries we use are typed; the rest are pointer-sized
/// placeholders.
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

/// Minimal ANativeActivity (native_activity.h) — only the fields we need.
const NativeActivity = extern struct {
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
/// render surface uses the entire display. Pass the ANativeActivity pointer
/// obtained from `sapp.androidGetNativeActivity()`. Must run on the JNI thread
/// (androidEntry runs inside ANativeActivity_onCreate, which is attached).
pub fn hideSystemBars(native_activity: ?*const anyopaque) void {
    const activity_ptr = native_activity orelse return;
    const activity: *const NativeActivity = @ptrCast(@alignCast(activity_ptr));
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
