const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;
const mu = pxl.mu;
const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;

var ferris: pxl.gpu.Texture = undefined;

pub fn config() pxl.Config {
    return .{
        .gfx = .{
            .design_width = 320,
            .design_height = 180,
            .resolution_policy = .show_all_pixel_perfect,
            .bloom_enabled = true,
            .bloom_downsample = 8,
            .bloom_threshold = 0.7,
            .bloom_intensity = 1.25,
            .bloom_blur_radius = 1.0,
        },
    };
}

pub fn update() !void {
    if (mu.beginWindowEx("Bloom Controls", .{ .x = 10, .y = 10, .w = 220, .h = 140 }, .{})) {
        mu.layoutRow(2, &[_]c_int{ 85, -1 }, 0);

        mu.label("Threshold:");
        _ = mu.slider(&pxl.gpu.gfx_config.bloom_threshold, 0.0, 2.0, 0.01);

        mu.label("Intensity:");
        _ = mu.slider(&pxl.gpu.gfx_config.bloom_intensity, 0.0, 8.0, 0.05);

        mu.label("Radius:");
        _ = mu.slider(&pxl.gpu.gfx_config.bloom_blur_radius, 0.0, 10.0, 0.05);

        mu.endWindow();
    }
}

pub fn setup() !void {
    ferris = try pxl.gpu.Texture.initFromFile("examples/assets/ferris_smol.png");
}

pub fn shutdown() !void {
    ferris.deinit();
}

pub fn render() !void {
    const t = @as(f32, @floatFromInt(pxl.time.frameCount())) / 60.0;
    const rw = pxl.gpu.renderWidthf();
    const rh = pxl.gpu.renderHeightf();
    const cx = rw * 0.5;
    const cy = rh * 0.5;
    const scene_scale = @min(rw / 320.0, rh / 180.0);

    pxl.beginPass(.{ .clear_color = Color.fromBytes(8, 10, 16, 255) });

    // Dark room background blocks.
    const room_x = rw * 0.05;
    const room_y = rh * 0.08888889;
    const room_w = rw * 0.9;
    const room_h = rh * 0.82222223;
    api.drawRect(.init(room_x, room_y), .init(room_w, room_h), Color.fromBytes(18, 22, 34, 255));
    api.drawRectOutline(.init(room_x, room_y), .init(room_w, room_h), 2.0 * scene_scale, Color.fromBytes(36, 45, 68, 255));

    // Bright emissive bars and circles that are easy to detect in bloom.
    api.setBlendMode(.add);
    api.drawRectEx(.init(cx, cy), .init(rw * 0.5, rh * 0.055555556), .center, Color.fromBytes(255, 240, 180, 255));
    api.drawRectEx(.init(cx, cy), .init(rw * 0.03125, rh * 0.6111111), .center, Color.fromBytes(180, 220, 255, 255));

    const orbit_a = Vec2.init(cx + @cos(t) * (rw * 0.21875), cy + @sin(t * 1.4) * (rh * 0.22222222));
    const orbit_b = Vec2.init(cx + @cos(t * 0.75 + 1.7) * (rw * 0.265625), cy + @sin(t + 0.6) * (rh * 0.30555555));
    api.drawCircle(orbit_a, 14.0 * scene_scale, 24, Color.fromBytes(255, 180, 90, 255));
    api.drawCircle(orbit_b, 18.0 * scene_scale, 24, Color.fromBytes(120, 190, 255, 255));

    api.setBlendMode(.blend);
    api.drawSprite(
        .{ .texture = ferris, .color = Color.fromBytes(255, 245, 180, 255) },
        .{ .pos = .init(cx, cy), .origin = .center, .scale = .init(scene_scale, scene_scale) },
    );

    pxl.endPass();
}
