const std = @import("std");
const pxl = @import("pxl");
const app = @import("app");

extern "c" fn emscripten_console_log(s: [*:0]const u8) void;

/// The std default debug Io (`std.Io.Threaded`) doesn't compile for
/// wasm32-emscripten in Zig 0.16, so install a trap-only panic handler and a
/// console logFn that avoid it.
pub const panic = std.debug.no_panic;

fn wasmLogFn(
    comptime level: std.log.Level,
    comptime scope: @EnumLiteral(),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = level;
    _ = scope;
    var buf: [1024]u8 = undefined;
    const msg = std.fmt.bufPrintZ(&buf, format, args) catch return;
    emscripten_console_log(msg.ptr);
}

pub const std_options: std.Options = .{ .logFn = wasmLogFn };

// `std.debug.print` goes through `std.Options.debug_io`, which defaults to the
// broken `std.Io.Threaded`. Provide a minimal Io whose stderr writer drains
// straight to the JS console. Only the stderr-related VTable entries are
// implemented; every other entry is left undefined (they are never reached:
// `panic` above is `no_panic`, so no stack traces or crash handler run).

fn consoleWrite(bytes: []const u8) void {
    var buf: [1024:0]u8 = undefined;
    const len = @min(bytes.len, buf.len - 1);
    @memcpy(buf[0..len], bytes[0..len]);
    buf[len] = 0;
    emscripten_console_log(&buf);
}

fn wasmStderrDrain(w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
    if (w.end != 0) {
        consoleWrite(w.buffer[0..w.end]);
        w.end = 0;
    }
    var consumed: usize = 0;
    for (data, 0..) |slice, i| {
        if (slice.len == 0) continue;
        const repeats = if (i == data.len - 1) splat else 1;
        var r: usize = 0;
        while (r < repeats) : (r += 1) {
            consoleWrite(slice);
            consumed += slice.len;
        }
    }
    return consumed;
}

const wasmWriterVTable = std.Io.Writer.VTable{
    // flush/rebase fall back to their defaults, which drive `drain` above.
    .drain = wasmStderrDrain,
};

var wasmFileWriter: std.Io.File.Writer = .{
    .io = undefined,
    .file = undefined,
    .interface = .{ .vtable = &wasmWriterVTable, .buffer = &.{} },
};

var wasmCancelProtection: std.Io.CancelProtection = .unblocked;

fn wasmSwapCancelProtection(_: ?*anyopaque, new: std.Io.CancelProtection) std.Io.CancelProtection {
    const prev = wasmCancelProtection;
    wasmCancelProtection = new;
    return prev;
}

fn wasmLockStderr(_: ?*anyopaque, _: ?std.Io.Terminal.Mode) std.Io.Cancelable!std.Io.LockedStderr {
    return .{ .file_writer = &wasmFileWriter, .terminal_mode = .no_color };
}

fn wasmUnlockStderr(_: ?*anyopaque) void {
    wasmFileWriter.interface.flush() catch {};
    wasmFileWriter.interface.buffer = &.{};
    wasmFileWriter.interface.end = 0;
}

fn makeWasmIoVTable() std.Io.VTable {
    var vt: std.Io.VTable = undefined;
    vt.swapCancelProtection = wasmSwapCancelProtection;
    vt.lockStderr = wasmLockStderr;
    vt.unlockStderr = wasmUnlockStderr;
    return vt;
}

const wasmIoVTable: std.Io.VTable = makeWasmIoVTable();

const wasmDebugIo: std.Io = .{ .userdata = null, .vtable = &wasmIoVTable };

pub const std_options_debug_io: std.Io = wasmDebugIo;

// sokol_app.h is compiled with SOKOL_NO_ENTRY (see sokol_defines.h), so it
// does not provide main(). On wasm this is the Emscripten entry point:
// pxl.run() calls sapp.run(), which starts the requestAnimationFrame loop.
pub fn main() void {
    const cfg: pxl.Config = if (@hasDecl(app, "config")) app.config() else .{};

    // wasm has no filesystem, so pxl.io is never dereferenced by the web build.
    _ = pxl.run(undefined, cfg, .{
        .setup = if (@hasDecl(app, "setup")) app.setup else null,
        .update = if (@hasDecl(app, "update")) app.update else null,
        .render = if (@hasDecl(app, "render")) app.render else null,
        .shutdown = if (@hasDecl(app, "shutdown")) app.shutdown else null,
    });
}
