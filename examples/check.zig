const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .render = render,
    });
}

fn render() !void {
    pxl.beginPass(.{ .action = .clear });
    api.drawRect(.init(200, 200), .init(100, 50), pxl.math.Color.aya);
    pxl.endPass();
}
