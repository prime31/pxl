const std = @import("std");
const pxl = @import("pxl");
const sg = pxl.sg;
const sgp = pxl.sgp;

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
    pip = sgp.make_pipeline(&.{
        .shader = sg.makeShader(pxl.shaders.gpExampleShaderDesc(sg.queryBackend())),
        .has_vs_color = true,
    });
}

fn render() !void {
    pxl.beginPass(.{ .action = .clear });

    sgp.set_pipeline(pip);

    vs_uniform.iResolution.x = pxl.sapp.widthf();
    vs_uniform.iResolution.y = pxl.sapp.heightf();
    fs_uniform.iTime = pxl.util.cast(f32, pxl.time.frame_count) / 60.0;
    sgp.set_uniform(&vs_uniform, @sizeOf(pxl.shaders.GpExampleVsUniforms), &fs_uniform, @sizeOf(pxl.shaders.GpExampleFsUniforms));

    sgp.unset_image(0);
    sgp.draw_filled_rect(0, 0, pxl.sapp.widthf(), pxl.sapp.heightf());
    sgp.reset_image(0);
    sgp.reset_pipeline();

    pxl.endPass();
}

fn shutdown() !void {}
