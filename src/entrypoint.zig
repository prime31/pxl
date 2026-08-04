const std = @import("std");
const builtin = @import("builtin");
const pxl = @import("pxl");
const app = @import("app");

comptime {
    if (builtin.target.abi.isAndroid()) {
        @export(&sokolMain, .{ .name = "sokol_main" });
    }
}

fn sokolMain() callconv(.c) pxl.sapp.Desc {
    const cfg: pxl.Config = if (@hasDecl(app, "config")) app.config() else .{};

    return pxl.runAndroid(.{
        .setup = if (@hasDecl(app, "setup")) app.setup else null,
        .update = if (@hasDecl(app, "update")) app.update else null,
        .render = if (@hasDecl(app, "render")) app.render else null,
        .shutdown = if (@hasDecl(app, "shutdown")) app.shutdown else null,
        .win = cfg.win,
        .gfx = cfg.gfx,
    });
}

pub fn main(init: std.process.Init) !void {
    const cfg: pxl.Config = if (@hasDecl(app, "config")) app.config() else .{};

    try pxl.run(init, .{
        .setup = if (@hasDecl(app, "setup")) app.setup else null,
        .update = if (@hasDecl(app, "update")) app.update else null,
        .render = if (@hasDecl(app, "render")) app.render else null,
        .shutdown = if (@hasDecl(app, "shutdown")) app.shutdown else null,
        .win = cfg.win,
        .gfx = cfg.gfx,
    });
}
