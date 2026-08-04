const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = pxl.math.Color.aya });
    api.drawRect(.init(200, 200), .init(100, 50), pxl.math.Color.aya);
    pxl.endPass();
}
