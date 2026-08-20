const std = @import("std");
const pxl = @import("../pxl.zig");
const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const Vec = pxl.util.Vec;

const fixed_dt: f32 = 1.0 / 60.0;

/// A single point mass with Verlet (implicit) velocity: velocity is `pos - prev`.
pub const Point = struct {
    pos: Vec2 = .zero,
    prev: Vec2 = .zero,
    pinned: bool = false,
};

/// Query: true when `pos` (world px) is inside solid geometry.
pub const SolidQuery = *const fn (Vec2) bool;

/// An interactive rope: a chain of point masses joined by soft distance
/// constraints, modeled on Lazr's Sys_Chains. External impulses accumulate in an
/// acceleration buffer (see `pushNear`) and are applied on the next fixed step,
/// which is what lets the hero and bullets shove it around.
pub const Rope = struct {
    points: Vec(Point) = .empty,
    accel: Vec(Vec2) = .empty,
    spacing: f32,
    gravity: Vec2,
    /// Velocity retained per fixed step (Lazr's 0.98 friction).
    damping: f32 = 0.98,
    /// Per-step displacement clamp; keeps a fast shove from tunnelling (Lazr's 2.5).
    max_speed: f32 = 2.5,
    /// Soft-spring correction strength toward `spacing` (Lazr's RelaxChain 0.25).
    relax: f32 = 0.25,
    accumulator: f32 = 0,

    pub fn init(anchor: Vec2, segments: usize, spacing: f32, gravity: Vec2) Rope {
        var r = Rope{
            .points = .empty,
            .accel = .empty,
            .spacing = spacing,
            .gravity = gravity,
        };
        r.points.ensureTotalCapacity(segments);
        r.accel.ensureTotalCapacity(segments);
        var i: usize = 0;
        while (i < segments) : (i += 1) {
            const pos = anchor.add(Vec2.init(0, @as(f32, @floatFromInt(i)) * spacing));
            r.points.append(.{ .pos = pos, .prev = pos, .pinned = i == 0 });
            r.accel.append(.zero);
        }
        return r;
    }

    pub fn deinit(self: *Rope) void {
        self.points.deinit();
        self.accel.deinit();
    }

    pub fn len(self: *const Rope) usize {
        return self.points.items.len;
    }

    pub fn point(self: *const Rope, i: usize) Vec2 {
        return self.points.items[i].pos;
    }

    /// Parametric position along the chain (in node-index units). Used by the
    /// hero to hang from a smoothly interpolated point while climbing.
    pub fn pointAt(self: *const Rope, t: f32) Vec2 {
        const last = @as(f32, @floatFromInt(self.points.items.len - 1));
        const clamped = std.math.clamp(t, 0, last);
        const lo: usize = @intFromFloat(@floor(clamped));
        const hi: usize = @min(lo + 1, self.points.items.len - 1);
        const frac = clamped - @as(f32, @floatFromInt(lo));
        const a = self.points.items[lo].pos;
        const b = self.points.items[hi].pos;
        return a.add(b.sub(a).scale(frac));
    }

    /// Adds `impulse` to every free point mass within `radius` of `pos`.
    pub fn pushNear(self: *Rope, pos: Vec2, impulse: Vec2, radius: f32) void {
        for (self.points.items, self.accel.items) |p, *a| {
            if (p.pinned) continue;
            if (p.pos.sub(pos).len() <= radius) a.* = a.add(impulse);
        }
    }

    /// Adds `impulse` to a single free point mass (used for swinging while climbing).
    pub fn push(self: *Rope, i: usize, impulse: Vec2) void {
        if (i >= self.accel.items.len) return;
        if (self.points.items[i].pinned) return;
        self.accel.items[i] = self.accel.items[i].add(impulse);
    }

    /// The point mass nearest to `pos` within `reach`, skipping the pinned anchor.
    pub fn grab(self: *const Rope, pos: Vec2, reach: f32) ?usize {
        var best: ?usize = null;
        var best_d = reach;
        var i: usize = 1;
        while (i < self.points.items.len) : (i += 1) {
            const d = self.points.items[i].pos.sub(pos).len();
            if (d <= best_d) {
                best_d = d;
                best = i;
            }
        }
        return best;
    }

    /// Fixed-timestep simulation; safe to call with variable frame dt.
    pub fn update(self: *Rope, dt: f32, solid: ?SolidQuery) void {
        self.accumulator += dt;
        self.accumulator = @min(self.accumulator, fixed_dt * 4);
        while (self.accumulator >= fixed_dt) : (self.accumulator -= fixed_dt) {
            self.step(fixed_dt, solid);
        }
    }

    fn step(self: *Rope, dt: f32, solid: ?SolidQuery) void {
        self.relaxChain();

        var i: usize = 0;
        while (i < self.points.items.len) : (i += 1) {
            const p = &self.points.items[i];
            const a = self.accel.items[i];
            if (p.pinned) {
                self.accel.items[i] = .zero;
                continue;
            }

            var vx = p.pos.x - p.prev.x;
            var vy = p.pos.y - p.prev.y;
            const speed = @sqrt(vx * vx + vy * vy);
            if (speed > self.max_speed) {
                const s = self.max_speed / speed;
                vx *= s;
                vy *= s;
            }
            vx *= self.damping;
            vy *= self.damping;

            const nx = p.pos.x + vx + a.x;
            const ny = p.pos.y + vy + a.y + self.gravity.y * dt * dt;
            self.accel.items[i] = .zero;

            var ok_x = true;
            var ok_y = true;
            if (solid) |s| {
                ok_x = !s(.init(nx, p.pos.y));
                ok_y = !s(.init(p.pos.x, ny));
            }

            p.prev = p.pos;
            if (ok_x) p.pos.x = nx;
            if (ok_y) p.pos.y = ny;
        }
    }

    /// Soft distance constraints: each segment nudges toward `spacing` by adding
    /// acceleration, so the rope stretches and springs back (Lazr's RelaxChain).
    fn relaxChain(self: *Rope) void {
        var i: usize = 1;
        while (i < self.points.items.len) : (i += 1) {
            const a = self.points.items[i - 1];
            const b = self.points.items[i];
            const dx = b.pos.x - a.pos.x;
            const dy = b.pos.y - a.pos.y;
            const dist = @sqrt(dx * dx + dy * dy);
            if (dist < 1e-6) continue;
            const err = (self.spacing - 1.0 - dist) / dist;
            self.accel.items[i].x += dx * self.relax * err * 1.1;
            self.accel.items[i].y += dy * self.relax * err * 1.4;
            self.accel.items[i - 1].x -= dx * self.relax * err * 1.0;
            self.accel.items[i - 1].y -= dy * self.relax * err * 1.0;
        }
    }

    pub fn draw(self: *const Rope, color: Color) void {
        var i: usize = 1;
        while (i < self.points.items.len) : (i += 1) {
            pxl.api.drawLine(self.points.items[i - 1].pos, self.points.items[i].pos, 2, color);
        }
        const last = self.points.items[self.points.items.len - 1].pos;
        pxl.api.drawCircle(last, 2, 8, color);
    }
};
