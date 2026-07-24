const std = @import("std");

const pxl = @import("pxl");
const ig = pxl.ig;

const Vec2 = pxl.math.Vec2;

const Crab = struct {
    pos: Vec2,
    vel: Vec2,
};

var texture: pxl.gpu.Texture = undefined;
var crabs: pxl.util.Vec(Crab) = .empty;

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        .update = update,
        .render = render,
        .shutdown = shutdown,
        .batcher = .{
            .max_verts = 3_000_000,
            .max_indices = 3_000_000,
        },
    });
}

fn setup() !void {
    texture = try pxl.gpu.Texture.initFromFile("examples/assets/ferris_smol.png");

    const w: f32 = @floatFromInt(pxl.sapp.width());
    const h: f32 = @floatFromInt(pxl.sapp.height());
    crabs.append(spawnCrab(Vec2.init(w, h)));
    crabs.append(spawnCrab(Vec2.init(w, h)));
}

fn shutdown() !void {
    texture.deinit();
    crabs.deinit();
}

fn update() !void {
    const dt: f32 = @floatCast(pxl.sapp.frameDuration());
    const bounds = Vec2.init(@floatFromInt(pxl.sapp.width()), @floatFromInt(pxl.sapp.height()));

    for (crabs.items) |*crab| {
        crab.pos = crab.pos.add(crab.vel.scale(dt));
        bounce(&crab.pos, &crab.vel, bounds, 32);
    }

    if (pxl.input.mouseDown(.left)) {
        const w: f32 = @floatFromInt(pxl.sapp.width());
        const h: f32 = @floatFromInt(pxl.sapp.height());

        for (0..3000) |_|
            crabs.append(spawnCrab(Vec2.init(w, h)));
    }

    std.debug.print("total: {}, dt: {:.3}, fps: {}, gg.dt: {d:.3}\n", .{
        crabs.items.len,
        dt,
        pxl.time.frames_per_second,
        pxl.time.deltaTime(),
    });
}

fn render() !void {
    pxl.beginPass(.{ .action = .clear });
    for (crabs.items) |*crab| {
        pxl.batcher.drawTexture(texture, crab.pos);
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
