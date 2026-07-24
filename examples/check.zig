const std = @import("std");
const pxl = @import("pxl");

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .render = render,
    });
}

fn render() !void {
    pxl.beginPass(.{ .action = .clear });
    pxl.batcher.drawRect(.init(200, 200), .init(100, 50), pxl.math.Color.aya);
    pxl.endPass();
}
