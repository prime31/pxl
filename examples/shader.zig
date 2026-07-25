const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;
const sg = pxl.sg;
const Color = pxl.math.Color;

var pip: sg.Pipeline = undefined;
var vs_uniform: pxl.shaders.GpExampleVsUniforms = undefined;
var fs_uniform: pxl.shaders.GpExampleFsUniforms = undefined;

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        .render = render,
    });
}

fn setup() !void {
    pip = api.makePipeline(sg.makeShader(pxl.shaders.gpExampleShaderDesc(sg.queryBackend())), .blend);
}

fn render() !void {
    pxl.beginPass(.{ .action = .clear });

    api.setPipeline(pip);

    vs_uniform.iResolution.x = pxl.sapp.widthf();
    vs_uniform.iResolution.y = pxl.sapp.heightf();
    fs_uniform.iTime = pxl.util.cast(f32, pxl.time.frame_count) / 60.0;
    api.setUniform(&vs_uniform, &fs_uniform);

    api.drawRect(.init(pxl.sapp.widthf() * 0.5, pxl.sapp.heightf() * 0.5), .init(pxl.sapp.widthf(), pxl.sapp.heightf()), Color.white);
    api.resetPipeline();

    pxl.endPass();
}
