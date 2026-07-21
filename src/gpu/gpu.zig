const std = @import("std");
const pxl = @import("../pxl.zig");
const sg = pxl.sokol.gfx;

pub const Texture = @import("texture.zig").Texture;

pub const offscreen = struct {
    var pass_action: sg.PassAction = .{};
    pub var attachments: sg.Attachments = .{};
    // var depth_stencil_img: sg.Image = .{};
    pub var img: sg.Image = .{};
    pub var smp: sg.Sampler = .{};

    pub var pass: sg.Pass = .{};
    var pip: sg.Pipeline = .{};
    var bind: sg.Bindings = .{};
};

pub fn init() void {
    createOffscreenAttachments(pxl.sapp.width(), pxl.sapp.height());

    offscreen.smp = sg.makeSampler(.{
        .min_filter = .LINEAR,
        .mag_filter = .LINEAR,
        .wrap_u = .CLAMP_TO_EDGE,
        .wrap_v = .CLAMP_TO_EDGE,
    });

    offscreen.bind.samplers[pxl.shaders.SMP_blit_smp] = offscreen.smp;

    offscreen.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 1, .g = 0.5, .b = 0, .a = 1 },
    };

    offscreen.pip = sg.makePipeline(.{
        .shader = sg.makeShader(pxl.shaders.blitShaderDesc(sg.queryBackend())),
        .label = "blit",
    });
}

pub fn deinit() void {
    sg.destroyPipeline(offscreen.pip);
    sg.destroyImage(offscreen.img);
    sg.destroySampler(offscreen.smp);
}

pub fn createOffscreenAttachments(width: i32, height: i32) void {
    sg.destroyImage(offscreen.img);
    sg.destroyView(offscreen.pass.attachments.colors[0]);
    sg.destroyView(offscreen.bind.views[pxl.shaders.VIEW_tex]);

    offscreen.img = sg.makeImage(.{
        .usage = .{ .color_attachment = true },
        .width = width,
        .height = height,
        // .sample_count = offscreen_sample_count,
        // .pixel_format = offscreen_pixel_format,
    });

    offscreen.pass.attachments.colors[0] = sg.makeView(.{
        .color_attachment = .{ .image = offscreen.img },
    });

    offscreen.bind.views[pxl.shaders.VIEW_tex] = sg.makeView(.{
        .texture = .{ .image = offscreen.img },
    });
}

pub fn clearRenderTexture() void {
    sg.beginPass(offscreen.pass);
    sg.endPass();
}

pub fn blitRenderTexture() void {
    var sgl_pass_action = sg.PassAction{};
    sgl_pass_action.colors[0].load_action = .LOAD;

    sg.beginPass(.{ .action = sgl_pass_action, .swapchain = pxl.sglue.swapchain() });

    sg.applyPipeline(offscreen.pip);
    sg.applyBindings(offscreen.bind);
    sg.draw(0, 3, 1);

    sg.endPass();
}
