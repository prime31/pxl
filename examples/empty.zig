const std = @import("std");

const pxl = @import("pxl");
const sg = pxl.sg;
const sgl = pxl.sgl;
const sgp = pxl.sgp;
const ig = pxl.ig;

const state = struct {
    var checkers: pxl.gpu.Texture = undefined;
};

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        // .update = update,
        .render = render,
        .shutdown = shutdown,
    });
}

fn setup() !void {
    state.checkers = pxl.gpu.Texture.initCheckerboard();
}

fn update() !void {
    if (ig.igBegin("Hello Dear ImGui!", null, ig.ImGuiWindowFlags_None)) {
        _ = ig.igText("Dear ImGui Version: %s", ig.IMGUI_VERSION);
    }
    ig.igEnd();
}

fn render() !void {
    pxl.beginPass(.{ .action = .clear });
    sgp.set_image(0, state.checkers.img);
    sgp.draw_filled_rect(-0.5, -0.5, 1.0, 1.0);
    if (pxl.input.keyDown(.G)) sgp.draw_filled_rect(-1, -1, 0.3, 0.3);
    pxl.endPass();

    pxl.beginPass(.{});
    sgp.set_color(1, 0, 0, 1);
    sgp.draw_filled_rect(-0.1, -0.1, 0.4, 0.4);
    pxl.endPass();

    pxl.beginPass(.{});
    sgl.beginPoints();

    const angle: f32 = @floatFromInt(pxl.sapp.frameCount() % 360);
    var psize: f32 = 5;
    for (0..300) |i| {
        const a = sgl.asRadians(angle + @as(f32, @floatFromInt(i)));
        const r = @sin(a * 4.0);
        const s = @sin(a);
        const c = @cos(a);
        const x = s * r;
        const y = c * r;

        sgl.c3f(1, 0.5, 0.3);
        sgl.c3f(r, s, c);
        sgl.pointSize(psize);
        sgl.v2f(x, y);
        psize *= 1.005;
    }
    sgl.end();
    pxl.endPass();
}

fn shutdown() !void {
    state.checkers.deinit();
}
