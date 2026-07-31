const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;
const mu = pxl.mu;
const sg = pxl.sg;

const Color = pxl.math.Color;

var sdf_pip: sg.Pipeline = undefined;
var noise_pip: sg.Pipeline = undefined;
var noise_tex: pxl.gpu.Texture = undefined;
var sdf_vs_uni: pxl.shaders.GpExampleVsUniforms = undefined;
var sdf_fs_uni: pxl.shaders.GpExampleFsUniforms = undefined;
var noise_fs_uni: pxl.shaders.FogNoiseFsUniforms = .{
    .iVelocity = .init(0.02, 0.01),
    .iPressure = 0.3,
    .iWarpiness = 0.2,
    .iZoom = 0.4,
    .iRatio = 0.0,
    .iTime = 0.0,
};

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        .shutdown = shutdown,
        .update = update,
        .render = render,
    });
}

fn setup() !void {
    sdf_pip = api.makePipeline(sg.makeShader(pxl.shaders.gpExampleShaderDesc(sg.queryBackend())), .blend);
    noise_pip = api.makePipeline(sg.makeShader(pxl.shaders.fogNoiseShaderDesc(sg.queryBackend())), .blend);
    noise_tex = try pxl.gpu.Texture.initFromFile("examples/assets/perlin.png");
}

fn shutdown() !void {
    sg.destroyPipeline(sdf_pip);
    sg.destroyPipeline(noise_pip);
    noise_tex.deinit();
}

fn update() !void {
    if (mu.beginWindowEx("Particle Controls", .{ .x = 10, .y = 10, .w = 260, .h = 280 }, .{ .align_center = false })) {
        mu.layoutRow(2, &[_]c_int{ 100, -1 }, 0);

        mu.label("Velocity.x:");
        _ = mu.slider(&noise_fs_uni.iVelocity.x, -0.1, 0.1, 0.001);

        mu.label("Velocity.y:");
        _ = mu.slider(&noise_fs_uni.iVelocity.y, -0.1, 0.1, 0.001);

        mu.label("Pressure:");
        _ = mu.slider(&noise_fs_uni.iPressure, 0, 1, 0.001);

        mu.label("Warpiness:");
        _ = mu.slider(&noise_fs_uni.iWarpiness, 0, 1, 0.001);

        mu.label("Zoom:");
        _ = mu.slider(&noise_fs_uni.iZoom, 0, 1, 0.001);

        mu.endWindow();
    }
}

fn render() !void {
    pxl.beginPass(.{ .clear_color = Color.aya });

    {
        api.setPipeline(sdf_pip);

        sdf_vs_uni.iResolution.x = pxl.sapp.widthf();
        sdf_vs_uni.iResolution.y = pxl.sapp.heightf();
        sdf_fs_uni.iTime = pxl.util.cast(f32, pxl.time.frameCount()) / 60.0;
        api.setUniform(&sdf_vs_uni, &sdf_fs_uni);

        api.drawRect(.init(0, 0), .init(pxl.sapp.widthf(), pxl.sapp.heightf()), Color.white);
    }

    {
        api.setPipeline(noise_pip);

        const image_ratio = pxl.util.cast(f32, noise_tex.width) / pxl.util.cast(f32, noise_tex.height);
        noise_fs_uni.iRatio = image_ratio;
        noise_fs_uni.iTime = pxl.time.time();
        api.setUniform(null, &noise_fs_uni);

        api.drawTexture(noise_tex, .{});
    }

    pxl.endPass();
}
