const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;
const mu = pxl.mu;
const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const Rect = pxl.math.Rect;

var worm: Worm = .{};
var ferris: pxl.gpu.Texture = undefined;
var camera: pxl.Camera = .{
    .position = .init(160, 90),
    .zoom = 1.0,
    .rotation = 0,
};

// Solid blocks defined by top-left (x, y) and size (w, h) in world space
const blocks = [_]Rect{
    .{ .x = 40, .y = 30, .w = 40, .h = 40 },
    .{ .x = 240, .y = 30, .w = 40, .h = 40 },
    .{ .x = 40, .y = 110, .w = 40, .h = 40 },
    .{ .x = 240, .y = 110, .w = 40, .h = 40 },
};

fn resolveBlockCollision(pt: *Vec2, radius: f32, rect: Rect) void {
    const rx1 = rect.x;
    const ry1 = rect.y;
    const rx2 = rect.x + rect.w;
    const ry2 = rect.y + rect.h;

    const cx = std.math.clamp(pt.x, rx1, rx2);
    const cy = std.math.clamp(pt.y, ry1, ry2);

    const dx = pt.x - cx;
    const dy = pt.y - cy;
    const dist_sq = dx * dx + dy * dy;

    if (dist_sq < radius * radius) {
        if (dist_sq > 0.00001) {
            const dist = @sqrt(dist_sq);
            const overlap = radius - dist;
            pt.x += (dx / dist) * overlap;
            pt.y += (dy / dist) * overlap;
        } else {
            // Inside box: push out to nearest edge
            const left_dist = pt.x - rx1;
            const right_dist = rx2 - pt.x;
            const top_dist = pt.y - ry1;
            const bottom_dist = ry2 - pt.y;

            const min_dist = @min(@min(left_dist, right_dist), @min(top_dist, bottom_dist));

            if (min_dist == left_dist) {
                pt.x = rx1 - radius;
            } else if (min_dist == right_dist) {
                pt.x = rx2 + radius;
            } else if (min_dist == top_dist) {
                pt.y = ry1 - radius;
            } else {
                pt.y = ry2 + radius;
            }
        }
    }
}

const Worm = struct {
    points: [5]Vec2 = [_]Vec2{Vec2.init(160, 90)} ** 5,
    seg_length: f32 = 10.0,

    pub fn update(self: *Worm, target_head_pos: Vec2) void {
        // Head moves to target position in world space
        self.points[0] = target_head_pos;

        // Collide head with blocks
        for (blocks) |b| {
            resolveBlockCollision(&self.points[0], 3.5, b);
        }

        // Each subsequent segment follows the previous segment
        for (1..5) |i| {
            const prev = self.points[i - 1];
            const curr = self.points[i];
            const dx = curr.x - prev.x;
            const dy = curr.y - prev.y;
            const dist = @sqrt(dx * dx + dy * dy);

            if (dist > self.seg_length) {
                const angle = std.math.atan2(dy, dx);
                self.points[i] = Vec2.init(
                    prev.x + @cos(angle) * self.seg_length,
                    prev.y + @sin(angle) * self.seg_length,
                );
            }

            // Collide segment with blocks
            for (blocks) |b| {
                resolveBlockCollision(&self.points[i], 2.5, b);
            }
        }
    }

    pub fn draw(self: Worm) void {
        // Draw lines connecting segment points
        for (0..4) |i| {
            const p1 = self.points[i];
            const p2 = self.points[i + 1];
            const thickness: f32 = 4.0 - @as(f32, @floatFromInt(i)) * 0.6;
            api.drawLine(p1, p2, thickness, Color.lime);
        }

        // Draw joint points (head is gold, body is orange)
        for (self.points, 0..) |pt, i| {
            const r: f32 = if (i == 0) 3.5 else 2.0;
            const col: Color = if (i == 0) Color.gold else Color.orange;
            api.drawCircle(pt, r, col, 16);
        }
    }
};

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        .update = update,
        .render = render,
        .shutdown = shutdown,
        .gfx = .{
            .design_width = 320,
            .design_height = 180,
            .resolution_policy = .show_all_pixel_perfect,
        },
    });
}

fn setup() !void {
    ferris = try pxl.gpu.Texture.initFromFile("examples/assets/ferris_smol.png");
}

fn shutdown() !void {
    ferris.deinit();
}

fn update() !void {
    // MicroUI Controls Window
    if (mu.beginWindowEx("Camera Controls", .{ .x = 10, .y = 10, .w = 200, .h = 160 }, .{ .align_center = false })) {
        mu.layoutRow(2, &[_]c_int{ 75, -1 }, 0);

        mu.label("Pos X:");
        _ = mu.slider(&camera.position.x, 0, 320, 1);

        mu.label("Pos Y:");
        _ = mu.slider(&camera.position.y, 0, 180, 1);

        mu.label("Zoom:");
        _ = mu.slider(&camera.zoom, 0.5, 4.0, 0.1);

        mu.label("Rotation:");
        _ = mu.slider(&camera.rotation, -3.14, 3.14, 0.05);

        mu.endWindow();
    }

    // Update worm head to follow mouse in world space
    const mouse_design = pxl.input.mousePosScaledVec();
    const mouse_world = camera.screenToWorld(mouse_design);
    worm.update(mouse_world);
}

fn render() !void {
    pxl.beginPass(.{
        .clear_color = Color.aya,
        .camera = camera,
    });

    // Draw background grid lines
    var x: f32 = 0;
    while (x <= 320) : (x += 20) {
        api.drawLine(.init(x, 0), .init(x, 180), 1, Color.fromRgba(0.25, 0.25, 0.25, 1));
    }
    var y: f32 = 0;
    while (y <= 180) : (y += 20) {
        api.drawLine(.init(0, y), .init(320, y), 1, Color.fromRgba(0.25, 0.25, 0.25, 1));
    }

    // Draw solid blocks (api.drawRect defaults to top-left!)
    for (blocks) |b| {
        api.drawRect(.init(b.x, b.y), .init(b.w, b.h), Color.dark_gray);
        api.drawRectOutline(.init(b.x, b.y), .init(b.w, b.h), 1, Color.light_gray);
    }

    // Draw center rect & pixel art ferris
    api.drawRectEx(.init(160, 90), .init(40, 40), .center, Color.sky_blue);
    api.drawSprite(.{
        .texture = ferris,
        .transform = .{
            .pos = .init(160, 90),
            .origin = .center,
        },
    });

    // Draw worm creature
    worm.draw();

    pxl.endPass();
}
