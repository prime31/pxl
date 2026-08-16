const std = @import("std");
const builtin = @import("builtin");

const pxl = @import("pxl");
const api = pxl.api;
const ig = pxl.ig;

const Vec2 = pxl.math.Vec2;

const Crab = struct {
    pos: Vec2,
    vel: Vec2,
};

// stress tests the batcher by forcing batches with texture swaps
const flip_tex_every_count = 20;

var tex1: *pxl.gpu.Texture = undefined;
var tex2: *pxl.gpu.Texture = undefined;
var crabs: pxl.util.Vec(Crab) = .empty;

pub fn config() pxl.Config {
    return .{
        .gfx = .{
            .batcher = .{
                .max_verts = 3_000_000,
                .max_indices = 3_000_000,
                .max_cmds = 3_000_000,
            },
        },
    };
}

pub fn setup() !void {
    tex1 = try pxl.assets.loadTexture(.ferris_smol);
    tex2 = try pxl.assets.loadTexture(.zig);

    const w: f32 = @floatFromInt(pxl.sapp.width());
    const h: f32 = @floatFromInt(pxl.sapp.height());
    crabs.append(spawnCrab(Vec2.init(w, h)));
    crabs.append(spawnCrab(Vec2.init(w, h)));
}

pub fn shutdown() !void {
    pxl.assets.destroy(tex1);
    pxl.assets.destroy(tex2);
    crabs.deinit();
}

pub fn update() !void {
    const bounds = Vec2.init(@floatFromInt(pxl.sapp.width()), @floatFromInt(pxl.sapp.height()));

    for (crabs.items) |*crab| {
        crab.pos = crab.pos.add(crab.vel.scale(pxl.time.dt()));
        bounce(&crab.pos, &crab.vel, bounds, 32);
    }

    if (pxl.input.mousePressed(.left)) {
        const w: f32 = @floatFromInt(pxl.sapp.width());
        const h: f32 = @floatFromInt(pxl.sapp.height());

        for (0..300) |_|
            crabs.append(spawnCrab(Vec2.init(w, h)));
    }

    if (pxl.input.mouseDown(.right)) {
        const w: f32 = @floatFromInt(pxl.sapp.width());
        const h: f32 = @floatFromInt(pxl.sapp.height());

        for (0..3000) |_|
            crabs.append(spawnCrab(Vec2.init(w, h)));
    }

    std.log.debug("total: {}, dt: {:.3}, fps: {}", .{
        crabs.items.len,
        pxl.time.dt(),
        pxl.time.fps(),
    });
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = pxl.math.Color.dark_gray });
    for (crabs.items, 0..) |*crab, i| {
        const t = if (@mod(i, flip_tex_every_count) == 0) tex1.* else tex2.*;
        api.drawTexture(t, crab.pos);
    }
    pxl.endPass();
}

fn spawnCrab(bounds: Vec2) Crab {
    const angle = pxl.math.rand.range(f32, 0, std.math.tau);
    const pos = Vec2.init(
        pxl.math.rand.range(f32, 0.0, bounds.x),
        pxl.math.rand.range(f32, 0.0, bounds.y),
    );

    return .{
        .pos = pos,
        .vel = Vec2.init(std.math.cos(angle), std.math.sin(angle)).scale(500),
    };
}

fn bounce(pos: *Vec2, vel: *Vec2, bounds: Vec2, size: f32) void {
    if (pos.x < 0.0 or pos.x > bounds.x - size) {
        vel.x *= -1.0;
        pos.x = std.math.clamp(pos.x, 0, bounds.x - size);
    }
    if (pos.y < 0.0 or pos.y > bounds.y - size) {
        vel.y *= -1.0;
        pos.y = std.math.clamp(pos.y, 0.0, bounds.y - size);
    }
}
