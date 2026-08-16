const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;
const sg = pxl.sg;

var ferris: *pxl.gpu.Texture = undefined;

// gp_example (ferris SDF) shader, driven through the batcher to test the uniform path
var shader_pip: ?sg.Pipeline = null;
var vs_uniform: pxl.shaders.GpExampleVsUniforms = undefined;
var fs_uniform: pxl.shaders.GpExampleFsUniforms = undefined;

pub fn setup() !void {
    ferris = try pxl.assets.loadTexture(.ferris_smol);
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = pxl.math.Color.aya });

    const t = pxl.util.cast(f32, pxl.time.frameCount()) / 60.0;

    // ---- top strip: primitive showcase ----
    api.drawTriangle(.init(80, 60), .init(240, 60), .init(160, 180), pxl.math.Color.white);
    api.drawRectEx(.init(380, 110), .init(120, 70), .center, pxl.math.Color.red);
    api.drawRectOutlineEx(.init(380, 110), .init(120, 70), .center, 4, pxl.math.Color.white);
    api.drawCircle(.init(560, 110), 45, 48, pxl.math.Color.gold);
    api.drawCircleOutline(.init(560, 110), 45, 4, 48, pxl.math.Color.white);
    api.drawLine(.init(660, 60), .init(940, 170), 6, pxl.math.Color.sky_blue);
    api.drawPoint(.init(620, 110), 8, pxl.math.Color.lime);
    // atlas path: draw only the left half of the texture as a sub-region
    api.drawSprite(
        .{
            .texture = ferris.*,
            .source = .{
                .x = 0,
                .y = 0,
                .w = pxl.util.cast(f32, ferris.width) / 2.0,
                .h = pxl.util.cast(f32, ferris.height),
            },
        },
        .{ .pos = .init(970, 110), .origin = .center },
    );

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
        api.drawRectOutlineEx(pos, .init(sw, sh), anchor, 2, pxl.math.Color.red);
        api.drawSprite(
            .{ .texture = ferris.* },
            .{ .pos = pos, .origin = anchor, .rotation = t, .scale = .init(pulse, pulse) },
        );
        api.drawPoint(pos, 6, pxl.math.Color.red);
    }

    // exercise the custom-pipeline + uniform API (pipeline is created once, on first press)
    if (pxl.input.keyDown(.p)) {
        api.setBlendMode(.add);
        api.setUniform(null, null);
        api.drawTriangle(.init(320, 100), .init(520, 100), .init(420, 300), pxl.math.Color.red);
        api.resetPipeline();
    }

    // hold S: draw the gp_example (ferris SDF) shader fullscreen, feeding it uniforms
    if (pxl.input.keyDown(.s)) {
        const pip = shader_pip orelse blk: {
            shader_pip = api.makePipeline(sg.makeShader(pxl.shaders.gpExampleShaderDesc(sg.queryBackend())), .blend);
            break :blk shader_pip.?;
        };
        api.setPipeline(pip);
        vs_uniform.iResolution = .init(pxl.sapp.widthf(), pxl.sapp.heightf());
        fs_uniform.iTime = pxl.util.cast(f32, pxl.time.frameCount()) / 60.0;
        api.setUniform(&vs_uniform, &fs_uniform);

        const w = pxl.sapp.widthf();
        const h = pxl.sapp.heightf();
        api.drawQuad(.{
            .{ .pos = .init(0, 0), .uv = .init(0, 0), .col = .white },
            .{ .pos = .init(w, 0), .uv = .init(1, 0), .col = .white },
            .{ .pos = .init(w, h), .uv = .init(1, 1), .col = .white },
            .{ .pos = .init(0, h), .uv = .init(0, 1), .col = .white },
        }, null, null);
        api.resetPipeline();
    }

    pxl.endPass();
}

pub fn shutdown() !void {
    pxl.assets.destroy(ferris);
}
