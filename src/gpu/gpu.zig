const std = @import("std");
const pxl = @import("../pxl.zig");
const sg = pxl.sokol.gfx;

const UNIFORM_SLOT_FRAGMENT: u32 = 1;

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

pub const animation = @import("animation.zig");
pub const Animation = animation.Animation;
pub const AnimationId = animation.AnimationId;
pub const AnimationPlayer = animation.AnimationPlayer;

pub const Rect = pxl.math.Rect;
pub const Transform = sprite.Transform;
pub const BlendMode = @import("batcher.zig").BlendMode;
pub const Camera = @import("camera.zig").Camera;

pub const particle = @import("particle.zig");
pub const ParticleSystem = particle.ParticleSystem;
pub const Particle = particle.Particle;
pub const EmitterParams = particle.EmitterParams;

pub const Config = struct {
    clear_color: pxl.math.Color = pxl.math.Color.aya,
    /// Batcher staging/GPU buffer capacity. Must hold a whole frame's geometry, since
    /// vertices accumulate across all flushes in a frame (raise for heavy scenes).
    batcher: BatcherConfig = .{},
    // the width of the main offscreen render texture when the policy is not .default
    design_width: i32 = 0,
    // the height of the main offscreen render texture when the policy is not .default
    design_height: i32 = 0,
    // defines how the main render texture should be blitted to the backbuffer
    resolution_policy: ResolutionPolicy = .default,
    // enables a minimal bloom post-process pass on the offscreen render target
    bloom_enabled: bool = false,
    // render bloom intermediate textures at 1 / bloom_downsample scale
    bloom_downsample: i32 = 2,
    // luminance threshold for bloom extraction, clamped to [0, 4]
    bloom_threshold: f32 = 0.7,
    // final bloom intensity multiplier, clamped to >= 0
    bloom_intensity: f32 = 1.2,
    // blur sampling radius multiplier, clamped to >= 0
    bloom_blur_radius: f32 = 1.0,
};

pub var gfx_config: Config = .{};

pub const offscreen = struct {
    pub var attachments: sg.Attachments = .{};
    pub var img: sg.Image = .{};
    pub var smp: sg.Sampler = .{};

    pub var pass: sg.Pass = .{};
    var pip: sg.Pipeline = .{};
    var bind: sg.Bindings = .{};

    pub const bloom = struct {
        pub var extract_img: sg.Image = .{};
        pub var ping_img: sg.Image = .{};
        pub var blur_img: sg.Image = .{};

        pub var extract_color_view: sg.View = .{};
        pub var ping_color_view: sg.View = .{};
        pub var blur_color_view: sg.View = .{};

        pub var extract_sample_view: sg.View = .{};
        pub var ping_sample_view: sg.View = .{};
        pub var blur_sample_view: sg.View = .{};

        pub var linear_smp: sg.Sampler = .{};

        pub var extract_pass: sg.Pass = .{};
        pub var ping_pass: sg.Pass = .{};
        pub var blur_pass: sg.Pass = .{};

        pub var extract_pip: sg.Pipeline = .{};
        pub var blur_h_pip: sg.Pipeline = .{};
        pub var blur_v_pip: sg.Pipeline = .{};
        pub var composite_pip: sg.Pipeline = .{};
    };
};

pub fn init(config: Config) void {
    gfx_config = config;

    offscreen.smp = sg.makeSampler(.{
        .min_filter = .NEAREST,
        .mag_filter = .NEAREST,
        .wrap_u = .CLAMP_TO_EDGE,
        .wrap_v = .CLAMP_TO_EDGE,
    });

    offscreen.bind.samplers[pxl.shaders.SMP_blit_smp] = offscreen.smp;

    offscreen.pip = sg.makePipeline(.{
        .shader = sg.makeShader(pxl.shaders.blitShaderDesc(sg.queryBackend())),
        .label = "blit",
    });

    if (gfx_config.bloom_enabled) {
        offscreen.bloom.linear_smp = sg.makeSampler(.{
            .min_filter = .LINEAR,
            .mag_filter = .LINEAR,
            .wrap_u = .CLAMP_TO_EDGE,
            .wrap_v = .CLAMP_TO_EDGE,
        });

        offscreen.bloom.extract_pip = sg.makePipeline(.{
            .shader = sg.makeShader(pxl.shaders.bloomExtractShaderDesc(sg.queryBackend())),
            .depth = .{ .pixel_format = .NONE },
            .label = "bloom_extract",
        });

        offscreen.bloom.blur_h_pip = sg.makePipeline(.{
            .shader = sg.makeShader(pxl.shaders.bloomBlurHShaderDesc(sg.queryBackend())),
            .depth = .{ .pixel_format = .NONE },
            .label = "bloom_blur_h",
        });

        offscreen.bloom.blur_v_pip = sg.makePipeline(.{
            .shader = sg.makeShader(pxl.shaders.bloomBlurVShaderDesc(sg.queryBackend())),
            .depth = .{ .pixel_format = .NONE },
            .label = "bloom_blur_v",
        });

        offscreen.bloom.composite_pip = sg.makePipeline(.{
            .shader = sg.makeShader(pxl.shaders.bloomCompositeShaderDesc(sg.queryBackend())),
            .label = "bloom_composite",
        });
    }

    createOffscreenAttachments();
}

pub fn deinit() void {
    if (gfx_config.bloom_enabled) {
        destroyBloomAttachments();
        sg.destroyPipeline(offscreen.bloom.extract_pip);
        sg.destroyPipeline(offscreen.bloom.blur_h_pip);
        sg.destroyPipeline(offscreen.bloom.blur_v_pip);
        sg.destroyPipeline(offscreen.bloom.composite_pip);
        sg.destroySampler(offscreen.bloom.linear_smp);
    }

    sg.destroyPipeline(offscreen.pip);
    sg.destroyImage(offscreen.img);
    sg.destroySampler(offscreen.smp);
    sg.destroyView(offscreen.pass.attachments.colors[0]);
    sg.destroyView(offscreen.bind.views[pxl.shaders.VIEW_tex]);
}

/// True when the resolution policy guarantees an integer-scaled blit of a fixed
/// design-size render target. Under these policies every draw should land on the
/// render target's pixel grid (see `Pass.pixel_snap`).
pub fn isPixelPerfect() bool {
    return switch (gfx_config.resolution_policy) {
        .no_border_pixel_perfect, .show_all_pixel_perfect => true,
        else => false,
    };
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

    if (gfx_config.bloom_enabled) createBloomAttachments(rt_w, rt_h);
}

pub fn blitRenderTexture(comptime has_imgui: bool) void {
    if (gfx_config.bloom_enabled) {
        runBloomPasses();
    }

    var pass_action = sg.PassAction{};
    pass_action.colors[0] = .{ .load_action = .CLEAR };

    sg.beginPass(.{ .action = pass_action, .swapchain = @import("sokol").glue.swapchain() });

    if (gfx_config.resolution_policy != .default) {
        const scaler = gfx_config.resolution_policy.getScaler(gfx_config.design_width, gfx_config.design_height);
        const view_w: f32 = scaler.widthf() * scaler.scale;
        const view_h: f32 = scaler.heightf() * scaler.scale;
        sg.applyViewportf(@floatFromInt(scaler.x), @floatFromInt(scaler.y), view_w, view_h, true);
    }

    if (gfx_config.bloom_enabled) {
        var bind = sg.Bindings{};
        bind.views[pxl.shaders.VIEW_scene_tex] = offscreen.bind.views[pxl.shaders.VIEW_tex];
        bind.views[pxl.shaders.VIEW_bloom_mix_tex] = offscreen.bloom.blur_sample_view;
        bind.samplers[pxl.shaders.SMP_bloom_smp] = offscreen.bloom.linear_smp;

        sg.applyPipeline(offscreen.bloom.composite_pip);
        sg.applyBindings(bind);

        var composite_uni: pxl.shaders.BloomCompositeFsUniforms = .{
            .u_intensity = @max(0.0, gfx_config.bloom_intensity),
        };
        sg.applyUniforms(UNIFORM_SLOT_FRAGMENT, sg.asRange(&composite_uni));
    } else {
        sg.applyPipeline(offscreen.pip);
        sg.applyBindings(offscreen.bind);
    }
    sg.draw(0, 3, 1);

    // Reset viewport to full swapchain window before rendering MicroUI
    sg.applyViewportf(0, 0, pxl.sapp.widthf(), pxl.sapp.heightf(), true);
    pxl.mu.render();
    if (has_imgui) @import("sokol").imgui.render();

    sg.endPass();
}

fn createBloomAttachments(rt_w: i32, rt_h: i32) void {
    destroyBloomAttachments();

    const downsample = @max(1, gfx_config.bloom_downsample);
    const bloom_w = @max(1, @divTrunc(rt_w, downsample));
    const bloom_h = @max(1, @divTrunc(rt_h, downsample));

    offscreen.bloom.extract_img = sg.makeImage(.{
        .usage = .{ .color_attachment = true },
        .width = bloom_w,
        .height = bloom_h,
    });
    offscreen.bloom.ping_img = sg.makeImage(.{
        .usage = .{ .color_attachment = true },
        .width = bloom_w,
        .height = bloom_h,
    });
    offscreen.bloom.blur_img = sg.makeImage(.{
        .usage = .{ .color_attachment = true },
        .width = bloom_w,
        .height = bloom_h,
    });

    offscreen.bloom.extract_color_view = sg.makeView(.{ .color_attachment = .{ .image = offscreen.bloom.extract_img } });
    offscreen.bloom.ping_color_view = sg.makeView(.{ .color_attachment = .{ .image = offscreen.bloom.ping_img } });
    offscreen.bloom.blur_color_view = sg.makeView(.{ .color_attachment = .{ .image = offscreen.bloom.blur_img } });

    offscreen.bloom.extract_sample_view = sg.makeView(.{ .texture = .{ .image = offscreen.bloom.extract_img } });
    offscreen.bloom.ping_sample_view = sg.makeView(.{ .texture = .{ .image = offscreen.bloom.ping_img } });
    offscreen.bloom.blur_sample_view = sg.makeView(.{ .texture = .{ .image = offscreen.bloom.blur_img } });

    offscreen.bloom.extract_pass.attachments.colors[0] = offscreen.bloom.extract_color_view;
    offscreen.bloom.ping_pass.attachments.colors[0] = offscreen.bloom.ping_color_view;
    offscreen.bloom.blur_pass.attachments.colors[0] = offscreen.bloom.blur_color_view;
}

fn destroyBloomAttachments() void {
    sg.destroyView(offscreen.bloom.extract_color_view);
    sg.destroyView(offscreen.bloom.ping_color_view);
    sg.destroyView(offscreen.bloom.blur_color_view);
    sg.destroyView(offscreen.bloom.extract_sample_view);
    sg.destroyView(offscreen.bloom.ping_sample_view);
    sg.destroyView(offscreen.bloom.blur_sample_view);

    sg.destroyImage(offscreen.bloom.extract_img);
    sg.destroyImage(offscreen.bloom.ping_img);
    sg.destroyImage(offscreen.bloom.blur_img);
}

fn runBloomPasses() void {
    const threshold = std.math.clamp(gfx_config.bloom_threshold, @as(f32, 0.0), @as(f32, 4.0));
    const radius = @max(@as(f32, 0.0), gfx_config.bloom_blur_radius);

    var extract_bind = sg.Bindings{};
    extract_bind.views[pxl.shaders.VIEW_scene_tex] = offscreen.bind.views[pxl.shaders.VIEW_tex];
    extract_bind.samplers[pxl.shaders.SMP_bloom_smp] = offscreen.bloom.linear_smp;

    sg.beginPass(offscreen.bloom.extract_pass);
    sg.applyPipeline(offscreen.bloom.extract_pip);
    sg.applyBindings(extract_bind);

    var extract_uni: pxl.shaders.BloomExtractFsUniforms = .{
        .u_threshold = threshold,
    };
    sg.applyUniforms(UNIFORM_SLOT_FRAGMENT, sg.asRange(&extract_uni));

    sg.draw(0, 3, 1);
    sg.endPass();

    var blur_h_bind = sg.Bindings{};
    blur_h_bind.views[pxl.shaders.VIEW_bloom_tex] = offscreen.bloom.extract_sample_view;
    blur_h_bind.samplers[pxl.shaders.SMP_bloom_smp] = offscreen.bloom.linear_smp;

    sg.beginPass(offscreen.bloom.ping_pass);
    sg.applyPipeline(offscreen.bloom.blur_h_pip);
    sg.applyBindings(blur_h_bind);

    var blur_h_uni: pxl.shaders.BloomBlurHFsUniforms = .{
        .u_radius = radius,
    };
    sg.applyUniforms(UNIFORM_SLOT_FRAGMENT, sg.asRange(&blur_h_uni));

    sg.draw(0, 3, 1);
    sg.endPass();

    var blur_v_bind = sg.Bindings{};
    blur_v_bind.views[pxl.shaders.VIEW_bloom_tex] = offscreen.bloom.ping_sample_view;
    blur_v_bind.samplers[pxl.shaders.SMP_bloom_smp] = offscreen.bloom.linear_smp;

    sg.beginPass(offscreen.bloom.blur_pass);
    sg.applyPipeline(offscreen.bloom.blur_v_pip);
    sg.applyBindings(blur_v_bind);

    var blur_v_uni: pxl.shaders.BloomBlurVFsUniforms = .{
        .u_radius = radius,
    };
    sg.applyUniforms(UNIFORM_SLOT_FRAGMENT, sg.asRange(&blur_v_uni));

    sg.draw(0, 3, 1);
    sg.endPass();
}
