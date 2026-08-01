const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;
const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;

var ferris: pxl.gpu.Texture = undefined;

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        .render = render,
        .shutdown = shutdown,
        .gfx = .{
            .design_width = 320,
            .design_height = 180,
            .resolution_policy = .show_all_pixel_perfect,
            .bloom_enabled = true,
            .bloom_downsample = 2,
        },
    });
}

fn setup() !void {
    ferris = try pxl.gpu.Texture.initFromFile("examples/assets/ferris_smol.png");
}

fn shutdown() !void {
    ferris.deinit();
}

fn render() !void {
    const t = @as(f32, @floatFromInt(pxl.time.frameCount())) / 60.0;

    pxl.beginPass(.{ .clear_color = Color.fromBytes(8, 10, 16, 255) });

    // Dark room background blocks.
    api.drawRect(.init(16, 16), .init(288, 148), Color.fromBytes(18, 22, 34, 255));
    api.drawRectOutline(.init(16, 16), .init(288, 148), 2, Color.fromBytes(36, 45, 68, 255));

    // Bright emissive bars and circles that are easy to detect in bloom.
    api.setBlendMode(.add);
    api.drawRectEx(.init(160, 90), .init(160, 10), .center, Color.fromBytes(255, 240, 180, 255));
    api.drawRectEx(.init(160, 90), .init(10, 110), .center, Color.fromBytes(180, 220, 255, 255));

    const orbit_a = Vec2.init(160 + @cos(t) * 70, 90 + @sin(t * 1.4) * 40);
    const orbit_b = Vec2.init(160 + @cos(t * 0.75 + 1.7) * 85, 90 + @sin(t + 0.6) * 55);
    api.drawCircle(orbit_a, 14, 24, Color.fromBytes(255, 180, 90, 255));
    api.drawCircle(orbit_b, 18, 24, Color.fromBytes(120, 190, 255, 255));

    api.setBlendMode(.blend);
    api.drawSprite(
        .{ .texture = ferris, .color = Color.fromBytes(255, 245, 180, 255) },
        .{ .pos = .init(160, 90), .origin = .center },
    );

    pxl.endPass();
}
