const std = @import("std");
const pxl = @import("pxl");
const sg = pxl.sg;

var batcher: pxl.gpu.Batcher = undefined;
var custom_pip: ?sg.Pipeline = null;

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        .render = render,
        .shutdown = shutdown,
    });
}

fn setup() !void {
    batcher = try pxl.gpu.Batcher.init(4096, 8192, 64);
}

fn render() !void {
    // All batcher drawing must happen inside an active pass: a draw-state change
    // (setPipeline/setTexture/setBlendMode) can trigger a flush mid-frame, and flush
    // issues sokol-gfx draw commands.
    pxl.gpu.offscreen.pass.action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1 },
    };
    sg.beginPass(pxl.gpu.offscreen.pass);

    batcher.begin(pxl.math.Mat32.orthographic(pxl.sapp.widthf(), pxl.sapp.heightf()));
    batcher.setBlendMode(.blend);
    batcher.drawTriangle(
        .init(100, 100),
        .init(300, 100),
        .init(200, 300),
        pxl.math.Color.white,
    );

    // exercise the custom-pipeline + uniform API (pipeline is created once, on first press)
    if (pxl.input.keyDown(.P)) {
        const pip = custom_pip orelse blk: {
            custom_pip = pxl.gpu.Batcher.makePipeline(batcher.shader, .add);
            break :blk custom_pip.?;
        };
        batcher.setPipeline(pip);
        batcher.setUniform(null, 0, null, 0);
        batcher.drawTriangle(.init(320, 100), .init(520, 100), .init(420, 300), pxl.math.Color.red);
        batcher.resetPipeline();
    }

    batcher.end();
    sg.endPass();
}

fn shutdown() !void {
    batcher.deinit();
}
