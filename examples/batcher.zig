const std = @import("std");
const pxl = @import("pxl");
const sg = pxl.sg;

var batcher: pxl.gpu.Batcher = undefined;
var custom_pip: ?sg.Pipeline = null;
var ferris: pxl.gpu.Texture = undefined;

// gp_example (ferris SDF) shader, driven through the batcher to test the uniform path
var shader_pip: ?sg.Pipeline = null;
var vs_uniform: pxl.shaders.GpExampleVsUniforms = undefined;
var fs_uniform: pxl.shaders.GpExampleFsUniforms = undefined;

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        .render = render,
        .shutdown = shutdown,
    });
}

fn setup() !void {
    batcher = try pxl.gpu.Batcher.init(4096, 8192, 64);
    ferris = try pxl.gpu.Texture.initFromFile("examples/assets/ferris_smol.png");
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

    // high-level convenience drawing
    batcher.drawRect(.init(150, 450), .init(120, 80), pxl.math.Color.red);
    batcher.drawRectOutline(.init(150, 450), .init(120, 80), 3, pxl.math.Color.white);
    batcher.drawLine(.init(400, 420), .init(650, 500), 6, pxl.math.Color.sky_blue);
    batcher.drawPoint(.init(300, 200), pxl.math.Color.lime, 8);
    batcher.drawCircle(.init(500, 200), 60, pxl.math.Color.gold, 32);
    batcher.drawCircleOutline(.init(500, 200), 70, 3, pxl.math.Color.white, 48);

    const rot = pxl.util.cast(f32, pxl.time.frame_count) / 60.0;
    // whole texture, spinning about its center, 2x
    batcher.drawSprite(.{ .texture = ferris, .position = .init(700, 300), .rotation = rot, .scale = .init(2, 2) });
    // atlas path: draw only the left half of the texture as a sub-region
    batcher.drawSprite(.{ .texture = ferris, .position = .init(700, 480), .source = .{
        .x = 0,
        .y = 0,
        .w = pxl.util.cast(f32, ferris.width) / 2.0,
        .h = pxl.util.cast(f32, ferris.height),
    } });

    // exercise the custom-pipeline + uniform API (pipeline is created once, on first press)
    if (pxl.input.keyDown(.P)) {
        const pip = custom_pip orelse blk: {
            custom_pip = pxl.gpu.Batcher.makePipeline(batcher.shader, .add);
            break :blk custom_pip.?;
        };
        batcher.setPipeline(pip);
        batcher.setUniform(null, null);
        batcher.drawTriangle(.init(320, 100), .init(520, 100), .init(420, 300), pxl.math.Color.red);
        batcher.resetPipeline();
    }

    // hold S: draw the gp_example (ferris SDF) shader fullscreen, feeding it uniforms
    if (pxl.input.keyDown(.S)) {
        const pip = shader_pip orelse blk: {
            shader_pip = pxl.gpu.Batcher.makePipeline(sg.makeShader(pxl.shaders.gpExampleShaderDesc(sg.queryBackend())), .blend);
            break :blk shader_pip.?;
        };
        batcher.setPipeline(pip);
        vs_uniform.iResolution = .init(pxl.sapp.widthf(), pxl.sapp.heightf());
        fs_uniform.iTime = pxl.util.cast(f32, pxl.time.frame_count) / 60.0;
        batcher.setUniform(&vs_uniform, &fs_uniform);

        const w = pxl.sapp.widthf();
        const h = pxl.sapp.heightf();
        batcher.drawQuad(.{
            .{ .pos = .init(0, 0), .uv = .init(0, 0), .col = .white },
            .{ .pos = .init(w, 0), .uv = .init(1, 0), .col = .white },
            .{ .pos = .init(w, h), .uv = .init(1, 1), .col = .white },
            .{ .pos = .init(0, h), .uv = .init(0, 1), .col = .white },
        });
        batcher.resetPipeline();
    }

    batcher.end();
    sg.endPass();
}

fn shutdown() !void {
    ferris.deinit();
    batcher.deinit();
}
