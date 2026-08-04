const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;
const Vec = pxl.util.Vec;
const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const rand = pxl.math.rand;

const max_objects = 350;
const max_constraints = 1500;
const max_colliders = 8;

/// The basic Verlet sphere. Notice there is *no* velocity field - velocity is
/// simply derived from the difference between `current` and `previous`.
/// To control the velocity you manipulate one of the two positions directly.
/// This mirrors the article's `VerletObject` (previousPosition, currentPosition, radius).
const VerletObject = struct {
    current: Vec2,
    previous: Vec2,
    radius: f32,
    color: Color,
    is_static: bool = false,
};

/// A distance constraint keeps two objects at a constant distance. Chaining
/// several of them together produces ropes/cloth - the "assemble other
/// structures from spheres" trick from the article.
const DistanceConstraint = struct {
    a: usize,
    b: usize,
    target_distance: f32,
    color: Color,
};

/// An angle constraint keeps the angle at `pivot` between the vectors to `a`
/// and `b` fixed. Combined with distance constraints this lets a handful of
/// nodes form rigid bodies (triangles, etc.) - the article's "fuse 2+ nodes
/// together" idea.
const AngleConstraint = struct {
    pivot: usize,
    a: usize,
    b: usize,
    target_angle: f32,
    color: Color,
};

/// An axis-aligned box collider represented as a *signed distance field* (SDF).
/// The SDF returns the distance to the closest surface (negative when inside),
/// and its gradient is the surface normal used to push objects back outside.
/// SDF source: https://iquilezles.org/articles/distfunctions2d/
const BoxCollider = struct {
    center: Vec2,
    half_size: Vec2,

    fn sdf(self: *const BoxCollider, p: Vec2) f32 {
        const q = Vec2.init(@abs(p.x - self.center.x) - self.half_size.x, @abs(p.y - self.center.y) - self.half_size.y);
        const ox = @max(q.x, 0);
        const oy = @max(q.y, 0);
        const outside = @sqrt(ox * ox + oy * oy);
        const inside = @min(@max(q.x, q.y), 0);
        return outside + inside;
    }

    /// The closest point on the box boundary to `p`. The push-out direction is
    /// simply (p - closest), which always points toward the surface the sphere
    /// is overlapping - unlike the raw SDF gradient which can point *away* from
    /// the box for points just outside its face.
    fn closestPoint(self: *const BoxCollider, p: Vec2) Vec2 {
        return Vec2.init(
            std.math.clamp(p.x, self.center.x - self.half_size.x, self.center.x + self.half_size.x),
            std.math.clamp(p.y, self.center.y - self.half_size.y, self.center.y + self.half_size.y),
        );
    }

    /// Surface normal pointing out of the box, used to slide an overlapping
    /// sphere to the nearest point outside the collider.
    fn normal(self: *const BoxCollider, p: Vec2) Vec2 {
        const cp = self.closestPoint(p);
        const d = p.sub(cp);
        const d_len = d.len();
        if (d_len > 1e-6) return d.scale(1.0 / d_len);

        // Center is inside the box: exit through the face we are closest to.
        // q holds the per-axis distance to the far faces (negative when inside).
        const q = Vec2.init(
            @abs(p.x - self.center.x) - self.half_size.x,
            @abs(p.y - self.center.y) - self.half_size.y,
        );
        if (q.y > q.x) return Vec2.init(0, signf(p.y - self.center.y));
        return Vec2.init(signf(p.x - self.center.x), 0);
    }
};

fn signf(v: f32) f32 {
    return if (v >= 0) 1.0 else -1.0;
}

/// The solver implements the article's 4-step simulation frame:
///   1) Velocity integration
///   2) Dynamic collisions (body vs body)
///   3) Constraints (optional, iterative)
///   4) Static collisions (body vs world)
const VerletSolver = struct {
    objects: Vec(VerletObject),
    constraints: Vec(DistanceConstraint),
    angle_constraints: Vec(AngleConstraint),
    colliders: Vec(BoxCollider),
    gravity: Vec2,
    constraint_iterations: u32 = 6,

    fn init(gravity: Vec2) VerletSolver {
        var s: VerletSolver = .{
            .objects = .empty,
            .constraints = .empty,
            .angle_constraints = .empty,
            .colliders = .empty,
            .gravity = gravity,
        };
        s.objects.ensureTotalCapacity(max_objects);
        s.constraints.ensureTotalCapacity(max_constraints);
        s.angle_constraints.ensureTotalCapacity(max_constraints);
        s.colliders.ensureTotalCapacity(max_colliders);
        return s;
    }

    fn deinit(self: *VerletSolver) void {
        self.objects.deinit();
        self.constraints.deinit();
        self.angle_constraints.deinit();
        self.colliders.deinit();
    }

    fn clearObjects(self: *VerletSolver) void {
        self.objects.clearRetainingCapacity();
        self.constraints.clearRetainingCapacity();
        self.angle_constraints.clearRetainingCapacity();
    }

    fn simulate(self: *VerletSolver, dt: f32) void {
        // 1) Velocity integration: velocity is implicit in (current - previous).
        for (self.objects.items) |*obj| {
            if (obj.is_static) continue;

            const velocity = obj.current.sub(obj.previous);
            obj.previous = obj.current; // remember where we were this tick
            // Move by velocity, then apply gravity. Note the dt*dt.
            obj.current = obj.current.add(velocity).add(self.gravity.scale(dt * dt));

            // Clamp the per-tick displacement so a fast sphere can never jump
            // past a collider's centerline and come out the far side. The bound
            // is smaller than the thinnest collider half-thickness.
            const displacement = obj.current.sub(obj.previous);
            const disp_len = displacement.len();
            if (disp_len > max_move_per_tick) {
                obj.current = obj.previous.add(displacement.scale(max_move_per_tick / disp_len));
            }
        }

        // 2) Dynamic collisions: check every pair, push them apart so they just touch.
        self.solveDynamicCollisions();

        // 3) Constraints: keep rope distances and joint angles fixed. Run several
        //    iterations so the corrections propagate for stable, stiff structures.
        var iter: u32 = 0;
        while (iter < self.constraint_iterations) : (iter += 1) {
            self.solveConstraints();
            self.solveAngleConstraints();
        }

        // 4) Static collisions: push overlapping objects out of every box collider.
        self.solveStaticCollisions();
    }

    fn solveDynamicCollisions(self: *VerletSolver) void {
        const objs = self.objects.items;
        var i: usize = 0;
        while (i < objs.len) : (i += 1) {
            var j: usize = i + 1;
            while (j < objs.len) : (j += 1) {
                const a = &objs[i];
                const b = &objs[j];
                if (a.is_static and b.is_static) continue;

                const diff = b.current.sub(a.current);
                const dist = diff.len();
                const min_dist = a.radius + b.radius;
                if (dist >= min_dist) continue;

                // Perfectly overlapping spheres get shoved sideways to break the tie.
                const dir = if (dist > 1e-6) diff.scale(1.0 / dist) else Vec2.x_axis;
                const push = dir.scale((min_dist - dist) * 0.5);
                if (!a.is_static) a.current = a.current.sub(push);
                if (!b.is_static) b.current = b.current.add(push);
            }
        }
    }

    fn solveConstraints(self: *VerletSolver) void {
        for (self.constraints.items) |constraint| {
            const a = &self.objects.items[constraint.a];
            const b = &self.objects.items[constraint.b];
            if (a.is_static and b.is_static) continue;

            const diff = b.current.sub(a.current);
            const dist = diff.len();
            if (dist < 1e-6) continue;

            // Move each object halfway back to the target distance.
            const offset = diff.scale((dist - constraint.target_distance) / dist * 0.5);
            if (!a.is_static) a.current = a.current.add(offset);
            if (!b.is_static) b.current = b.current.sub(offset);
        }
    }

    /// Keeps the angle at `pivot` between the vectors to `a` and `b` at the
    /// constraint's target. The two outer nodes are rotated around the pivot by
    /// half the angular error each (in opposite directions) so the pivot stays put.
    fn solveAngleConstraints(self: *VerletSolver) void {
        for (self.angle_constraints.items) |constraint| {
            const pivot = &self.objects.items[constraint.pivot];
            const a = &self.objects.items[constraint.a];
            const b = &self.objects.items[constraint.b];

            const va = a.current.sub(pivot.current);
            const vb = b.current.sub(pivot.current);
            const la = va.len();
            const lb = vb.len();
            if (la < 1e-6 or lb < 1e-6) continue;

            const current_angle = std.math.atan2(va.y, va.x) - std.math.atan2(vb.y, vb.x);
            var delta = current_angle - constraint.target_angle;
            while (delta > std.math.pi) delta -= std.math.tau;
            while (delta < -std.math.pi) delta += std.math.tau;

            const half = delta * 0.5;
            const c = @cos(half);
            const s = @sin(half);
            // Rotate a by -half and b by +half around the pivot.
            const ra = Vec2.init(va.x * c + va.y * s, -va.x * s + va.y * c);
            const rb = Vec2.init(vb.x * c - vb.y * s, vb.x * s + vb.y * c);

            if (!a.is_static) a.current = pivot.current.add(ra);
            if (!b.is_static) b.current = pivot.current.add(rb);
        }
    }

    fn solveStaticCollisions(self: *VerletSolver) void {
        for (self.objects.items) |*obj| {
            if (obj.is_static) continue;
            for (self.colliders.items) |*collider| {
                const dist = collider.sdf(obj.current);
                if (dist < obj.radius) {
                    const n = collider.normal(obj.current);
                    obj.current = obj.current.add(n.scale(obj.radius - dist));

                    // Velocity is implicitly (current - previous), so after
                    // pushing the object out of the collider we also fix
                    // `previous` to cancel the velocity component pushing INTO
                    // the surface. Without this the object re-penetrates every
                    // tick and slowly sinks through the collider.
                    const velocity = obj.current.sub(obj.previous);
                    const vn = velocity.dot(n);
                    if (vn < 0) {
                        obj.previous = obj.current.sub(velocity.sub(n.scale(vn)));
                    }
                }
            }
        }
    }

    fn addObject(self: *VerletSolver, position: Vec2, radius: f32, color: Color) ?usize {
        if (self.objects.items.len >= max_objects) return null;
        self.objects.append(.{
            .current = position,
            .previous = position,
            .radius = radius,
            .color = color,
        });
        return self.objects.items.len - 1;
    }

    /// Spawn a hanging rope: a chain of spheres pinned at the top and joined by
    /// distance constraints - the article's "build structures from spheres" idea.
    fn addRope(self: *VerletSolver, anchor: Vec2, segment_count: usize, spacing: f32, radius: f32, color: Color) void {
        var prev: ?usize = null;
        var i: usize = 0;
        while (i < segment_count) : (i += 1) {
            const pos = anchor.add(Vec2.init(0, @as(f32, @floatFromInt(i)) * spacing));
            const index = self.addObject(pos, radius, color) orelse return;
            if (i == 0) self.objects.items[index].is_static = true; // pin the top of the rope

            if (prev) |p| {
                if (self.constraints.items.len < max_constraints) {
                    self.constraints.append(.{
                        .a = p,
                        .b = index,
                        .target_distance = spacing,
                        .color = color,
                    });
                }
            }
            prev = index;
        }
    }

    fn draw(self: *VerletSolver) void {
        // Box colliders
        for (self.colliders.items) |collider| {
            const min = collider.center.sub(collider.half_size);
            api.drawRectOutline(min, collider.half_size.scale(2), 2, Color.fromRgb(0.32, 0.38, 0.5));
        }

        // Constraints (rope segments)
        for (self.constraints.items) |constraint| {
            const a = self.objects.items[constraint.a].current;
            const b = self.objects.items[constraint.b].current;
            api.drawLine(a, b, 2, constraint.color);
        }

        // Objects: brighten the fill with the current speed (velocity is just
        // (current - previous)), like the article's debug gizmos with flair.
        for (self.objects.items) |obj| {
            const velocity = obj.current.sub(obj.previous);
            const speed_t = std.math.clamp(velocity.len() / (obj.radius * 2.0), 0.0, 1.0);
            const base = obj.color.asArray();
            const hot = Color.fromRgba(
                base[0] + (1.0 - base[0]) * speed_t * 0.45,
                base[1] + (1.0 - base[1]) * speed_t * 0.45,
                base[2] + (1.0 - base[2]) * speed_t * 0.45,
                1.0,
            );
            api.drawCircle(obj.current, obj.radius, 16, hot);
            api.drawCircleOutline(obj.current, obj.radius, 1.5, 16, Color.fromRgba(0, 0, 0, 0.35));
        }

        // Highlight the node currently being grabbed with shift+drag.
        if (drag_index) |idx| {
            if (idx < self.objects.items.len) {
                const grabbed = self.objects.items[idx];
                api.drawCircleOutline(grabbed.current, grabbed.radius + 4, 2, 16, Color.white);
            }
        }

        // Highlight the chain of nodes selected for fusing with the F key.
        var fi: usize = 0;
        while (fi < fuse_count) : (fi += 1) {
            const idx = fuse_nodes[fi];
            if (idx < self.objects.items.len) {
                const n = self.objects.items[idx];
                const ring_col = if (fi == 0) Color.gold else Color.sky_blue;
                api.drawCircleOutline(n.current, n.radius + 6, 2, 16, ring_col);
            }
        }
    }
};

var solver: VerletSolver = undefined;
var accumulator: f32 = 0;
var paused: bool = false;
var color_index: usize = 0;
const fixed_dt: f32 = 1.0 / 60.0;
/// Max displacement per physics tick. Must stay below the thinnest collider
/// half-thickness (ledges are 18) so spheres can never tunnel through.
const max_move_per_tick: f32 = 16.0;
/// Extra padding around a sphere's radius used to pick it up with shift+drag.
const grab_margin: f32 = 8.0;

/// Index of the node currently being dragged with shift+left button, if any.
var drag_index: ?usize = null;
var last_drag_mouse: Vec2 = Vec2.zero;

/// Chain of node indices being fused together with the F key. Each new node
/// gets a distance constraint to the previous one, and once there are 3+ nodes
/// an angle constraint locks the joint at the middle node - building rigid
/// structures (triangles, etc.) from a handful of nodes, per the article.
const max_fuse_nodes = 8;
var fuse_nodes: [max_fuse_nodes]usize = undefined;
var fuse_count: usize = 0;

/// Finds the node under `mouse` (within radius + grab_margin), or null.
fn pickNode(mouse: Vec2) ?usize {
    var best: ?usize = null;
    var best_dist: f32 = std.math.floatMax(f32);
    for (solver.objects.items, 0..) |obj, i| {
        const d = obj.current.sub(mouse).len();
        if (d <= obj.radius + grab_margin and d < best_dist) {
            best_dist = d;
            best = i;
        }
    }
    return best;
}

const palette = [_]Color{
    Color.sky_blue,
    Color.gold,
    Color.pink,
    Color.green,
    Color.purple,
    Color.orange,
    Color.fromRgb(0.25, 0.8, 1.0),
    Color.fromRgb(1.0, 0.45, 0.25),
};

fn nextColor() Color {
    const c = palette[color_index % palette.len];
    color_index += 1;
    return c;
}

pub fn config() pxl.Config {
    return .{
        .gfx = .{
            .clear_color = Color.fromBytes(10, 12, 18, 255),
        },
    };
}

pub fn setup() !void {
    const w = pxl.gpu.renderWidthf();
    const h = pxl.gpu.renderHeightf();

    solver = VerletSolver.init(.init(0, 2200));

    // World colliders: thick screen bounds plus two interior ledges. The
    // boundary colliders are kept much thicker than max_move_per_tick so a
    // fast sphere can never cross their centerline in a single tick.
    solver.colliders.append(.{ .center = .init(w * 0.5, h + 40), .half_size = .init(w * 0.5 + 24, 40) }); // floor
    solver.colliders.append(.{ .center = .init(w * 0.5, -40), .half_size = .init(w * 0.5 + 24, 40) }); // ceiling
    solver.colliders.append(.{ .center = .init(-20, h * 0.5), .half_size = .init(24, h * 0.5 + 40) }); // left wall
    solver.colliders.append(.{ .center = .init(w + 20, h * 0.5), .half_size = .init(24, h * 0.5 + 40) }); // right wall
    solver.colliders.append(.{ .center = .init(w * 0.25, h * 0.62), .half_size = .init(150, 18) });
    solver.colliders.append(.{ .center = .init(w * 0.75, h * 0.4), .half_size = .init(160, 18) });

    // A little opening scene: a rope pinned to the ceiling plus a sphere shower.
    solver.addRope(.init(w * 0.85, 40), 16, 24, 8, Color.gold);
    var i: u32 = 0;
    while (i < 18) : (i += 1) {
        _ = solver.addObject(
            .init(rand.range(f32, 80, w - 80), rand.range(f32, 80, h * 0.4)),
            rand.range(f32, 7.0, 13.0),
            nextColor(),
        );
    }
}

pub fn shutdown() !void {
    solver.deinit();
}

pub fn update() !void {
    const w = pxl.gpu.renderWidthf();
    const h = pxl.gpu.renderHeightf();

    if (pxl.input.keyPressed(.space)) {
        var i: u32 = 0;
        while (i < 24) : (i += 1) {
            _ = solver.addObject(
                .init(rand.range(f32, 80, w - 80), rand.range(f32, 80, h * 0.45)),
                rand.range(f32, 6.0, 14.0),
                nextColor(),
            );
        }
    }

    if (pxl.input.keyPressed(.c)) {
        solver.clearObjects();
        drag_index = null;
        fuse_count = 0;
    }

    if (pxl.input.keyPressed(.p)) paused = !paused;

    const mouse = pxl.input.mousePos();
    const shift_held = pxl.input.keyDown(.left_shift) or pxl.input.keyDown(.right_shift);

    // Fuse nodes: press F on a node to add it to the chain. Consecutive nodes
    // get a distance constraint; once 3+ nodes are chained, an angle constraint
    // locks the joint at the middle node so the structure stays rigid. Press F
    // on empty space (or X) to clear the selection.
    if (pxl.input.keyPressed(.f)) {
        if (pickNode(mouse)) |idx| {
            if (fuse_count == 0 or fuse_nodes[fuse_count - 1] != idx) {
                if (fuse_count < max_fuse_nodes) {
                    if (fuse_count > 0) {
                        const prev = fuse_nodes[fuse_count - 1];
                        const a = solver.objects.items[prev];
                        const b = solver.objects.items[idx];
                        const dist = a.current.sub(b.current).len();
                        if (solver.constraints.items.len < max_constraints) {
                            solver.constraints.append(.{
                                .a = prev,
                                .b = idx,
                                .target_distance = dist,
                                .color = Color.fromRgb(0.6, 0.8, 1.0),
                            });
                        }
                        // With 3+ nodes, lock the angle at the previous node
                        // between the node before it and the new node.
                        if (fuse_count >= 2) {
                            const pivot = prev;
                            const a_idx = fuse_nodes[fuse_count - 2];
                            const va = solver.objects.items[a_idx].current.sub(solver.objects.items[pivot].current);
                            const vb = solver.objects.items[idx].current.sub(solver.objects.items[pivot].current);
                            const target_angle = std.math.atan2(va.y, va.x) - std.math.atan2(vb.y, vb.x);
                            if (solver.angle_constraints.items.len < max_constraints) {
                                solver.angle_constraints.append(.{
                                    .pivot = pivot,
                                    .a = a_idx,
                                    .b = idx,
                                    .target_angle = target_angle,
                                    .color = Color.fromRgb(1.0, 0.6, 0.4),
                                });
                            }
                        }
                    }
                    fuse_nodes[fuse_count] = idx;
                    fuse_count += 1;
                }
            }
        } else {
            fuse_count = 0;
        }
    }

    if (pxl.input.keyPressed(.x)) fuse_count = 0;

    if (pxl.input.mousePressed(.left) and !shift_held) {
        _ = solver.addObject(mouse, rand.range(f32, 6.0, 14.0), nextColor());
    }

    if (pxl.input.mousePressed(.right)) {
        solver.addRope(mouse, 16, 18, 9, nextColor());
        std.debug.print("rope\n", .{});
    }

    // Fixed-timestep simulation so the verlet integration is stable regardless
    // of the display's frame rate.
    if (!paused) {
        accumulator += pxl.time.dt();
        accumulator = @min(accumulator, fixed_dt * 4); // avoid a spiral of death
        while (accumulator >= fixed_dt) : (accumulator -= fixed_dt) {
            solver.simulate(fixed_dt);
        }
    }

    // Shift+left-click drags the node under the mouse. On the press frame we
    // grab the nearest sphere whose (radius + grab_margin) covers the cursor.
    if (pxl.input.mouseDown(.left) and shift_held) {
        if (drag_index == null) {
            var best: ?usize = null;
            var best_dist: f32 = std.math.floatMax(f32);
            for (solver.objects.items, 0..) |obj, i| {
                const d = obj.current.sub(mouse).len();
                if (d <= obj.radius + grab_margin and d < best_dist) {
                    best_dist = d;
                    best = i;
                }
            }
            drag_index = best;
            last_drag_mouse = mouse;
        }
    } else {
        drag_index = null;
    }

    // Glue the grabbed node to the cursor. The mouse's per-frame motion is fed
    // back into the verlet state (via `previous`) so releasing gives the node
    // a natural "throw" instead of a dead drop.
    if (drag_index) |idx| {
        if (shift_held and pxl.input.mouseDown(.left) and idx < solver.objects.items.len) {
            const obj = &solver.objects.items[idx];
            const mouse_delta = mouse.sub(last_drag_mouse);
            obj.current = mouse;
            obj.previous = mouse.sub(mouse_delta);
            last_drag_mouse = mouse;
        } else {
            drag_index = null;
        }
    }
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = Color.fromBytes(10, 12, 18, 255) });

    const w = pxl.gpu.renderWidthf();
    const h = pxl.gpu.renderHeightf();

    // Faint grid
    var x: f32 = 0;
    while (x <= w) : (x += 32) {
        api.drawLine(.init(x, 0), .init(x, h), 1, Color.fromRgba(0.13, 0.15, 0.21, 1));
    }
    var y: f32 = 0;
    while (y <= h) : (y += 32) {
        api.drawLine(.init(0, y), .init(w, y), 1, Color.fromRgba(0.13, 0.15, 0.21, 1));
    }

    solver.draw();

    const hud = if (paused) "Verlet solver: LMB sphere, SHIFT+LMB drag, RMB rope, F fuse, X clear fuse, SPACE burst, C clear, P pause [PAUSED]" else "Verlet solver: LMB sphere, SHIFT+LMB drag, RMB rope, F fuse, X clear fuse, SPACE burst, C clear, P pause";
    api.drawText(null, .init(12, 12), hud, Color.light_gray);

    pxl.endPass();
}
