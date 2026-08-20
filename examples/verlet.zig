const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;
const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const rand = pxl.math.rand;
const verlet = pxl.physics.verlet;

/// A verlet sandbox built on `pxl.physics.verlet`:
///   LMB            add a sphere to the scene body
///   SHIFT+LMB      drag the nearest point (world-wide grab)
///   RMB            hang a soft rope
///   F              fuse points: distance links, then angle joints for 3+
///   X              clear the fuse selection
///   SPACE          debris burst with sleep + remove lifecycle
///   C              clear the scene body
///   P              pause
var world: verlet.World = .{};
/// The persistent body holding all loose spheres and fuse constraints.
var scene: usize = 0;
var paused: bool = false;
var color_index: usize = 0;

/// Extra padding around a point's radius used to pick it up with shift+drag.
const grab_margin: f32 = 8.0;
var drag: ?verlet.Grab = null;
var last_drag_mouse: Vec2 = Vec2.zero;

/// Chain of node indices being fused together with the F key. Each new node
/// gets a distance constraint to the previous one, and once there are 3+ nodes
/// an angle constraint locks the joint at the middle node — building rigid
/// structures (triangles, etc.) from a handful of nodes.
const max_fuse_nodes = 8;
var fuse_nodes: [max_fuse_nodes]usize = undefined;
var fuse_count: usize = 0;

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

/// Sandbox collision: the screen bounds as a point query (no tilemap here).
fn solidAt(pos: Vec2) bool {
    const w = pxl.gpu.renderWidthf();
    const h = pxl.gpu.renderHeightf();
    return pos.y > h or pos.y < 0 or pos.x < 0 or pos.x > w;
}

/// Finds the node under `mouse` (within radius + grab_margin) in `body`, or null.
fn pickNode(body: *const verlet.Body, mouse: Vec2) ?usize {
    var best: ?usize = null;
    var best_dist: f32 = std.math.floatMax(f32);
    for (body.points.items, 0..) |p, i| {
        const d = p.pos.sub(mouse).len();
        if (d <= p.radius + grab_margin and d < best_dist) {
            best_dist = d;
            best = i;
        }
    }
    return best;
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

    world = .{};
    world.setCollisionFn(solidAt);

    // A rope pinned to the ceiling plus a sphere shower into the scene body.
    _ = world.addRope(.init(w * 0.85, 40), 16, 24, false);
    scene = world.addBody() orelse unreachable;
    const s = &world.bodies.items[scene];
    s.self_collide = true; // spheres bounce off each other
    var i: u32 = 0;
    while (i < 18) : (i += 1) {
        const pi = s.addPoint(.init(rand.range(f32, 80, w - 80), rand.range(f32, 80, h * 0.4)), .zero);
        s.points.items[pi].radius = rand.range(f32, 7.0, 13.0);
        s.points.items[pi].color = nextColor();
    }
}

pub fn shutdown() !void {
    world.deinit();
}

pub fn update() !void {
    const mouse = pxl.input.mousePos();
    const shift_held = pxl.input.keyDown(.left_shift) or pxl.input.keyDown(.right_shift);

    if (pxl.input.keyPressed(.space)) {
        if (world.addDebris(mouse, .init(0, -1), 24, 160, std.math.pi)) |bi| {
            const body = &world.bodies.items[bi];
            body.self_collide = true; // chunks bump each other as they burst
            body.sleep_delay = 2.0; // settle and go inert after 2s
            body.remove_delay = 5.0; // then vanish entirely
            for (body.points.items) |*p| p.color = nextColor();
        }
    }

    if (pxl.input.keyPressed(.c)) {
        world.bodies.items[scene].clear();
        drag = null;
        fuse_count = 0;
    }

    if (pxl.input.keyPressed(.p)) paused = !paused;

    // Fuse nodes: press F on a node to add it to the chain. Consecutive nodes
    // get a distance constraint; once 3+ nodes are chained, an angle constraint
    // locks the joint at the middle node so the structure stays rigid. Press F
    // on empty space (or X) to clear the selection.
    if (pxl.input.keyPressed(.f)) {
        const s = &world.bodies.items[scene];
        if (pickNode(s, mouse)) |idx| {
            if (fuse_count == 0 or fuse_nodes[fuse_count - 1] != idx) {
                if (fuse_count < max_fuse_nodes) {
                    if (fuse_count > 0) {
                        const prev = fuse_nodes[fuse_count - 1];
                        s.addDistance(prev, idx);
                        // With 3+ nodes, lock the angle at the previous node
                        // between the node before it and the new node.
                        if (fuse_count >= 2) {
                            const pivot = prev;
                            s.addAngle(pivot, fuse_nodes[fuse_count - 2], idx);
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
        const s = &world.bodies.items[scene];
        const pi = s.addPoint(mouse, .zero);
        s.points.items[pi].radius = rand.range(f32, 6.0, 14.0);
        s.points.items[pi].color = nextColor();
    }

    if (pxl.input.mousePressed(.right)) {
        _ = world.addRope(mouse, 16, 18, false);
    }

    if (!paused) world.update(pxl.time.dt());

    // SHIFT+left-click drags the point under the cursor (across any body).
    if (pxl.input.mouseDown(.left) and shift_held) {
        if (drag == null) {
            drag = world.grab(mouse, 24);
            last_drag_mouse = mouse;
        }
    } else {
        drag = null;
    }

    // Glue the grabbed point to the cursor. The mouse's per-frame motion is fed
    // back into the verlet state (via `previous`) so releasing gives the point
    // a natural "throw" instead of a dead drop.
    if (drag) |d| {
        if (shift_held and pxl.input.mouseDown(.left)) {
            const obj = &world.bodies.items[d.body].points.items[d.point];
            const mouse_delta = mouse.sub(last_drag_mouse);
            obj.pos = mouse;
            obj.prev = mouse.sub(mouse_delta);
            last_drag_mouse = mouse;
        } else {
            drag = null;
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

    // Bodies draw themselves: rope segments, speed-brightened points, debris.
    world.draw(null);

    // Highlight the point currently being dragged.
    if (drag) |d| {
        const p = world.bodies.items[d.body].points.items[d.point];
        api.drawCircleOutline(p.pos, p.radius + 4, 2, 16, Color.white);
    }

    // Highlight the chain of nodes selected for fusing with the F key.
    const s = &world.bodies.items[scene];
    var fi: usize = 0;
    while (fi < fuse_count) : (fi += 1) {
        const idx = fuse_nodes[fi];
        if (idx < s.points.items.len) {
            const n = s.points.items[idx];
            const ring_col = if (fi == 0) Color.gold else Color.sky_blue;
            api.drawCircleOutline(n.pos, n.radius + 6, 2, 16, ring_col);
        }
    }

    const hud = if (paused) "Verlet: LMB sphere, SHIFT+LMB drag, RMB rope, F fuse, X clear fuse, SPACE debris, C clear, P pause [PAUSED]" else "Verlet: LMB sphere, SHIFT+LMB drag, RMB rope, F fuse, X clear fuse, SPACE debris, C clear, P pause";
    api.drawText(null, .init(12, 12), hud, Color.light_gray);

    pxl.endPass();
}
