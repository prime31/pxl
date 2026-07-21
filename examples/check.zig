const std = @import("std");
const pxl = @import("pxl");
const sgp = pxl.sgp;

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .render = render,
    });
}

fn render() !void {
    pxl.beginPass(.{ .action = .clear });
    sgp.draw_filled_rect(-0.5, -0.5, 1.0, 1.0);
    pxl.endPass();
}

fn shutdown() !void {}
