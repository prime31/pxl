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

    const t = pxl.util.cast(f32, pxl.time.frame_count) / 60.0;

    // ---- top strip: primitive showcase ----
    batcher.drawTriangle(.init(80, 60), .init(240, 60), .init(160, 180), pxl.math.Color.white);
    batcher.drawRect(.init(380, 110), .init(120, 70), pxl.math.Color.red);
    batcher.drawRectOutline(.init(380, 110), .init(120, 70), 4, pxl.math.Color.white);
    batcher.drawCircle(.init(560, 110), 45, pxl.math.Color.gold, 48);
    batcher.drawCircleOutline(.init(560, 110), 45, 4, pxl.math.Color.white, 48);
    batcher.drawLine(.init(660, 60), .init(940, 170), 6, pxl.math.Color.sky_blue);
    batcher.drawPoint(.init(620, 110), pxl.math.Color.lime, 8);
    // atlas path: draw only the left half of the texture as a sub-region
    batcher.drawSprite(.{ .texture = ferris, .position = .init(970, 110), .source = .{
        .x = 0,
        .y = 0,
        .w = pxl.util.cast(f32, ferris.width) / 2.0,
        .h = pxl.util.cast(f32, ferris.height),
    } });

    // ---- 3x3 sprite alignment / pivot showcase (comfy draw_sprite_pro) ----
    // Each sprite is anchored at the same grid point via a different origin, and spins
    // and pulses about that anchor. The red guide rect + dot mark the anchor.
    const anchors = [9]pxl.gpu.Anchor{
        .top_left,    .top_center,    .top_right,
        .center_left, .center,        .center_right,
        .bottom_left, .bottom_center, .bottom_right,
    };
    const pulse = 2.0 + @abs(@sin(t)) * 1.0;
    const sw = pxl.util.cast(f32, ferris.width) * pulse;
    const sh = pxl.util.cast(f32, ferris.height) * pulse;
    const grid_origin = pxl.math.Vec2.init(360, 320);
    const gstep: f32 = 150;
    for (anchors, 0..) |anchor, i| {
        const col: f32 = @floatFromInt(i % 3);
        const row: f32 = @floatFromInt(i / 3);
        const pos = pxl.math.Vec2.init(grid_origin.x + col * gstep, grid_origin.y + row * gstep);
        batcher.drawRectOutline(pos, .init(sw, sh), 2, pxl.math.Color.red);
        batcher.drawSprite(.{ .texture = ferris, .position = pos, .anchor = anchor, .rotation = t, .scale = .init(pulse, pulse) });
        batcher.drawPoint(pos, pxl.math.Color.red, 6);
    }

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
