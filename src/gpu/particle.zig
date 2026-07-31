const std = @import("std");
const pxl = @import("../pxl.zig");
const api = pxl.api;
const lerp = std.math.lerp;

const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const BlendMode = pxl.gpu.BlendMode;
const Texture = pxl.gpu.Texture;

pub const Particle = struct {
    pos: Vec2,
    vel: Vec2,
    accel: Vec2,
    color_start: Color,
    color_end: Color,
    size_start: f32,
    size_end: f32,
    rotation: f32,
    angular_velocity: f32,
    lifetime: f32,
    age: f32 = 0.0,
    texture: ?Texture = null,
    blend_mode: BlendMode = .blend,
};

pub const EmitterParams = struct {
    position: Vec2 = .zero,
    spawn_area: Vec2 = .zero,
    lifetime_min: f32 = 0.5,
    lifetime_max: f32 = 1.5,
    speed_min: f32 = 20.0,
    speed_max: f32 = 100.0,
    angle_min: f32 = 0.0,
    angle_max: f32 = std.math.tau,
    accel: Vec2 = .zero,
    size_start_min: f32 = 4.0,
    size_start_max: f32 = 8.0,
    size_end_min: f32 = 0.0,
    size_end_max: f32 = 2.0,
    color_start: Color = Color.white,
    color_end: Color = Color.fromRgba(1, 1, 1, 0),
    rotation_min: f32 = 0.0,
    rotation_max: f32 = std.math.tau,
    angular_velocity_min: f32 = -2.0,
    angular_velocity_max: f32 = 2.0,
    blend_mode: BlendMode = .blend,
    texture: ?Texture = null,
};

pub const ParticleSystem = struct {
    particles: []Particle,
    active_count: usize = 0,
    prng: std.Random.DefaultPrng,

    pub fn init(max_particles: usize) ParticleSystem {
        const particles = pxl.mem.alloc(Particle, max_particles, .persistent);
        const seed: u64 = @intCast(std.Io.Clock.now(.awake, pxl.io).toMilliseconds());
        return .{
            .particles = particles,
            .active_count = 0,
            .prng = std.Random.DefaultPrng.init(seed),
        };
    }

    pub fn deinit(self: *ParticleSystem) void {
        pxl.mem.free(self.particles);
    }

    pub fn emit(self: *ParticleSystem, params: EmitterParams, count: usize) void {
        var rand = self.prng.random();
        for (0..count) |_| {
            if (self.active_count >= self.particles.len) break;

            const angle = lerp(params.angle_min, params.angle_max, rand.float(f32));
            const speed = lerp(params.speed_min, params.speed_max, rand.float(f32));
            const lifetime = lerp(params.lifetime_min, params.lifetime_max, rand.float(f32));
            const size_start = lerp(params.size_start_min, params.size_start_max, rand.float(f32));
            const size_end = lerp(params.size_end_min, params.size_end_max, rand.float(f32));
            const rot = lerp(params.rotation_min, params.rotation_max, rand.float(f32));
            const ang_vel = lerp(params.angular_velocity_min, params.angular_velocity_max, rand.float(f32));

            const offset = Vec2.init(
                (rand.float(f32) * 2.0 - 1.0) * params.spawn_area.x,
                (rand.float(f32) * 2.0 - 1.0) * params.spawn_area.y,
            );

            self.particles[self.active_count] = .{
                .pos = params.position.add(offset),
                .vel = Vec2.init(@cos(angle) * speed, @sin(angle) * speed),
                .accel = params.accel,
                .color_start = params.color_start,
                .color_end = params.color_end,
                .size_start = size_start,
                .size_end = size_end,
                .rotation = rot,
                .angular_velocity = ang_vel,
                .lifetime = lifetime,
                .age = 0.0,
                .texture = params.texture,
                .blend_mode = params.blend_mode,
            };
            self.active_count += 1;
        }
    }

    pub fn update(self: *ParticleSystem, dt: f32) void {
        var i: usize = 0;
        while (i < self.active_count) {
            var p = &self.particles[i];
            p.age += dt;
            if (p.age >= p.lifetime) {
                // Swap with last active particle
                self.particles[i] = self.particles[self.active_count - 1];
                self.active_count -= 1;
                continue;
            }

            p.vel = p.vel.add(p.accel.scale(dt));
            p.pos = p.pos.add(p.vel.scale(dt));
            p.rotation += p.angular_velocity * dt;
            i += 1;
        }
    }

    pub fn draw(self: *const ParticleSystem) void {
        for (self.particles[0..self.active_count]) |p| {
            const t = p.age / p.lifetime;
            const size = lerp(p.size_start, p.size_end, t);
            const col = lerpColor(p.color_start, p.color_end, t);

            api.setBlendMode(p.blend_mode);
            if (p.texture) |tex| {
                api.drawSprite(
                    .{ .texture = tex, .color = col },
                    .{
                        .pos = p.pos,
                        .scale = .init(size / @as(f32, @floatFromInt(tex.width)), size / @as(f32, @floatFromInt(tex.height))),
                        .rotation = p.rotation,
                        .origin = .center,
                    },
                );
            } else {
                api.drawRectEx(p.pos, .init(size, size), .center, col);
            }
        }
        api.setBlendMode(.blend);
    }
};

fn lerpColor(c1: Color, c2: Color, t: f32) Color {
    const r1: f32 = @floatFromInt(c1.comps.r);
    const g1: f32 = @floatFromInt(c1.comps.g);
    const b1: f32 = @floatFromInt(c1.comps.b);
    const a1: f32 = @floatFromInt(c1.comps.a);

    const r2: f32 = @floatFromInt(c2.comps.r);
    const g2: f32 = @floatFromInt(c2.comps.g);
    const b2: f32 = @floatFromInt(c2.comps.b);
    const a2: f32 = @floatFromInt(c2.comps.a);

    return Color.fromBytes(
        @intFromFloat(lerp(r1, r2, t)),
        @intFromFloat(lerp(g1, g2, t)),
        @intFromFloat(lerp(b1, b2, t)),
        @intFromFloat(lerp(a1, a2, t)),
    );
}
