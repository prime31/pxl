const std = @import("std");
const pxl = @import("../pxl.zig");
const sg = pxl.sokol.gfx;

pub const ResolutionPolicy = @import("resolution_policy.zig").ResolutionPolicy;
pub const ResolutionScaler = @import("resolution_policy.zig").ResolutionScaler;
pub const Batcher = @import("batcher.zig").Batcher;
pub const BatcherConfig = @import("batcher.zig").BatcherConfig;
pub const Texture = @import("texture.zig").Texture;
pub const Vertex = @import("batcher.zig").Vertex;
pub const Mesh = Batcher.Mesh;

pub const sprite = @import("sprite.zig");
pub const Anchor = sprite.Anchor;
pub const Sprite = sprite.Sprite;
pub const Rect = sprite.Rect;
pub const Transform = sprite.Transform;
pub const BlendMode = @import("batcher.zig").BlendMode;
pub const Camera = @import("camera.zig").Camera;

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

pub var gfx_config: Config = .{};

pub const offscreen = struct {
    var pass_action: sg.PassAction = .{};
    pub var attachments: sg.Attachments = .{};
    pub var img: sg.Image = .{};
    pub var smp: sg.Sampler = .{};

    pub var pass: sg.Pass = .{};
    var pip: sg.Pipeline = .{};
    var bind: sg.Bindings = .{};
};

pub fn init(config: Config) void {
    gfx_config = config;
    createOffscreenAttachments();

    offscreen.smp = sg.makeSampler(.{
        .min_filter = .NEAREST,
        .mag_filter = .NEAREST,
        .wrap_u = .CLAMP_TO_EDGE,
        .wrap_v = .CLAMP_TO_EDGE,
    });

    offscreen.bind.samplers[pxl.shaders.SMP_blit_smp] = offscreen.smp;

    offscreen.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = gfx_config.clear_color,
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

pub fn renderWidth() i32 {
    const scaler = gfx_config.resolution_policy.getScaler(gfx_config.design_width, gfx_config.design_height);
    return scaler.w;
}

pub fn renderHeight() i32 {
    const scaler = gfx_config.resolution_policy.getScaler(gfx_config.design_width, gfx_config.design_height);
    return scaler.h;
}

pub fn renderWidthf() f32 {
    return @floatFromInt(renderWidth());
}

pub fn renderHeightf() f32 {
    return @floatFromInt(renderHeight());
}

pub fn createOffscreenAttachments() void {
    const scaler = gfx_config.resolution_policy.getScaler(gfx_config.design_width, gfx_config.design_height);
    const rt_w = scaler.w;
    const rt_h = scaler.h;

    sg.destroyImage(offscreen.img);
    sg.destroyView(offscreen.pass.attachments.colors[0]);
    sg.destroyView(offscreen.bind.views[pxl.shaders.VIEW_tex]);

    offscreen.img = sg.makeImage(.{
        .usage = .{ .color_attachment = true },
        .width = rt_w,
        .height = rt_h,
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
    var pass_action = sg.PassAction{};
    pass_action.colors[0] = .{ .load_action = .CLEAR };

    sg.beginPass(.{ .action = pass_action, .swapchain = pxl.sglue.swapchain() });

    if (gfx_config.resolution_policy != .default) {
        const scaler = gfx_config.resolution_policy.getScaler(gfx_config.design_width, gfx_config.design_height);
        const view_w: f32 = @floatFromInt(@as(i32, @intFromFloat(@as(f32, @floatFromInt(scaler.w)) * scaler.scale)));
        const view_h: f32 = @floatFromInt(@as(i32, @intFromFloat(@as(f32, @floatFromInt(scaler.h)) * scaler.scale)));
        sg.applyViewportf(@floatFromInt(scaler.x), @floatFromInt(scaler.y), view_w, view_h, true);
    }

    sg.applyPipeline(offscreen.pip);
    sg.applyBindings(offscreen.bind);
    sg.draw(0, 3, 1);

    // Reset viewport to full swapchain window before rendering MicroUI
    sg.applyViewportf(0, 0, pxl.sapp.widthf(), pxl.sapp.heightf(), true);
    pxl.mu.render();

    sg.endPass();
}
