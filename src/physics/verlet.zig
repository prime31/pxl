const std = @import("std");
const pxl = @import("../pxl.zig");
const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const Vec = pxl.util.Vec;
const LayerInstance = pxl.tilemap.LDtk.LayerInstance;

const fixed_dt: f32 = 1.0 / 60.0;

/// A single point mass with Verlet (implicit) velocity: velocity is `pos - prev`.
pub const Point = struct {
    pos: Vec2 = .zero,
    prev: Vec2 = .zero,
    pinned: bool = false,
    /// Radius used when drawing; 0 hides the point (pure chain segments).
    radius: f32 = 0,
    color: Color = Color.white,
};

/// Keeps two points at `target` distance. `stiffness` 1.0 is a hard projection
/// (each free node moves half the error per pass); lower values are a soft
/// spring that lets the pair stretch. Note that soft + strong gravity stretches
/// a chain far beyond its rest length, so chains default to hard (1.0) and the
/// wobble comes from the Verlet integration itself.
pub const Distance = struct {
    a: usize,
    b: usize,
    target: f32,
    stiffness: f32 = 1.0,
};

/// Keeps the angle at `pivot` between the vectors to `a` and `b` at `target`.
/// Combined with distance constraints a handful of nodes becomes a rigid body.
pub const Angle = struct {
    pivot: usize,
    a: usize,
    b: usize,
    target: f32,
    stiffness: f32 = 1.0,
};

/// Query: true when `pos` (world px) is inside solid geometry.
pub const SolidQuery = *const fn (Vec2) bool;

/// What a body collides against. Tilemaps are the default (`isSolidAt` per
/// axis, like the tilemap bodies); `custom` is an escape hatch for sandboxes
/// and non-tilemap scenes.
pub const Collision = union(enum) {
    tilemap: LayerInstance,
    custom: SolidQuery,
};

/// A generic verlet body: points, constraints, integration settings and a
/// lifecycle. Ropes are just chains built out of this (see `addChain`), debris
/// is loose points, rigid chunks are points + distance/angle constraints.
pub const Body = struct {
    points: Vec(Point) = .empty,
    accel: Vec(Vec2) = .empty,
    distances: Vec(Distance) = .empty,
    angles: Vec(Angle) = .empty,
    gravity: Vec2 = .zero,
    /// Velocity retained per fixed step (Lazr's 0.98 friction).
    damping: f32 = 0.98,
    /// Per-step displacement clamp; keeps a fast shove from tunnelling. This is
    /// a collision-safety limiter, not terminal velocity: 16 (the default) lets
    /// a 2200 px/s² fall accelerate for ~200px before it engages, so gravity
    /// reads as acceleration. Lower it below your thinnest collider / tile size
    /// if you see points skipping through walls.
    max_speed: f32 = 16.0,
    /// Constraint passes per fixed step. 1 for springy chains, 4-6 for stiff rigid bodies.
    iterations: u32 = 1,
    /// Constant external force per fixed step (wind, currents).
    wind: Vec2 = .zero,
    /// Comfy-style hook run once per fixed step after integration. Can move
    /// points directly or set `sleeping`/`dead`; null for the common case.
    on_update: ?*const fn (*Body, f32) void = null,
    /// Radius'd points push each other apart once per step (sandbox spheres,
    /// debris chunks). Ropes leave this off - their points have no radius.
    self_collide: bool = false,
    /// Become inert (stop simulating, keep drawing, wake on push) after this many seconds.
    sleep_delay: ?f32 = null,
    /// The owning world removes the body entirely after this many seconds.
    remove_delay: ?f32 = null,
    age: f32 = 0,
    sleeping: bool = false,
    dead: bool = false,
    accumulator: f32 = 0,

    pub fn len(self: *const Body) usize {
        return self.points.items.len;
    }

    pub fn deinit(self: *Body) void {
        self.points.deinit();
        self.accel.deinit();
        self.distances.deinit();
        self.angles.deinit();
    }

    /// Resets the body for reuse: drops every point/constraint and the timers.
    pub fn clear(self: *Body) void {
        self.points.clearRetainingCapacity();
        self.accel.clearRetainingCapacity();
        self.distances.clearRetainingCapacity();
        self.angles.clearRetainingCapacity();
        self.age = 0;
        self.sleeping = false;
        self.dead = false;
    }

    /// Adds a loose point with an initial velocity (px/s). Velocity is encoded
    /// as `prev = pos - vel * dt`, so a spawned point is already moving (this is
    /// how debris gets its burst). Points added this way draw as 2px circles.
    pub fn addPoint(self: *Body, pos: Vec2, vel: Vec2) usize {
        self.points.append(.{ .pos = pos, .prev = pos.sub(vel.scale(fixed_dt)), .radius = 2 });
        self.accel.append(.zero);
        return self.points.items.len - 1;
    }

    /// Adds `count` points spaced `spacing` apart along `dir` from `start`,
    /// joined by hard distance constraints (a rope, vine or grass blade). Chains
    /// hold their length under gravity; give the body a few `iterations` (4 is
    /// good for hanging ropes) so the length error stays small. Returns the
    /// index of the first point.
    pub fn addChain(self: *Body, start: Vec2, count: usize, spacing: f32, dir: Vec2, pin_head: bool, pin_tail: bool) usize {
        const first = self.points.items.len;
        var i: usize = 0;
        while (i < count) : (i += 1) {
            const pos = start.add(dir.scale(@as(f32, @floatFromInt(i)) * spacing));
            self.points.append(.{ .pos = pos, .prev = pos });
            self.accel.append(.zero);
        }
        var j: usize = 0;
        while (j + 1 < count) : (j += 1) {
            self.distances.append(.{ .a = first + j, .b = first + j + 1, .target = spacing, .stiffness = 1.0 });
        }
        if (pin_head) self.points.items[first].pinned = true;
        if (pin_tail) self.points.items[first + count - 1].pinned = true;
        return first;
    }

    /// Locks two existing points to their current distance (hard joint).
    pub fn addDistance(self: *Body, a: usize, b: usize) void {
        self.addDistanceTo(a, b, self.points.items[a].pos.sub(self.points.items[b].pos).len(), 1.0);
    }

    /// Locks two existing points to an explicit distance with a chosen stiffness.
    pub fn addDistanceTo(self: *Body, a: usize, b: usize, target: f32, stiffness: f32) void {
        self.distances.append(.{ .a = a, .b = b, .target = target, .stiffness = stiffness });
    }

    /// Locks the angle at `pivot` between the vectors to `a` and `b` to its
    /// current value (a rigid joint, like the verlet example's "fuse").
    pub fn addAngle(self: *Body, pivot: usize, a: usize, b: usize) void {
        const va = self.points.items[a].pos.sub(self.points.items[pivot].pos);
        const vb = self.points.items[b].pos.sub(self.points.items[pivot].pos);
        self.angles.append(.{
            .pivot = pivot,
            .a = a,
            .b = b,
            .target = std.math.atan2(va.y, va.x) - std.math.atan2(vb.y, vb.x),
        });
    }

    /// Pins a point in place (anchors, or re-attaching a cut rope).
    pub fn pin(self: *Body, i: usize, pos: Vec2) void {
        if (i >= self.points.items.len) return;
        self.points.items[i].pinned = true;
        self.points.items[i].pos = pos;
        self.points.items[i].prev = pos;
    }

    /// Releases a pinned point so it falls (cut ropes/vines).
    pub fn unpin(self: *Body, i: usize) void {
        if (i >= self.points.items.len) return;
        self.points.items[i].pinned = false;
    }

    /// Adds `impulse` to a single free point mass (swinging while climbing).
    pub fn push(self: *Body, i: usize, impulse: Vec2) void {
        if (i >= self.accel.items.len) return;
        if (self.points.items[i].pinned) return;
        self.wake();
        self.accel.items[i] = self.accel.items[i].add(impulse);
    }

    /// Adds `impulse` to every free point mass within `radius` of `pos`. This is
    /// the hook the hero and bullets use to shove ropes, grass and debris.
    pub fn pushNear(self: *Body, pos: Vec2, impulse: Vec2, radius: f32) void {
        var hit = false;
        for (self.points.items, self.accel.items) |p, *a| {
            if (p.pinned) continue;
            if (p.pos.sub(pos).len() <= radius) {
                a.* = a.add(impulse);
                hit = true;
            }
        }
        if (hit) self.wake();
    }

    /// The free point mass nearest to `pos` within `reach`, or null.
    pub fn grab(self: *const Body, pos: Vec2, reach: f32) ?usize {
        var best: ?usize = null;
        var best_d = reach;
        for (self.points.items, 0..) |p, i| {
            if (p.pinned) continue;
            const d = p.pos.sub(pos).len();
            if (d <= best_d) {
                best_d = d;
                best = i;
            }
        }
        return best;
    }

    /// Parametric position along the chain (in node-index units). Used to hang
    /// something from a smoothly interpolated point between two nodes.
    pub fn pointAt(self: *const Body, t: f32) Vec2 {
        const last = @as(f32, @floatFromInt(self.points.items.len - 1));
        const clamped = std.math.clamp(t, 0, last);
        const lo: usize = @intFromFloat(@floor(clamped));
        const hi: usize = @min(lo + 1, self.points.items.len - 1);
        const frac = clamped - @as(f32, @floatFromInt(lo));
        const a = self.points.items[lo].pos;
        const b = self.points.items[hi].pos;
        return a.add(b.sub(a).scale(frac));
    }

    /// The fastest point's speed (|pos - prev| per step). Useful for sleeping
    /// decisions and speed-brightened rendering.
    pub fn speed(self: *const Body) f32 {
        var max: f32 = 0;
        for (self.points.items) |p| {
            const s = p.pos.sub(p.prev).len();
            if (s > max) max = s;
        }
        return max;
    }

    /// Fixed-timestep simulation; safe to call with variable frame dt.
    pub fn update(self: *Body, dt: f32, collision: ?Collision) void {
        self.accumulator += dt;
        self.accumulator = @min(self.accumulator, fixed_dt * 4); // avoid a spiral of death
        while (self.accumulator >= fixed_dt) : (self.accumulator -= fixed_dt) {
            self.step(fixed_dt, collision);
            self.age += fixed_dt;
            if (self.remove_delay) |d| {
                if (self.age >= d) self.dead = true;
            }
        }
    }

    fn step(self: *Body, dt: f32, collision: ?Collision) void {
        if (self.sleep_delay) |d| {
            if (!self.sleeping and self.age >= d) self.sleeping = true;
        }
        if (self.sleeping) return;

        var iter: u32 = 0;
        while (iter < self.iterations) : (iter += 1) {
            self.solveDistances();
            self.solveAngles();
        }

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
            const spd = @sqrt(vx * vx + vy * vy);
            if (spd > self.max_speed) {
                const s = self.max_speed / spd;
                vx *= s;
                vy *= s;
            }
            vx *= self.damping;
            vy *= self.damping;

            const nx = p.pos.x + vx + a.x + self.wind.x + self.gravity.x * dt * dt;
            const ny = p.pos.y + vy + a.y + self.wind.y + self.gravity.y * dt * dt;
            self.accel.items[i] = .zero;

            var ok_x = true;
            var ok_y = true;
            if (collision) |c| {
                const ok = axisOk(c, .init(nx, ny), p.pos, p.radius);
                ok_x = ok[0];
                ok_y = ok[1];
            }

            p.prev = p.pos;
            if (ok_x) p.pos.x = nx;
            if (ok_y) p.pos.y = ny;
        }

        if (self.self_collide) {
            self.solveSelfCollisions();
            // Self-collision shoves points directly (bypassing the integration
            // check), so a pile can push a sphere into/through the floor. Clamp
            // any axis that ended up in solid back to the last checked position.
            if (collision) |c| self.clampCollisions(c);
        }
        if (self.on_update) |hook| hook(self, dt);
    }

    /// Per-axis solidity of `target` for a point whose orthogonal axis is still
    /// at `pos`. A radius'd point collides with its full extent (pos +- r), so
    /// chunks rest ON the floor instead of sinking to their center.
    fn axisOk(collision: Collision, target: Vec2, pos: Vec2, radius: f32) [2]bool {
        switch (collision) {
            .tilemap => |layer| {
                if (radius > 0) {
                    return .{
                        !pxl.tilemap.isSolidAt(layer, .init(target.x - radius, pos.y)) and !pxl.tilemap.isSolidAt(layer, .init(target.x + radius, pos.y)),
                        !pxl.tilemap.isSolidAt(layer, .init(pos.x, target.y - radius)) and !pxl.tilemap.isSolidAt(layer, .init(pos.x, target.y + radius)),
                    };
                }
                return .{ !pxl.tilemap.isSolidAt(layer, .init(target.x, pos.y)), !pxl.tilemap.isSolidAt(layer, .init(pos.x, target.y)) };
            },
            .custom => |q| {
                if (radius > 0) {
                    return .{
                        !q(.init(target.x - radius, pos.y)) and !q(.init(target.x + radius, pos.y)),
                        !q(.init(pos.x, target.y - radius)) and !q(.init(pos.x, target.y + radius)),
                    };
                }
                return .{ !q(.init(target.x, pos.y)), !q(.init(pos.x, target.y)) };
            },
        }
    }

    /// Reverts any axis that self-collision pushed into solid back to the last
    /// collision-checked position (`prev`), per axis, like the integration step.
    fn clampCollisions(self: *Body, collision: Collision) void {
        for (self.points.items) |*p| {
            if (p.pinned) continue;
            const ok = axisOk(collision, p.pos, p.prev, p.radius);
            if (!ok[0]) p.pos.x = p.prev.x;
            if (!ok[1]) p.pos.y = p.prev.y;
        }
    }

    /// Pushes every overlapping pair of radius'd points apart so they just
    /// touch. Pinned points stay put and shove the free one the full way.
    fn solveSelfCollisions(self: *Body) void {
        const pts = self.points.items;
        var i: usize = 0;
        while (i < pts.len) : (i += 1) {
            var j: usize = i + 1;
            while (j < pts.len) : (j += 1) {
                if (pts[i].radius == 0 or pts[j].radius == 0) continue;
                const a = &pts[i];
                const b = &pts[j];
                const diff = b.pos.sub(a.pos);
                const dist = diff.len();
                const min_dist = a.radius + b.radius;
                if (dist >= min_dist) continue;

                const dir = if (dist > 1e-6) diff.scale(1.0 / dist) else Vec2.x_axis;
                const sep = dir.scale((min_dist - dist) * 0.5);
                if (!a.pinned) a.pos = a.pos.sub(sep);
                if (!b.pinned) b.pos = b.pos.add(sep);
            }
        }
    }

    /// Soft (stiffness < 1) or hard (1.0) distance projection: each free node
    /// moves by half the error scaled by stiffness, `iterations` times.
    fn solveDistances(self: *Body) void {
        for (self.distances.items) |d| {
            const a = &self.points.items[d.a];
            const b = &self.points.items[d.b];
            if (a.pinned and b.pinned) continue;
            const diff = b.pos.sub(a.pos);
            const dist = diff.len();
            if (dist < 1e-6) continue;
            const amt = (d.target - dist) / dist * d.stiffness * 0.5;
            if (!a.pinned) a.pos = a.pos.sub(diff.scale(amt));
            if (!b.pinned) b.pos = b.pos.add(diff.scale(amt));
        }
    }

    /// Rotates the two outer nodes around `pivot` by half the angular error each
    /// (stiffness-scaled, opposite directions) so the pivot stays put and the
    /// angle converges.
    fn solveAngles(self: *Body) void {
        for (self.angles.items) |c| {
            const va = self.points.items[c.a].pos.sub(self.points.items[c.pivot].pos);
            const vb = self.points.items[c.b].pos.sub(self.points.items[c.pivot].pos);
            const la = va.len();
            const lb = vb.len();
            if (la < 1e-6 or lb < 1e-6) continue;

            const current = std.math.atan2(va.y, va.x) - std.math.atan2(vb.y, vb.x);
            var delta = current - c.target;
            while (delta > std.math.pi) delta -= std.math.tau;
            while (delta < -std.math.pi) delta += std.math.tau;

            const half = delta * 0.5 * c.stiffness;
            const cos_h = @cos(half);
            const sin_h = @sin(half);
            const ra = Vec2.init(va.x * cos_h + va.y * sin_h, -va.x * sin_h + va.y * cos_h);
            const rb = Vec2.init(vb.x * cos_h - vb.y * sin_h, vb.x * sin_h + vb.y * cos_h);

            const pivot = self.points.items[c.pivot].pos;
            if (!self.points.items[c.a].pinned) self.points.items[c.a].pos = pivot.add(ra);
            if (!self.points.items[c.b].pinned) self.points.items[c.b].pos = pivot.add(rb);
        }
    }

    fn wake(self: *Body) void {
        if (self.sleeping) {
            self.sleeping = false;
            self.age = 0;
        }
    }

    /// Draws distance segments plus a circle per visible point. With `color`
    /// null each point draws in its own color (brightened by speed); otherwise
    /// everything uses the given color (uniform ropes).
    pub fn draw(self: *const Body, color: ?Color) void {
        for (self.distances.items) |d| {
            const a = self.points.items[d.a];
            const b = self.points.items[d.b];
            pxl.api.drawLine(a.pos, b.pos, 2, color orelse a.color);
        }
        for (self.points.items) |p| {
            if (p.radius <= 0) continue;
            pxl.api.drawCircle(p.pos, p.radius, 16, color orelse brighten(p));
        }
    }
};

/// Brightens a point's color with how fast it's moving (verlet example flair).
fn brighten(p: Point) Color {
    const speed_t = std.math.clamp(p.pos.sub(p.prev).len() / (p.radius * 2.0), 0.0, 1.0);
    const base = p.color.asArray();
    return Color.fromRgba(
        base[0] + (1.0 - base[0]) * speed_t * 0.45,
        base[1] + (1.0 - base[1]) * speed_t * 0.45,
        base[2] + (1.0 - base[2]) * speed_t * 0.45,
        1.0,
    );
}

/// The point (body, index) nearest `pos`, for grabbing something to interact with.
pub const Grab = struct { body: usize, point: usize };

/// Owns a set of verlet bodies, shares their collision source, and sweeps away
/// dead ones. This is the "fun visuals" adjunct to pxl's manual body physics:
/// ropes to climb, debris that bursts and settles, vines swaying in the wind.
pub const World = struct {
    bodies: Vec(Body) = .empty,
    /// Default gravity applied to bodies spawned after this is set.
    gravity: Vec2 = .init(0, 2200),
    collision: ?Collision = null,

    pub fn deinit(self: *World) void {
        for (self.bodies.items) |*b| b.deinit();
        self.bodies.deinit();
    }

    /// Collide every body against an LDtk IntGrid layer (the default path).
    pub fn setCollisionLayer(self: *World, layer: LayerInstance) void {
        self.collision = .{ .tilemap = layer };
    }

    /// Escape hatch for non-tilemap scenes: a point-solidity query.
    pub fn setCollisionFn(self: *World, q: SolidQuery) void {
        self.collision = .{ .custom = q };
    }

    pub fn clearCollision(self: *World) void {
        self.collision = null;
    }

    /// Adds an empty body inheriting `gravity`; returns its index.
    pub fn addBody(self: *World) ?usize {
        self.bodies.append(.{ .gravity = self.gravity });
        return self.bodies.items.len - 1;
    }

    /// Hangs a chain down from `anchor` with soft distance links. `pin_tail`
    /// false pins the top (a hanging rope); true pins the bottom (grass/vine
    /// rooted at the ground — pass the blade tip as `anchor`). Returns the body
    /// index; the free end gets a small endcap dot.
    pub fn addRope(self: *World, anchor: Vec2, segments: usize, spacing: f32, pin_tail: bool) ?usize {
        const idx = self.addBody() orelse return null;
        const body = &self.bodies.items[idx];
        // Hard links + a few iterations keep a hanging rope near its rest
        // length under gravity (soft links stretch 2-5x and look broken).
        body.iterations = 4;
        _ = body.addChain(anchor, segments, spacing, .init(0, 1), !pin_tail, pin_tail);
        const end: usize = if (pin_tail) 0 else segments - 1;
        body.points.items[end].radius = 2;
        return idx;
    }

    /// Spawns `count` loose chunks at `pos` bursting outward along `dir` (the
    /// impact push direction: away from the wall for a side hit, downward for a
    /// ceiling hit), within `spread` radians of it, at up to `speed` px/s.
    /// A zero `dir` bursts upward (the historical default). Each chunk is nudged
    /// along `dir` until its radius fully clears solid geometry, so debris is
    /// never born inside a wall/ceiling (where the collision check would freeze
    /// it in place). Points draw as small circles; set `sleep_delay` /
    /// `remove_delay` on the returned body for settle-then-vanish behavior.
    pub fn addDebris(self: *World, pos: Vec2, dir: Vec2, count: usize, speed: f32, spread: f32) ?usize {
        const idx = self.addBody() orelse return null;
        const body = &self.bodies.items[idx];
        const dir_len = dir.len();
        const dir_n = if (dir_len > 1e-6) dir.scale(1.0 / dir_len) else Vec2.init(0, -1);
        const dir_ang = if (dir_len > 1e-6) std.math.atan2(dir.y, dir.x) else -std.math.pi / 2.0;
        var i: usize = 0;
        while (i < count) : (i += 1) {
            const ang = dir_ang + pxl.math.rand.range(f32, -spread, spread);
            const spd = pxl.math.rand.range(f32, speed * 0.2, speed);
            const vel = Vec2.init(@cos(ang) * spd, @sin(ang) * spd);
            const pi = body.addPoint(pos, vel);
            body.points.items[pi].radius = pxl.math.rand.range(f32, 1.5, 3.5);
            if (self.collision) |c| pushOutOfSolid(body, pi, dir_n, c);
        }
        return idx;
    }

    /// True when `pos` (ignoring radius) sits inside solid geometry.
    fn centerSolid(collision: Collision, pos: Vec2) bool {
        return switch (collision) {
            .tilemap => |layer| pxl.tilemap.isSolidAt(layer, pos),
            .custom => |q| q(pos),
        };
    }

    /// True when the point's radius box (center + 4 cardinal extent points) is
    /// fully in free space — the condition for it to be able to move at all.
    fn fullyFree(collision: Collision, pos: Vec2, radius: f32) bool {
        if (centerSolid(collision, pos)) return false;
        return switch (collision) {
            .tilemap => |layer|
                !pxl.tilemap.isSolidAt(layer, .init(pos.x - radius, pos.y)) and
                !pxl.tilemap.isSolidAt(layer, .init(pos.x + radius, pos.y)) and
                !pxl.tilemap.isSolidAt(layer, .init(pos.x, pos.y - radius)) and
                !pxl.tilemap.isSolidAt(layer, .init(pos.x, pos.y + radius)),
            .custom => |q|
                !q(.init(pos.x - radius, pos.y)) and
                !q(.init(pos.x + radius, pos.y)) and
                !q(.init(pos.x, pos.y - radius)) and
                !q(.init(pos.x, pos.y + radius)),
        };
    }

    /// Moves point `pi` along `dir` until its radius fully clears solid geometry
    /// (capped), preserving its spawn velocity. Fast projectiles stop up to a
    /// step inside the surface, so impact debris spawns buried in it.
    fn pushOutOfSolid(body: *Body, pi: usize, dir: Vec2, collision: Collision) void {
        const p = &body.points.items[pi];
        const r = p.radius;
        if (r <= 0) return;
        var k: f32 = 0;
        while (k < 32.0) : (k += 1) {
            const candidate = p.pos.add(dir.scale(k));
            if (fullyFree(collision, candidate, r)) {
                const disp = candidate.sub(p.pos);
                p.pos = candidate;
                p.prev = p.prev.add(disp); // keep the spawn velocity intact
                return;
            }
        }
    }

    /// Removes a body (frees its storage). Indices into `bodies` are unstable
    /// while bodies are removed; grab fresh ones each frame.
    pub fn removeBody(self: *World, i: usize) void {
        if (i >= self.bodies.items.len) return;
        self.bodies.items[i].deinit();
        _ = self.bodies.swapRemove(i);
    }

    /// Steps every body on the fixed timestep, then drops the dead ones.
    pub fn update(self: *World, dt: f32) void {
        var i: usize = 0;
        while (i < self.bodies.items.len) {
            const body = &self.bodies.items[i];
            body.update(dt, self.collision);
            if (body.dead) {
                self.removeBody(i);
            } else {
                i += 1;
            }
        }
    }

    /// Pushes every body within `radius` of `pos` (hero shoving grass, bullets
    /// plowing debris). Wakes sleeping bodies.
    pub fn pushNear(self: *World, pos: Vec2, impulse: Vec2, radius: f32) void {
        for (self.bodies.items) |*b| b.pushNear(pos, impulse, radius);
    }

    /// The nearest free point to `pos` across all bodies within `reach`.
    pub fn grab(self: *const World, pos: Vec2, reach: f32) ?Grab {
        var best: ?Grab = null;
        var best_d = reach;
        for (self.bodies.items, 0..) |*b, bi| {
            if (b.grab(pos, best_d)) |pi| {
                const d = b.points.items[pi].pos.sub(pos).len();
                if (d <= best_d) {
                    best_d = d;
                    best = .{ .body = bi, .point = pi };
                }
            }
        }
        return best;
    }

    /// Draws every body; see `Body.draw` for the color semantics.
    pub fn draw(self: *const World, color: ?Color) void {
        for (self.bodies.items) |*b| b.draw(color);
    }
};

test "distance constraint holds two free points at target distance" {
    pxl.mem.init();
    defer pxl.mem.deinit();
    var b: Body = .{ .iterations = 4 };
    const a = b.addPoint(.init(0, 0), .zero);
    const c = b.addPoint(.init(10, 0), .zero);
    b.addDistanceTo(a, c, 5, 1.0);

    var i: usize = 0;
    while (i < 300) : (i += 1) b.update(fixed_dt, null);
    try std.testing.expectApproxEqAbs(@as(f32, 5.0), b.points.items[a].pos.sub(b.points.items[c].pos).len(), 0.05);
    b.deinit();
}

test "angle constraint holds a three-point joint" {
    pxl.mem.init();
    defer pxl.mem.deinit();
    var b: Body = .{ .iterations = 8 };
    const pivot = b.addPoint(.init(0, 0), .zero);
    const a = b.addPoint(.init(10, 0), .zero);
    const c = b.addPoint(.init(0, 10), .zero);
    b.addAngle(pivot, a, c);

    var i: usize = 0;
    while (i < 300) : (i += 1) b.update(fixed_dt, null);
    const va = b.points.items[a].pos.sub(b.points.items[pivot].pos);
    const vb = b.points.items[c].pos.sub(b.points.items[pivot].pos);
    const angle = std.math.atan2(va.y, va.x) - std.math.atan2(vb.y, vb.x);
    try std.testing.expectApproxEqAbs(-std.math.pi / 2.0, angle, 0.05);
    b.deinit();
}

test "sleep delay makes a body inert, push wakes it" {
    pxl.mem.init();
    defer pxl.mem.deinit();
    var b: Body = .{ .sleep_delay = 0.5 };
    _ = b.addPoint(.init(0, 0), .zero);

    var i: usize = 0;
    while (i < 60) : (i += 1) b.update(fixed_dt, null);
    try std.testing.expect(b.sleeping);

    const before = b.points.items[0].pos;
    b.update(fixed_dt, null); // sleeping: no movement, no age growth
    try std.testing.expectEqual(before, b.points.items[0].pos);

    b.push(0, .init(5, 0));
    try std.testing.expect(!b.sleeping);
    try std.testing.expectEqual(@as(f32, 0), b.age);
    b.deinit();
}

test "world sweeps bodies whose remove delay elapsed" {
    pxl.mem.init();
    defer pxl.mem.deinit();
    var w: World = .{};
    _ = w.addBody() orelse unreachable;
    _ = w.addBody() orelse unreachable;
    w.bodies.items[0].remove_delay = 0.1;
    _ = w.bodies.items[0].addPoint(.init(0, 0), .zero);

    var i: usize = 0;
    while (i < 30) : (i += 1) w.update(fixed_dt);
    try std.testing.expectEqual(@as(usize, 1), w.bodies.items.len);
    w.deinit();
}

test "addPoint encodes initial velocity in prev" {
    pxl.mem.init();
    defer pxl.mem.deinit();
    var b: Body = .{};
    _ = b.addPoint(.init(0, 0), .init(120, 0)); // 120 px/s -> 2 px per fixed step
    try std.testing.expectApproxEqAbs(@as(f32, 2.0), b.points.items[0].pos.x - b.points.items[0].prev.x, 0.001);
    b.deinit();
}

test "pointAt interpolates between nodes" {
    pxl.mem.init();
    defer pxl.mem.deinit();
    var b: Body = .{};
    _ = b.addPoint(.init(0, 0), .zero);
    _ = b.addPoint(.init(10, 0), .zero);
    const mid = b.pointAt(0.5);
    try std.testing.expectApproxEqAbs(@as(f32, 5.0), mid.x, 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), mid.y, 0.001);
    b.deinit();
}

test "hanging rope holds near its rest length under gravity" {
    pxl.mem.init();
    defer pxl.mem.deinit();
    var w: World = .{};
    const ri = w.addRope(.init(0, 0), 18, 8, false) orelse unreachable;
    // floor at y=240 via a custom query: nothing below is solid
    w.collision = .{ .custom = &solidBelow240 };

    var i: usize = 0;
    while (i < 720) : (i += 1) w.update(fixed_dt); // 12s, well past settling

    const body = &w.bodies.items[ri];
    var len: f32 = 0;
    var j: usize = 1;
    while (j < body.points.items.len) : (j += 1) {
        len += body.points.items[j].pos.sub(body.points.items[j - 1].pos).len();
    }
    // Natural length is 144; allow generous sag but nowhere near the 2-5x blowup.
    try std.testing.expect(len < 144 * 1.35);
    // The free end rests on the floor, it must not hang below it.
    try std.testing.expect(body.points.items[body.points.items.len - 1].pos.y <= 240 + 0.5);
    w.deinit();
}

fn solidBelow240(pos: Vec2) bool {
    return pos.y > 240;
}

test "radius'd point rests above the floor, not sunk to its center" {
    pxl.mem.init();
    defer pxl.mem.deinit();
    var b: Body = .{ .gravity = .init(0, 2200) };
    _ = b.addPoint(.init(50, 60), .zero);
    b.points.items[0].radius = 8;

    var i: usize = 0;
    while (i < 240) : (i += 1) b.update(fixed_dt, .{ .custom = &solidBelow100 });
    try std.testing.expectApproxEqAbs(@as(f32, 100 - 8), b.points.items[0].pos.y, 0.5);
    b.deinit();
}

fn solidBelow100(pos: Vec2) bool {
    return pos.y > 100;
}

test "self-collision pushes overlapping radius'd points apart" {
    pxl.mem.init();
    defer pxl.mem.deinit();
    var b: Body = .{ .self_collide = true };
    const a = b.addPoint(.init(0, 0), .zero);
    const c = b.addPoint(.init(4, 0), .zero); // 4px apart, radii 3+3 -> overlap 2px
    b.points.items[a].radius = 3;
    b.points.items[c].radius = 3;
    b.update(fixed_dt, null);

    const dist = b.points.items[a].pos.sub(b.points.items[c].pos).len();
    try std.testing.expectApproxEqAbs(@as(f32, 6.0), dist, 0.01);
    b.deinit();
}

test "addDebris emits along the requested direction" {
    pxl.mem.init();
    defer pxl.mem.deinit();
    var w: World = .{};

    // Bullet moving right hits a wall: burst must spray left, away from it.
    const left = w.addDebris(.init(0, 0), .init(-1, 0), 8, 100, 0.2) orelse unreachable;
    for (w.bodies.items[left].points.items) |p| {
        const vel = p.pos.sub(p.prev);
        try std.testing.expect(vel.x < 0);
    }

    // Bullet hits the ceiling: burst must spray downward.
    const down = w.addDebris(.init(0, 0), .init(0, 1), 8, 100, 0.2) orelse unreachable;
    for (w.bodies.items[down].points.items) |p| {
        const vel = p.pos.sub(p.prev);
        try std.testing.expect(vel.y > 0);
    }
    w.deinit();
}

test "debris spawned inside a ceiling is pushed out, not frozen" {
    pxl.mem.init();
    defer pxl.mem.deinit();
    var w: World = .{};
    w.setCollisionFn(solidAbove16); // solid above y=16 (a ceiling)

    // Spawn a downward burst at y=10, well inside the ceiling tile.
    const bi = w.addDebris(.init(50, 10), .init(0, 1), 6, 100, 0.05) orelse unreachable;
    for (w.bodies.items[bi].points.items) |p| {
        // Every chunk must spawn with its full radius clear of the ceiling.
        try std.testing.expect(p.pos.y >= 16.0 + p.radius);
    }

    // And they must fall out, not freeze in place.
    var i: usize = 0;
    while (i < 60) : (i += 1) w.update(fixed_dt);
    for (w.bodies.items[bi].points.items) |p| try std.testing.expect(p.pos.y > 16.0);
    w.deinit();
}

fn solidAbove16(pos: Vec2) bool {
    return pos.y < 16;
}

test "self-collision can't push a point through the floor" {
    pxl.mem.init();
    defer pxl.mem.deinit();
    var b: Body = .{ .gravity = .init(0, 2200), .self_collide = true };
    // Three radius'd spheres stacked vertically on a floor at y=100. The bottom
    // one rests at 92 (100 - radius); overlapping pile pressure must never sink
    // any sphere below the floor line.
    const a = b.addPoint(.init(50, 90), .zero);
    const c = b.addPoint(.init(50, 70), .zero);
    const d = b.addPoint(.init(50, 50), .zero);
    for (b.points.items) |*p| p.radius = 8;

    var i: usize = 0;
    while (i < 240) : (i += 1) b.update(fixed_dt, .{ .custom = &solidBelow100 });
    // The floor-touching sphere rests on the floor; the ones above sit a few px
    // lower than the ideal stack height (verlet piles compress under their own
    // weight). The invariant that matters: nothing sinks below the floor line.
    try std.testing.expect(b.points.items[a].pos.y <= 92.5);
    try std.testing.expect(b.points.items[c].pos.y <= 80.0);
    try std.testing.expect(b.points.items[d].pos.y <= 64.0);
    for (b.points.items) |p| try std.testing.expect(p.pos.y <= 100.0);
    b.deinit();
}
