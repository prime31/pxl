const std = @import("std");
const pxl = @import("pxl");
const sg = pxl.sg;

var batcher: pxl.gpu.Batcher = undefined;

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        .render = render,
        .shutdown = shutdown,
    });
}

fn setup() !void {
    batcher = try pxl.gpu.Batcher.init(4096, 8192);
}

fn render() !void {
    batcher.begin(pxl.math.Mat32.orthographic(pxl.sapp.widthf(), pxl.sapp.heightf()));
    batcher.drawTriangle(
        .init(100, 100),
        .init(300, 100),
        .init(200, 300),
        pxl.math.Color.white,
    );

    // flush inside the offscreen pass (the same render target pxl blits to the swapchain)
    pxl.gpu.offscreen.pass.action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1 },
    };
    sg.beginPass(pxl.gpu.offscreen.pass);
    batcher.end();
    sg.endPass();
}

fn shutdown() !void {
    batcher.deinit();
}
