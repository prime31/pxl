const std = @import("std");
const pxl = @import("../pxl.zig");
const sg = pxl.sokol.gfx;

pub const ResolutionPolicy = @import("resolution_policy.zig").ResolutionPolicy;
pub const Batcher = @import("batcher.zig").Batcher;
pub const BatcherConfig = @import("batcher.zig").BatcherConfig;
pub const Texture = @import("texture.zig").Texture;
pub const Vertex = @import("batcher.zig").Vertex;
pub const Anchor = @import("batcher.zig").Anchor;
pub const Sprite = @import("batcher.zig").Sprite;
pub const Rect = @import("batcher.zig").Rect;
pub const BlendMode = @import("batcher.zig").BlendMode;

pub const Config = struct {
    clear_color: sg.Color = .{ .r = 0.8, .g = 0.2, .b = 0.3, .a = 1.0 },
    /// Batcher staging/GPU buffer capacity. Must hold a whole frame's geometry, since
    /// vertices accumulate across all flushes in a frame (raise for heavy scenes).
    batcher: BatcherConfig = .{},
    // the width of the main offscreen render texture when the policy is not .default
    design_width: i32 = 0,
    // the height of the main offscreen render texture when the policy is not .default
    design_height: i32 = 0,
    // defines how the main render texture should be blitted to the backbuffer
    resolution_policy: ResolutionPolicy = .default,
};

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

pub fn init(config: Config) void {
    createOffscreenAttachments(pxl.sapp.width(), pxl.sapp.height());

    offscreen.smp = sg.makeSampler(.{
        .min_filter = .NEAREST,
        .mag_filter = .NEAREST,
        .wrap_u = .CLAMP_TO_EDGE,
        .wrap_v = .CLAMP_TO_EDGE,
    });

    offscreen.bind.samplers[pxl.shaders.SMP_blit_smp] = offscreen.smp;

    offscreen.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = config.clear_color,
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

    pxl.mu.render();

    sg.endPass();
}
