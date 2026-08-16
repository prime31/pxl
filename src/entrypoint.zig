const std = @import("std");
const builtin = @import("builtin");
const pxl = @import("pxl");
const app = @import("app");

pub const std_options: std.Options = .{
    .log_level = .debug,
    .log_scope_levels = &[_]std.log.ScopeLevel{
        .{ .scope = .library_a, .level = .debug },
        .{ .scope = .library_b, .level = .info },
    },
    .logFn = if (builtin.target.abi.isAndroid()) androidLogFn else std.log.defaultLog,
};

pub const std_options_cwd = null;

fn androidLogFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    _ = scope;
    pxl.android.logLevel(level, format, args);
}

comptime {
    if (builtin.target.abi.isAndroid())
        @export(&sokolMain, .{ .name = "sokol_main" });
}

fn sokolMain() callconv(.c) pxl.sapp.Desc {
    const cfg: pxl.Config = if (@hasDecl(app, "config")) app.config() else .{};

    return pxl.run(std.Io.Threaded.global_single_threaded.io(), cfg, .{
        .setup = if (@hasDecl(app, "setup")) app.setup else null,
        .update = if (@hasDecl(app, "update")) app.update else null,
        .render = if (@hasDecl(app, "render")) app.render else null,
        .shutdown = if (@hasDecl(app, "shutdown")) app.shutdown else null,
    });
}

pub fn main(init: std.process.Init) !void {
    const cfg: pxl.Config = if (@hasDecl(app, "config")) app.config() else .{};

    _ = pxl.run(init.io, cfg, .{
        .setup = if (@hasDecl(app, "setup")) app.setup else null,
        .update = if (@hasDecl(app, "update")) app.update else null,
        .render = if (@hasDecl(app, "render")) app.render else null,
        .shutdown = if (@hasDecl(app, "shutdown")) app.shutdown else null,
    });
}
