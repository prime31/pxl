// Slugcat — a Rain World inspired procedural creature.
//
// Based on the `ldtk` example (same map + camera + microui scaffolding), but
// the blocky tilemap player is replaced by a slugcat whose movement and body
// animation are ports of Rain World's systems:
//
//   * Player.cs          — two body chunks (gravity, tile collision, run speed,
//                          jump/canJump, flipDirection, run-cycle animationFrame)
//   * BodyPart.cs        — verlet-ish parts (pos/lastPos/vel + ConnectToPoint
//                          elastic spring to a host point)
//   * TailSegment.cs     — a verlet rope chain with split distance constraints
//   * Limb.cs            — damped "hunt" chasing used to drive the limbs
//   * PlayerGraphics.cs  — drawPositions smoothing, run bob, legs/arms/tail layering
//
// The body is two chunky circles (like the game): standing still the slugcat
// rises upright on its hind legs (almost two tiles tall), running it drops to
// a horizontal all-fours pose (one tile tall). The two legs are solved with
// analytic two-bone IK and plant their feet on the tilemap's solid cells; the
// two arms are FABRIK chains. Everything is drawn with `pxl.api` shapes and
// inspected with `pxl.dbg` lines (toggle with the window / F1).

const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;
const mu = pxl.mu;
const input = pxl.input;

const LDtk = pxl.tilemap.LDtk;
const Texture = pxl.gpu.Texture;
const Rect = pxl.math.Rect;
const Color = pxl.math.Color;
const Vec2 = pxl.math.Vec2;
const CollisionState = pxl.tilemap.CollisionState;
const moveBody = pxl.tilemap.moveBody;

// ---------------------------------------------------------------------------
// Tuning. Rain World steps its simulation at 60 Hz with px/frame units; pxl
// runs at real dt, so the constants below are Rain World's values x60 (px/s).
// ---------------------------------------------------------------------------
const gravity: f32 = 3240; // 0.9 px/frame^2 (Player.cs: base.gravity = 0.9)
const run_speed: f32 = 258; // 4.3 px/frame
const jump_speed: f32 = 340; // ~7 px/frame impulse (Player.cs Jump())
const jump_hop: f32 = 90; // 1.5 px/frame forward hop on a grounded jump (RW num5)
const jump_boost_rate: f32 = 750; // (jumpBoost+1) * 0.3 px/frame^2 while holding (RW)
const jump_boost_decay: f32 = 90; // 1.5 boost units per frame
const max_fall: f32 = 960; // 16 px/frame terminal fall speed
const ground_accel_rate: f32 = 25; // vel.x lerp ~0.34/frame on the ground
const air_accel_rate: f32 = 9.5; // vel.x lerp ~0.15/frame in the air
const ground_friction_rate: f32 = 12; // idle deceleration while grounded
const tile_size: f32 = 12; // collision IntGrid tile size in px

var map: LDtk = undefined;
var textures: std.AutoHashMap(i64, Texture) = undefined;
var collision: LDtk.LayerInstance = undefined; // IntGrid layer used for collision
var map_w: f32 = 264;
var map_h: f32 = 264;

var camera: pxl.Camera = .{ .position = .init(140, 190), .zoom = 2.0, .rotation = 0 };
var follow_cam: bool = true;
var show_debug: bool = true;
var slugcat: Slugcat = .{};

// ---------------------------------------------------------------------------
// Small vector helpers (Rain World's Custom.* equivalents)
// ---------------------------------------------------------------------------
fn clampf(v: f32, lo: f32, hi: f32) f32 {
    return std.math.clamp(v, lo, hi);
}

fn lerpf(a: f32, b: f32, t: f32) f32 {
    return a + (b - a) * t;
}

fn lerpVec(a: Vec2, b: Vec2, t: f32) Vec2 {
    return a.add(b.sub(a).scale(t));
}

fn dirVec(a: Vec2, b: Vec2) Vec2 {
    return b.sub(a).norm();
}

fn rotate2D(v: Vec2, ang: f32) Vec2 {
    const c = @cos(ang);
    const s = @sin(ang);
    return .init(v.x * c - v.y * s, v.x * s + v.y * c);
}

/// Is the tilemap cell solid?
fn cellSolid(tx: i32, ty: i32) bool {
    if (tx < 0 or ty < 0 or tx >= collision.width() or ty >= collision.height()) return false;
    return collision.isCellSolid(@intCast(tx), @intCast(ty));
}

/// Is the world-space point inside a solid IntGrid cell?
fn solidAt(w: Vec2) bool {
    const gi: i32 = @intFromFloat(tile_size);
    const tx = @divFloor(@as(i32, @intFromFloat(@floor(w.x))), gi);
    const ty = @divFloor(@as(i32, @intFromFloat(@floor(w.y))), gi);
    return cellSolid(tx, ty);
}

/// Tail segments collide with the tilemap (RW's BodyPart.PushOutOfTerrain,
/// simplified): a segment whose centre is inside a solid cell is pushed out
/// through the nearest free cell edge, and its velocity into the wall is
/// killed so it drags along the ground instead of pressing into it.
fn pushPartOutOfTerrain(p: *Part) void {
    if (!solidAt(p.pos)) return;
    const gi: i32 = @intFromFloat(tile_size);
    const tx = @divFloor(@as(i32, @intFromFloat(@floor(p.pos.x))), gi);
    const ty = @divFloor(@as(i32, @intFromFloat(@floor(p.pos.y))), gi);
    const cell_x = @as(f32, @floatFromInt(tx)) * tile_size;
    const cell_y = @as(f32, @floatFromInt(ty)) * tile_size;
    const fx = p.pos.x - cell_x;
    const fy = p.pos.y - cell_y;

    var best: f32 = 1e9;
    var out = p.pos;
    var pushed_x: bool = false;
    // Push the segment's centre a full radius past the cell edge so the tail
    // visibly rests on the floor instead of sinking halfway into it.
    if (!cellSolid(tx - 1, ty) and fx + p.rad < best) {
        best = fx + p.rad;
        out.x = cell_x - p.rad;
        pushed_x = true;
    }
    if (!cellSolid(tx + 1, ty) and tile_size - fx + p.rad < best) {
        best = tile_size - fx + p.rad;
        out.x = cell_x + tile_size + p.rad;
        pushed_x = true;
    }
    if (!cellSolid(tx, ty - 1) and fy + p.rad < best) {
        best = fy + p.rad;
        out.y = cell_y - p.rad;
        pushed_x = false;
    }
    if (!cellSolid(tx, ty + 1) and tile_size - fy + p.rad < best) {
        best = tile_size - fy + p.rad;
        out.y = cell_y + tile_size + p.rad;
        pushed_x = false;
    }
    p.pos = out;
    if (pushed_x) {
        p.vel.x = 0;
    } else {
        p.vel.y = 0;
    }
}

/// Would a chunk of size `w`x`h` centered at `c` overlap any solid cell?
/// The bottom ~2.5px strip is ignored: resting chunks legitimately sit a
/// pixel or two into the floor, and the pose constraint must not fight that.
fn rectOverlapsSolid(c: Vec2, w: f32, h: f32) bool {
    var y = c.y - h / 2 + 1;
    while (y <= c.y + h / 2 - 2.5) : (y += 4) {
        var x = c.x - w / 2 + 1;
        while (x <= c.x + w / 2 - 1) : (x += 4) {
            if (solidAt(.init(x, y))) return true;
        }
    }
    return false;
}

/// Returns the surface point (top of the first solid tile) directly below
/// `start`, or null when there is no ground within `max_dist`.
fn groundBelow(start: Vec2, max_dist: f32) ?Vec2 {
    var y = start.y + 1;
    while (y - start.y <= max_dist) : (y += 2) {
        if (solidAt(.init(start.x, y))) {
            const ty = @divFloor(@as(i32, @intFromFloat(@floor(y))), @as(i32, @intFromFloat(tile_size)));
            return .init(start.x, @as(f32, @floatFromInt(ty)) * tile_size);
        }
    }
    return null;
}

// ---------------------------------------------------------------------------
// Chunk — Rain World's BodyChunk simplified: a rect that moves through the
// tilemap with gravity, resolved by pxl's swept collision (moveBody).
// ---------------------------------------------------------------------------
const Chunk = struct {
    rect: Rect = .{},
    state: CollisionState = .{ .pixel_perfect = false },
    vel: Vec2 = .zero,

    fn init(self: *Chunk, center: Vec2, size: Vec2) void {
        self.rect = .{ .x = center.x - size.x / 2, .y = center.y - size.y / 2, .w = size.x, .h = size.y };
        self.state = .{ .pixel_perfect = false };
        self.vel = .zero;
    }

    fn setCenter(self: *Chunk, c: Vec2) void {
        self.rect.x = c.x - self.rect.w / 2;
        self.rect.y = c.y - self.rect.h / 2;
    }

    fn update(self: *Chunk, m: *LDtk, dt: f32) void {
        self.vel.y += gravity * dt;
        moveBody(m, &self.rect, &self.state, self.vel);
        // Kill the velocity into a contact so bodies don't press into terrain
        // (a resting chunk otherwise accumulates gravity forever).
        if (self.state.above and self.vel.y < 0) self.vel.y = 0;
        if (self.state.below and self.vel.y > 0) self.vel.y = 0;
        if (self.state.left and self.vel.x < 0) self.vel.x = 0;
        if (self.state.right and self.vel.x > 0) self.vel.x = 0;

        // Keep the chunk inside the collision layer bounds.
        if (self.rect.x < 0) {
            self.rect.x = 0;
            if (self.vel.x < 0) self.vel.x = 0;
        }
        if (self.rect.right() > map_w) {
            self.rect.x = map_w - self.rect.w;
            if (self.vel.x > 0) self.vel.x = 0;
        }
        if (self.rect.y < 0) {
            self.rect.y = 0;
            if (self.vel.y < 0) self.vel.y = 0;
        }
        if (self.rect.bottom() > map_h) {
            self.rect.y = map_h - self.rect.h;
            if (self.vel.y > 0) self.vel.y = 0;
        }
    }
};

// ---------------------------------------------------------------------------
// Part — Rain World's BodyPart: a verlet-ish point (pos/lastPos/vel) that can
// be elastically attached to a host point (ConnectToPoint).
// ---------------------------------------------------------------------------
const Part = struct {
    pos: Vec2 = .zero,
    last_pos: Vec2 = .zero,
    vel: Vec2 = .zero,
    rad: f32 = 4,
    air_friction: f32 = 0.9,

    fn update(self: *Part, grav: f32, dt: f32) void {
        self.last_pos = self.pos;
        self.pos = self.pos.add(self.vel.scale(dt));
        self.vel = self.vel.scale(std.math.pow(f32, self.air_friction, 60.0 * dt));
        self.vel.y += grav * dt;
    }

    /// Port of BodyPart.ConnectToPoint: an elastic pull toward `pnt`, a hard
    /// connection radius, and host-velocity adaptation so the part trails or
    /// anticipates the chunk it hangs from.
    fn connectToPoint(
        self: *Part,
        pnt: Vec2,
        connection_rad: f32,
        elastic: f32,
        host_vel: Vec2,
        adapt_vel: f32,
        exaggerate_vel: f32,
    ) void {
        const d = pnt.sub(self.pos);
        const dist = d.len();
        if (elastic > 0 and dist > 1e-4) {
            self.vel = self.vel.add(d.norm().scale(dist * elastic * 60.0 * pxl.time.dt()));
        }
        self.vel = self.vel.add(host_vel.scale(exaggerate_vel));
        if (dist > connection_rad and dist > 1e-4) {
            const corr = d.norm().scale(connection_rad - dist);
            self.pos = self.pos.sub(corr);
            self.vel = self.vel.sub(corr);
        }
        self.vel = self.vel.sub(host_vel);
        self.vel = self.vel.scale(1.0 - adapt_vel);
        self.vel = self.vel.add(host_vel);
    }
};

// ---------------------------------------------------------------------------
// Leg — a two-bone IK leg that plants its foot on the tilemap. The foot chases
// a ground target; once planted it stays put until the hip walks more than
// `max_step` away, then the leg lifts and takes a new step. The knee is solved
// analytically (law of cosines) and bends toward the direction of travel.
// ---------------------------------------------------------------------------
const Leg = struct {
    foot: Vec2 = .zero,
    target: Vec2 = .zero,
    knee: Vec2 = .zero,
    planted: bool = false,
    dangling: bool = false, // true while airborne: target is a mid-air dangle point
    front: bool = true,
    thigh: f32 = 9,
    shin: f32 = 9,

    const max_step: f32 = 13;
    const chase_rate: f32 = 60; // swing snap speed

    fn update(self: *Leg, hip: Vec2, flip: f32, grounded: bool, moving: bool, dt: f32) void {
        if (grounded) {
            if (!self.planted) {
                if (self.dangling) {
                    // Just landed: aim at the ground ahead of the hip instead
                    // of the mid-air dangle point.
                    self.dangling = false;
                    const stride: f32 = if (moving) 11 else 7;
                    const fwd = if (self.front) flip * stride else -flip * (stride - 4);
                    const desired = hip.add(.init(fwd, 0));
                    self.target = groundBelow(desired, 90) orelse desired.add(.init(0, 8));
                }
            } else if (hip.sub(self.foot).len() > max_step) {
                // The body outran this foot (running, crawling, or walking
                // after a turn-around): lift it and step forward. The release
                // is distance-based, not gated on speed — gating it on the
                // `moving` flag left feet planted far behind the body while
                // the slugcat crawled slowly, stretching the legs into long
                // broken strands (and the debug target lines with them).
                self.planted = false;
                self.dangling = false;
                const fwd = if (self.front) flip * 11 else -flip * 7;
                const desired = hip.add(.init(fwd, 0));
                self.target = groundBelow(desired, 90) orelse desired.add(.init(0, 9));
            }
        } else {
            // Airborne: dangle the foot below the body.
            self.planted = false;
            self.dangling = true;
            const dir: f32 = if (self.front) 7 else -5;
            self.target = hip.add(.init(flip * dir, 6));
        }

        // Chase the target — shared by the grounded swing and the airborne
        // dangle. A swinging foot chasing a target that is re-aimed every
        // frame at the running hip can never catch it, so grounded targets
        // are fixed at release time. The airborne foot must keep chasing too:
        // when the chase lived only in the grounded branch, airborne feet
        // froze at the takeoff spot and the legs stretched to twice their
        // length while the body rose.
        if (!self.planted) {
            const blend = 1.0 - std.math.exp(-chase_rate * dt);
            self.foot = lerpVec(self.foot, self.target, blend);
            if (grounded and self.foot.sub(self.target).len() < 1.5) {
                self.foot = self.target;
                self.planted = true;
            }
        }

        self.knee = solveKnee(hip, self.foot, self.thigh, self.shin, flip);
    }
};

fn solveKnee(hip: Vec2, foot: Vec2, l1: f32, l2: f32, flip: f32) Vec2 {
    const d = foot.sub(hip);
    const dist = d.len();
    // When the foot is almost on top of the hip (dangling right under the
    // body), the law-of-cosines solution degenerates into a ~90 degree knee.
    // Give it a natural forward-down bend instead.
    if (dist < 3) {
        return hip.add(.init(flip * (l1 * 0.55), l1 * 0.45));
    }
    const cl = std.math.clamp(dist, @abs(l1 - l2) + 0.5, l1 + l2 - 0.5);
    const cos_a = clampf((l1 * l1 + cl * cl - l2 * l2) / (2 * l1 * cl), -1, 1);
    const a = std.math.acos(cos_a);
    // Rotate hip->foot by -a*flip so the knee pokes toward the nose.
    return hip.add(rotate2D(d.norm(), -a * flip).scale(l1));
}

// ---------------------------------------------------------------------------
// Arm — a FABRIK chain (shoulder, elbow, hand) reaching for a target that
// swings with the run cycle (Rain World's Limb "hunt" behaviour, simplified).
// ---------------------------------------------------------------------------
const Arm = struct {
    nodes: [3]Vec2 = .{ .zero, .zero, .zero },
    seg: [2]f32 = .{ 8, 7 },
    front: bool = true,

    fn solve(self: *Arm, shoulder: Vec2, target: Vec2, iterations: u32) void {
        self.nodes[0] = shoulder;
        var iter: u32 = 0;
        while (iter < iterations) : (iter += 1) {
            // Backward pass: pin the hand to the target and walk to the shoulder.
            self.nodes[2] = target;
            var i: usize = 2;
            while (i > 0) : (i -= 1) {
                const d = self.nodes[i - 1].sub(self.nodes[i]);
                if (d.len() < 1e-4) continue;
                self.nodes[i - 1] = self.nodes[i].add(d.norm().scale(self.seg[i - 1]));
            }
            // Forward pass: pin the shoulder back and walk to the hand.
            self.nodes[0] = shoulder;
            var j: usize = 1;
            while (j < 3) : (j += 1) {
                const d = self.nodes[j].sub(self.nodes[j - 1]);
                if (d.len() < 1e-4) continue;
                self.nodes[j] = self.nodes[j - 1].add(d.norm().scale(self.seg[j - 1]));
            }
        }
    }

    fn hand(self: *const Arm) Vec2 {
        return self.nodes[2];
    }
};

// ---------------------------------------------------------------------------
// Slugcat — the creature itself.
// ---------------------------------------------------------------------------
const Slugcat = struct {
    chunks: [2]Chunk = .{ .{}, .{} }, // [0] = upper/main body, [1] = lower body
    rest_dist: f32 = 16, // BodyChunkConnection distance (RW: 17 at 20px tiles)
    can_jump: i32 = 0,
    jump_boost: f32 = 0, // holding jump lifts further while this lasts (RW)
    flip: f32 = 1, // which way the slugcat faces
    anim_frame: i32 = 0, // run-cycle frame, 0..6 (Rain World's animationFrame)
    left_foot: bool = false,
    grounded: bool = false,
    was_grounded: bool = false,
    speed: f32 = 0, // |vel.x| for the HUD
    squash: f32 = 0, // landing squash, decays to 0
    stand_blend: f32 = 0, // 1 = upright on hind legs, 0 = on all fours

    head: Part = .{ .rad = 4.2 },
    tail: [4]TailSeg = undefined,
    legs: [2]Leg = undefined,
    arms: [2]Arm = undefined,

    // Derived pose state (also used by the debug overlay).
    upper_draw: Vec2 = .zero,
    lower_draw: Vec2 = .zero,
    head_anchor: Vec2 = .zero,
    leg_hip: [2]Vec2 = .{ .zero, .zero },
    arm_shoulder: [2]Vec2 = .{ .zero, .zero },
    arm_target: [2]Vec2 = .{ .zero, .zero },
    look_dir: Vec2 = .zero,

    const TailSeg = struct {
        part: Part = .{ .air_friction = 1.0 },
        connection_rad: f32,
        affect_previous: f32,
        stretched: f32 = 1,
    };

    fn init(self: *Slugcat, spawn: Vec2) void {
        self.* = .{};
        self.chunks[0].init(spawn, .init(11, 11));
        self.chunks[1].init(.init(spawn.x - 15, spawn.y + 2), .init(10, 10));

        // Tail segments: (radius, connectionRad, affectPrevious) from
        // PlayerGraphics.cs — a verlet rope rooted at the lower body chunk.
        const specs = [_][3]f32{
            .{ 5, 5, 1.0 },
            .{ 3.5, 6, 0.5 },
            .{ 2, 7, 0.5 },
            .{ 1, 7, 0.5 },
        };
        for (0..4) |l| {
            self.tail[l] = .{ .connection_rad = specs[l][1], .affect_previous = specs[l][2] };
            self.tail[l].part.rad = specs[l][0];
            self.tail[l].part.pos = .init(spawn.x - 17, spawn.y + 7 + @as(f32, @floatFromInt(l)) * 5);
        }

        self.legs[0] = .{ .front = true, .foot = .init(spawn.x - 12, spawn.y + 8), .target = .init(spawn.x - 12, spawn.y + 8) };
        self.legs[1] = .{ .front = false, .foot = .init(spawn.x - 18, spawn.y + 8), .target = .init(spawn.x - 18, spawn.y + 8) };
        self.arms[0] = .{ .front = true };
        self.arms[1] = .{ .front = false };
        self.head.pos = .init(spawn.x + 5, spawn.y - 6);
    }

    /// Is there enough headroom above the lower chunk to stand up? Used to
    /// stop the slugcat rising upright under a low ceiling — instead it stays
    /// crouched on all fours (Rain World drops to Default mode when the room
    /// is too short to Stand).
    fn standingFits(self: *const Slugcat) bool {
        const c1 = self.chunks[1].rect.center();
        return !rectOverlapsSolid(
            c1.add(.init(0, -self.rest_dist)),
            self.chunks[0].rect.w,
            self.chunks[0].rect.h,
        );
    }

    /// Is the chunk's bottom edge resting on (or within ~2.5px of) a solid
    /// tile? Used to kill downward velocity after the chunk connection nudges
    /// a resting chunk. Deliberately tolerant: it is only a velocity damp, so
    /// the extra 2.5px of reach can't re-arm the jump (grounding for the jump
    /// comes from the swept-contact flags, see update()).
    fn isOnGround(self: *const Slugcat, c: *const Chunk) bool {
        _ = self;
        const bottom = c.rect.bottom();
        const cx = c.rect.center().x;
        const half = @max(1, c.rect.w / 2 - 1);
        var x = cx - half;
        while (x <= cx + half) : (x += 2) {
            if (solidAt(.init(x, bottom + 1.0)) or solidAt(.init(x, bottom + 2.5))) return true;
        }
        return false;
    }

    fn update(self: *Slugcat, move_x: f32, move_up: bool, jump_pressed: bool, jump_held: bool, dt: f32) void {
        // Grounding source of truth: the swept-contact flags. These are
        // frame-fresh (pxl clears them at the start of every Y move), which
        // matters on the jump's takeoff frame — a tilemap sample taken a
        // couple of pixels below the rect still reports ground for a frame or
        // two, which would re-arm canJump mid-air and allow a double jump.
        const on_ground = self.chunks[0].state.below or self.chunks[1].state.below;
        const just_landed = on_ground and !self.was_grounded;
        self.was_grounded = on_ground;
        self.grounded = on_ground;

        // Rain World refreshes canJump every frame a chunk is on the ground;
        // a fresh jump press consumes it.
        if (on_ground) self.can_jump = 5;
        if (just_landed) self.squash = 1;

        // --- run speed (dynamicRunSpeed with exponential smoothing) ---
        // The pair counts as grounded while either chunk touches, so the upper
        // body keeps its ground acceleration during the drop from the standing
        // pose and leads the run (RW's dynamicRunSpeed[0] > [1]).
        if (move_x != 0) {
            self.flip = if (move_x > 0) 1 else -1;
            const rate = if (on_ground) ground_accel_rate else air_accel_rate;
            const blend = 1.0 - std.math.exp(-rate * dt);
            const target = move_x * run_speed;
            self.chunks[0].vel.x = lerpf(self.chunks[0].vel.x, target, blend);
            self.chunks[1].vel.x = lerpf(self.chunks[1].vel.x, target * 0.93, blend);
        } else if (on_ground) {
            const blend = 1.0 - std.math.exp(-ground_friction_rate * dt);
            self.chunks[0].vel.x = lerpf(self.chunks[0].vel.x, 0, blend);
            self.chunks[1].vel.x = lerpf(self.chunks[1].vel.x, 0, blend);
        }

        // --- jump (Rain World: a fresh press consumes canJump and fires the
        // impulse; holding jump then keeps lifting via jumpBoost, so a tap is
        // a short hop and a held jump is the floaty full jump) ---
        if (jump_pressed and self.can_jump > 0) {
            self.can_jump = 0;
            // Both chunks launch with the same impulse: the pose constraint
            // keeps them at rest distance, so they fly as one rigid body.
            self.chunks[0].vel.y = -jump_speed;
            self.chunks[1].vel.y = -jump_speed;
            // RW's crouch-hop: a grounded jump pushes forward while running.
            if (move_x != 0) {
                self.chunks[0].vel.x += move_x * jump_hop;
                self.chunks[1].vel.x += move_x * jump_hop;
            }
            // Standing jumps carry a bit more boost than all-fours jumps.
            self.jump_boost = if (self.stand_blend > 0.5) 8 else 6;
        }
        // The boost drains every frame (release cuts the jump short) and,
        // while jump is held, keeps lifting — RW's tap = hop / hold = float.
        if (self.jump_boost > 0) {
            if (jump_held) {
                const lift = (self.jump_boost + 1) * jump_boost_rate * dt;
                self.chunks[0].vel.y -= lift;
                self.chunks[1].vel.y -= lift;
            }
            self.jump_boost = @max(0, self.jump_boost - jump_boost_decay * dt);
        }

        // terminal fall speed (both directions)
        self.chunks[0].vel.y = clampf(self.chunks[0].vel.y, -max_fall, max_fall);
        self.chunks[1].vel.y = clampf(self.chunks[1].vel.y, -max_fall, max_fall);

        // --- standing pose blend (RW's Stand vs Default body modes) ---
        // Frozen in the air so a jump keeps its takeoff pose. On the ground the
        // creature stands upright when idle or holding up, and drops to all
        // fours when it runs.
        if (on_ground) {
            // Don't try to stand up when there's no headroom (crawling under
            // a low ceiling): stay crouched on all fours, which is what Rain
            // World's slugcat does when the room is too short to Stand.
            const want_stand = (move_x == 0 or move_up) and self.standingFits();
            const stand_target: f32 = if (want_stand) 1 else 0;
            self.stand_blend = lerpf(self.stand_blend, stand_target, 1.0 - std.math.exp(-7 * dt));
        }

        // --- physics ---
        self.chunks[0].update(&map, dt);
        self.chunks[1].update(&map, dt);

        // --- pose constraint: pin the head chunk to its pose position
        // relative to the lower chunk. Standing = straight up over the hips
        // (upright, ~2 tiles); running = ahead on the ground (all fours,
        // ~1 tile). The head chunk inherits the lower chunk's velocity so the
        // swept collision never fights the constraint. The pose computes the
        // distance it actually pinned at (slid back out of solid tiles when
        // bonking a ceiling/wall) and the connection below caps at that —
        // otherwise the two would fight forever: the connection restores the
        // full rest distance, pushing the head chunk back into the ceiling,
        // and the pose compresses it again. That oscillation is what wedged
        // and jittered the slugcat in low crawl spaces.
        var pose_dist: f32 = -1; // -1 = pose skipped (wedged into a wall)
        {
            const c1 = self.chunks[1].rect.center();
            const want_raw = lerpVec(.init(self.flip, 0), .init(0, -1), self.stand_blend);
            const want = want_raw.norm();
            var d = self.rest_dist;
            const w = self.chunks[0].rect.w;
            const h = self.chunks[0].rect.h;
            while (d > 3 and rectOverlapsSolid(c1.add(want.scale(d)), w, h)) d -= 1;
            if (d > 3) {
                pose_dist = d;
                const new_pos = c1.add(want.scale(d));
                self.chunks[0].setCenter(new_pos);
                self.chunks[0].vel = self.chunks[1].vel;
            }
            // else: wedged where the whole pose line is inside a wall (e.g.
            // jumping right under a low ceiling at a floor edge) — skip the
            // pin for this frame. The chunk keeps its own velocity, the
            // connection keeps the pair together, and collision resolution
            // pushes it clear; the pose re-engages as soon as it fits again.
        }

        // --- chunk connection (RW BodyChunkConnection: restore the rest
        // distance, correcting both pos and vel, split by mass symmetry) ---
        {
            const c0 = self.chunks[0].rect.center();
            const c1 = self.chunks[1].rect.center();
            const d = c1.sub(c0);
            const num = d.len();
            // Never push the pair apart beyond what the pose allowed this
            // frame (see the pose/connection-fight comment above).
            const target = if (pose_dist > 0) pose_dist else self.rest_dist;
            if (num > 1e-4) {
                const dir = d.norm(); // chunk0 -> chunk1
                const corr = dir.scale((target - num) * 0.5);
                self.chunks[0].setCenter(c0.sub(corr));
                self.chunks[0].vel = self.chunks[0].vel.sub(corr);
                self.chunks[1].setCenter(c1.add(corr));
                self.chunks[1].vel = self.chunks[1].vel.add(corr);
            }
        }

        // Resting chunks don't keep accumulating gravity into vel.y (the
        // tilemap sample is more tolerant than the swept-contact flag, so this
        // also covers the couple of pixels the rigid connection lifts a chunk
        // while the pose transitions).
        if (self.isOnGround(&self.chunks[0]) and self.chunks[0].vel.y > 0) self.chunks[0].vel.y = 0;
        if (self.isOnGround(&self.chunks[1]) and self.chunks[1].vel.y > 0) self.chunks[1].vel.y = 0;
        self.speed = @abs(self.chunks[0].vel.x);

        // --- run cycle: one frame per step, 6 frames per full cycle ---
        const moving = on_ground and self.speed > 30;
        if (moving) {
            self.anim_frame += 1;
            if (self.anim_frame > 6) {
                self.anim_frame = 0;
                self.left_foot = !self.left_foot;
            }
        } else {
            self.anim_frame = 0;
        }
        if (self.squash > 0) self.squash = @max(0, self.squash - 3 * dt);

        // --- drawPositions: body bob + forward lean (PlayerGraphics.cs) ---
        const run_t = clampf(self.speed / run_speed, 0, 1);
        const phase = @as(f32, @floatFromInt(self.anim_frame)) / 6.0 * std.math.tau;
        self.upper_draw = self.chunks[0].rect.center().add(.init(
            self.flip * 4 * run_t,
            @cos(phase) * 2.0 * run_t,
        ));
        self.lower_draw = self.chunks[1].rect.center().add(.init(
            0,
            (2.0 + @sin(phase) * 3.0) * run_t,
        ));

        // --- legs (two-bone IK, ground-planting walk) — hips on the lower
        // chunk, like RW's legs attach to bodyChunks[1] ---
        self.leg_hip[0] = self.lower_draw.add(.init(self.flip * 3, -1));
        self.leg_hip[1] = self.lower_draw.add(.init(-self.flip * 3, -1));
        self.legs[0].update(self.leg_hip[0], self.flip, on_ground, moving, dt);
        self.legs[1].update(self.leg_hip[1], self.flip, on_ground, moving, dt);

        // --- arms (FABRIK chains) — shoulders on the upper chunk ---
        self.arm_shoulder[0] = self.upper_draw.add(.init(self.flip * 5, 0));
        self.arm_shoulder[1] = self.upper_draw.add(.init(-self.flip * 3, 1));
        if (on_ground) {
            if (moving) {
                self.arm_target[0] = self.upper_draw.add(.init(
                    self.flip * (7 + 2 * @sin(phase)),
                    2 + 2 * @sin(phase),
                ));
                self.arm_target[1] = self.upper_draw.add(.init(
                    -self.flip * 5,
                    2 + @sin(phase),
                ));
            } else {
                // Standing: the front paw presses the ground ahead, the back
                // paw hangs by the body.
                self.arm_target[0] = groundBelow(self.upper_draw.add(.init(self.flip * 8, 2)), 60)
                    orelse self.upper_draw.add(.init(self.flip * 8, 8));
                self.arm_target[1] = self.upper_draw.add(.init(-self.flip * 5, 6));
            }
        } else {
            const flail = self.chunks[0].vel.scale(0.05);
            self.arm_target[0] = self.upper_draw.add(.init(self.flip * 10, -4)).add(flail);
            self.arm_target[1] = self.upper_draw.add(.init(-self.flip * 7, -2)).add(flail);
        }
        self.arms[0].solve(self.arm_shoulder[0], self.arm_target[0], 4);
        self.arms[1].solve(self.arm_shoulder[1], self.arm_target[1], 4);

        // --- head: verlet part elastically tethered ahead of the upper chunk ---
        self.head_anchor = self.upper_draw.add(.init(self.flip * (4 + 2 * run_t), -7 + 2 * run_t));
        self.head.update(0, dt);
        self.head.connectToPoint(self.head_anchor, 3, 0.2, self.chunks[0].vel, 0.7, 0.1);
        self.look_dir = .init(self.flip * 0.7, if (!on_ground) 0.35 else -0.15);
        self.head.vel = self.head.vel.sub(self.look_dir.scale(30 * dt));

        // --- tail: verlet rope (TailSegment.cs + PlayerGraphics.Update) ---
        // tail[0] is anchored to the lower body's tail point; each segment
        // follows the previous via a distance constraint. A chain pull toward
        // the body — strongest at the root, halving per segment — makes the
        // tail trail along behind the slugcat as it runs. num5 is 0 while
        // running (stiff, little droop) and drifts to 1 when idle (droopy).
        const root = self.lower_draw.add(.init(-self.flip * 7, 2));
        var num5: f32 = if (run_t > 0.5) 0 else 1;
        var num12: f32 = 28;
        var anchor: Vec2 = self.chunks[0].rect.center(); // pull anchor: upper chunk first
        var prev_seg: Vec2 = self.chunks[1].rect.center(); // then the lower chunk, then earlier segments

        // Pass 1: verlet update, distance constraints, damping, chain pull.
        // No terrain collision in this pass — the distance constraints can
        // move earlier segments (affectPrevious) *after* their push-out ran,
        // dragging them back into the wall. That's what stuck tail segments
        // inside the floor during the run out of the crawl space.
        for (0..4) |l| {
            const seg = &self.tail[l];
            seg.part.update(0, dt);

            // distance constraint to the previous segment (or the body)
            const prev_pos = if (l == 0) root else self.tail[l - 1].part.pos;
            const dd = prev_pos.sub(seg.part.pos);
            const dist = dd.len();
            seg.stretched = 1;
            if (dist > seg.connection_rad and dist > 1e-4) {
                const dir = dd.norm();
                const corr_self = dir.scale((seg.connection_rad - dist) * (1 - seg.affect_previous));
                const corr_prev = dir.scale((seg.connection_rad - dist) * seg.affect_previous);
                seg.part.pos = seg.part.pos.sub(corr_self);
                seg.part.vel = seg.part.vel.sub(corr_self);
                if (l > 0) {
                    self.tail[l - 1].part.pos = self.tail[l - 1].part.pos.add(corr_prev);
                    self.tail[l - 1].part.vel = self.tail[l - 1].part.vel.add(corr_prev);
                }
                seg.stretched = clampf((seg.connection_rad / (dist * 0.5) + 2) / 3, 0.2, 1);
            }

            // damping + weak gravity (droop), scaled by num5 (PlayerGraphics.cs)
            const damp = lerpf(0.75, 0.95, num5);
            seg.part.vel = seg.part.vel.scale(std.math.pow(f32, damp, 60 * dt));
            seg.part.vel.y += lerpf(0.1, 0.5, num5) * gravity * dt;
            num5 = (num5 * 10 + 1) / 11;

            // chain pull: vel += DirVec(anchor, pos) * num12 / dist — a stretch
            // force keeping the tail trailed out behind the slugcat (RW).
            const to_anchor = seg.part.pos.sub(anchor);
            const ad = to_anchor.len();
            if (ad > 1e-4) {
                seg.part.vel = seg.part.vel.add(to_anchor.norm().scale(num12 / ad));
            }
            num12 *= 0.5;
            anchor = prev_seg;
            prev_seg = seg.part.pos;
        }

        // Pass 2: after all the corrections settled, keep the tail near the
        // body and push any segment that ended up inside terrain back out (RW
        // PushOutOfTerrain) — the tail drags on the floor instead of poking
        // through it. Run twice: a push-out of one segment can nudge another
        // back into a wall, and the second pass catches that.
        for (0..2) |_| {
            for (0..4) |l| {
                const seg = &self.tail[l];
                const maxr = 9.0 * @as(f32, @floatFromInt(l + 1));
                const from_body = seg.part.pos.sub(self.lower_draw);
                const bl = from_body.len();
                if (bl > maxr) seg.part.pos = self.lower_draw.add(from_body.norm().scale(maxr));
                pushPartOutOfTerrain(&seg.part);
            }
        }
    }

    // ------------------------------------------------------------------ draw
    fn render(self: *const Slugcat) void {
        const body_col = Color.fromRgb(0.86, 0.64, 0.42);
        const dark_col = Color.fromRgb(0.55, 0.37, 0.23);
        const belly_col = Color.fromRgb(0.96, 0.84, 0.68);

        // soft shadow
        const sh_t = clampf(self.speed / run_speed, 0, 1);
        api.drawRectEx(
            self.lower_draw.add(.init(0, 9)),
            .init(22 + 6 * sh_t, 5),
            .center,
            Color.fromRgba(0, 0, 0, 0.18),
        );

        // tail (behind the body)
        var prev = self.lower_draw.add(.init(-self.flip * 5, 1));
        for (0..4) |l| {
            const seg = &self.tail[l];
            const thick = lerpf(3.0, 1.4, @as(f32, @floatFromInt(l)) / 3.0);
            api.drawLine(prev, seg.part.pos, thick, body_col);
            prev = seg.part.pos;
        }

        // back arm
        drawArm(&self.arms[1], dark_col, body_col);

        // body: two chunky circles — Rain World's slugcat is basically this.
        // A thick back line under the circles bridges the gap between them so
        // the body reads as one continuous mass (elongated on all fours).
        const c0 = self.upper_draw;
        const c1 = self.lower_draw;
        api.drawLine(c1, c0, 7.0, body_col);
        drawBodyCircle(c0, 5.5, dark_col, body_col);
        drawBodyCircle(c1, 5.0, dark_col, body_col);
        // belly highlight
        api.drawCircle(c0.add(.init(-self.flip * 1.5, 2.2)), 2.4, 10, belly_col);
        api.drawCircle(c1.add(.init(-self.flip * 1.5, 2.0)), 2.2, 10, belly_col);

        // legs
        for (0..2) |i| {
            const leg = &self.legs[i];
            const hip = self.leg_hip[i];
            api.drawLine(hip, leg.knee, 3.2, body_col);
            api.drawLine(leg.knee, leg.foot, 2.8, body_col);
            api.drawCircle(leg.knee, 1.4, 8, dark_col);
            api.drawCircle(leg.foot, 2.4, 10, dark_col);
        }

        // front arm
        drawArm(&self.arms[0], dark_col, body_col);

        // head + ears + eye
        const hp = self.head.pos;
        api.drawCircle(hp, 4.6, 14, dark_col);
        api.drawCircle(hp, 3.9, 14, body_col);
        api.drawTriangle(
            hp.add(.init(self.flip * 1.2, -3.6)),
            hp.add(.init(self.flip * 3.8, -5.4)),
            hp.add(.init(self.flip * -1.2, -5.6)),
            body_col,
        );
        api.drawTriangle(
            hp.add(.init(self.flip * -2.6, -3.6)),
            hp.add(.init(self.flip * -5, -5.2)),
            hp.add(.init(self.flip * 0.2, -5.4)),
            body_col,
        );
        api.drawCircle(hp.add(.init(self.flip * 2.6, -0.8)), 1.3, 8, Color.fromRgb(0.1, 0.08, 0.06));
    }

    fn drawBodyCircle(center: Vec2, rad: f32, outline: Color, fill: Color) void {
        api.drawCircle(center, rad + 1.0, 16, outline);
        api.drawCircle(center, rad, 16, fill);
    }

    fn drawArm(arm: *const Arm, dark_col: Color, body_col: Color) void {
        api.drawLine(arm.nodes[0], arm.nodes[1], 2.8, dark_col);
        api.drawLine(arm.nodes[1], arm.nodes[2], 2.4, body_col);
        api.drawCircle(arm.nodes[0], 1.6, 8, dark_col);
        api.drawCircle(arm.nodes[2], 1.9, 8, dark_col);
    }

    // ---------------------------------------------------------- debug overlay
    fn renderDebug(self: *const Slugcat) void {
        const d = pxl.dbg;

        // chunk rects + connection
        d.drawHollowRect(self.chunks[0].rect.pos(), self.chunks[0].rect.w, self.chunks[0].rect.h, 1, Color.green);
        d.drawHollowRect(self.chunks[1].rect.pos(), self.chunks[1].rect.w, self.chunks[1].rect.h, 1, Color.sky_blue);
        const c0 = self.chunks[0].rect.center();
        const c1 = self.chunks[1].rect.center();
        d.drawLine(c0, c1, 1, Color.fromRgba(1, 1, 1, 0.5));

        // legs: hip -> target, planted foot / dangling foot
        for (0..2) |i| {
            const leg = &self.legs[i];
            d.drawLine(self.leg_hip[i], leg.target, 1, Color.pink);
            if (leg.planted) {
                d.drawPoint(leg.foot, 4, Color.green);
            } else {
                d.drawHollowCircle(leg.foot, 3, 1.2, Color.orange);
            }
            // reach limit circle around the hip
            d.drawHollowCircle(self.leg_hip[i], Leg.max_step, 1, Color.fromRgba(1, 0.5, 0.6, 0.35));
        }

        // arms: shoulder -> target, FABRIK nodes
        for (0..2) |i| {
            d.drawLine(self.arm_shoulder[i], self.arm_target[i], 1, Color.gold);
            d.drawPoint(self.arm_target[i], 3, Color.gold);
            for (self.arms[i].nodes) |n| d.drawPoint(n, 2, Color.fromRgba(1, 1, 1, 0.8));
        }

        // head tether
        d.drawLine(self.head.pos, self.head_anchor, 1, Color.purple);
        d.drawPoint(self.head_anchor, 2.5, Color.purple);

        // velocity vector from the center of mass
        const com = lerpVec(c0, c1, 0.5);
        const vel = self.chunks[0].vel.add(self.chunks[1].vel).scale(0.5);
        d.drawLine(com, com.add(vel.scale(0.25)), 1.5, Color.orange);

        const mode = if (self.grounded) "Default" else "Airborne";
        const pose = if (self.stand_blend > 0.5) "Stand" else "Fours";
        const f0: []const u8 = if (self.legs[0].planted) "planted" else "swing";
        const f1: []const u8 = if (self.legs[1].planted) "planted" else "swing";
        d.drawTextFmt(
            "{s}/{s}  spd={d:.0}px/s  anim={d}  jump={d}  flip={d:.0}",
            .{ mode, pose, self.speed, self.anim_frame, self.can_jump, self.flip },
            com.add(.init(0, -38)),
            Color.white,
        );
        d.drawTextFmt("front {s} / back {s}  below {s} {s}", .{
            f0,
            f1,
            stateMark(self.chunks[0].state.below),
            stateMark(self.chunks[1].state.below),
        }, com.add(.init(0, -26)), Color.light_gray);
    }
};

// ---------------------------------------------------------------------------
// Example callbacks
// ---------------------------------------------------------------------------
pub fn config() pxl.Config {
    return .{
        .win = .{
            .width = 640 * 2,
            .height = 360 * 2,
        },
        .gfx = .{
            .design_width = 640,
            .design_height = 360,
            .resolution_policy = .show_all_pixel_perfect,
        },
    };
}

pub fn setup() !void {
    textures = std.AutoHashMap(i64, Texture).init(pxl.mem.allocator);

    map = try LDtk.parse(try pxl.fs.read("examples/assets/tiny_tiles.ldtk", .temp));
    if (map.root.defs) |defs| {
        for (defs.tilesets) |tileset| {
            if (tileset.relPath) |rel_path| {
                const path = try std.mem.concatWithSentinel(pxl.mem.scratch, u8, &.{ "examples/assets/", rel_path }, 0);
                const tex = try Texture.initFromFile(path);
                try textures.put(tileset.uid, tex);
            } else if (tileset.embedAtlas) |atlas| {
                if (atlas == .LdtkIcons) {
                    const tex = try Texture.initFromFile("examples/assets/ldtk_icons.png");
                    try textures.put(tileset.uid, tex);
                }
            }
        }
    }

    // Grab the IntGrid collision layer and derive the world size from it.
    const layers = map.root.levels[0].layerInstances.?;
    for (layers) |layer| {
        if (layer.__type == .IntGrid) {
            collision = layer;
            break;
        }
    }
    map_w = @as(f32, @floatFromInt(collision.width())) * tile_size;
    map_h = @as(f32, @floatFromInt(collision.height())) * tile_size;

    input.addBinding("left", .key(.left));
    input.addBinding("left", .key(.a));
    input.addBinding("left", .gamepadButton(.dpad_left));
    input.addBinding("left", .gamepadAxis(.left_stick_left));

    input.addBinding("right", .key(.right));
    input.addBinding("right", .key(.d));
    input.addBinding("right", .gamepadButton(.dpad_right));
    input.addBinding("right", .gamepadAxis(.left_stick_right));

    input.addBinding("up", .key(.up));
    input.addBinding("up", .key(.w));
    input.addBinding("up", .gamepadButton(.dpad_up));
    input.addBinding("up", .gamepadAxis(.left_stick_up));

    input.addBinding("down", .key(.down));
    input.addBinding("down", .key(.s));
    input.addBinding("down", .gamepadButton(.dpad_down));
    input.addBinding("down", .gamepadAxis(.left_stick_down));

    input.addBinding("jump", .key(.space));
    input.addBinding("jump", .key(.up));
    input.addBinding("jump", .key(.w));
    input.addBinding("jump", .gamepadButton(.south));
    input.addBinding("jump", .gamepadButton(.east));

    // Spawn mid-platform: the floor top is tile row 15 (y=180) and a low
    // ceiling (rows 11-12) hangs over the floor's left half (x <= 132), so
    // this spot keeps full headroom for standing and jumping.
    slugcat.init(.init(200, 172));
    camera.position = slugcat.chunks[0].rect.center();
}

pub fn update() !void {
    if (input.keyPressed(.f1)) show_debug = !show_debug;

    const move = input.getVector("left", "right", "up", "down", .square);
    const jump_pressed = input.isActionJustPressed("jump");
    const jump_held = input.isActionPressed("jump");
    const dt = pxl.time.dt();

    slugcat.update(move.x, move.y <= -0.5, jump_pressed, jump_held, dt);

    // Camera: follow the slugcat (with lookahead) or steer manually.
    if (follow_cam) {
        const com = lerpVec(
            slugcat.chunks[0].rect.center(),
            slugcat.chunks[1].rect.center(),
            0.5,
        );
        const lookahead = move.x * 40;
        const target = com.add(.init(lookahead, -20));
        const blend = 1.0 - std.math.exp(-5 * dt);
        camera.position = lerpVec(camera.position, target, blend);
        camera.zoom = 2.0;
    }

    if (mu.beginWindowEx("Slugcat", .{ .x = 10, .y = 10, .w = 250, .h = 360 }, .{ .align_center = false })) {
        mu.layoutRow(2, &[_]c_int{ 100, -1 }, 0);
        _ = mu.checkbox("Follow cam", &follow_cam);
        _ = mu.checkbox("Debug overlay", &show_debug);

        if (!follow_cam) {
            mu.layoutRow(2, &[_]c_int{ 95, -1 }, 0);
            mu.label("Cam X:");
            _ = mu.slider(&camera.position.x, 0, 264, 1);
            mu.label("Cam Y:");
            _ = mu.slider(&camera.position.y, 0, 264, 1);
            mu.label("Zoom:");
            _ = mu.slider(&camera.zoom, 0.5, 4.0, 0.1);
        }

        mu.layoutRow(1, &[_]c_int{ -1, -1 }, 0);
        var st_buf: [64]u8 = undefined;
        const mode = if (slugcat.grounded) "Default" else "Airborne";
        const pose = if (slugcat.stand_blend > 0.5) "Stand (upright)" else "On all fours";
        mu.label((std.fmt.bufPrintZ(&st_buf, "mode:  {s} / {s}", .{ mode, pose }) catch unreachable).ptr);
        mu.label((std.fmt.bufPrintZ(&st_buf, "speed: {d:.0} px/s", .{slugcat.speed}) catch unreachable).ptr);
        mu.label((std.fmt.bufPrintZ(&st_buf, "anim:  {d}  jump: {d}", .{ slugcat.anim_frame, slugcat.can_jump }) catch unreachable).ptr);
        mu.label((std.fmt.bufPrintZ(&st_buf, "ground:{s}  below: {s} {s}", .{
            stateMark(slugcat.grounded),
            stateMark(slugcat.chunks[0].state.below),
            stateMark(slugcat.chunks[1].state.below),
        }) catch unreachable).ptr);
        mu.label((std.fmt.bufPrintZ(&st_buf, "feet:  {s} {s}", .{ stateMark(slugcat.legs[0].planted), stateMark(slugcat.legs[1].planted) }) catch unreachable).ptr);

        mu.endWindow();
    }
}

/// Renders "yes" when a collision-state bool is set, otherwise "-".
fn stateMark(b: bool) []const u8 {
    return if (b) "yes" else "-";
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = Color.aya, .camera = camera });
    for (map.root.levels) |level| renderLevel(level);

    slugcat.render();
    if (show_debug) slugcat.renderDebug();

    api.drawText(null, .init(12, 12), "Slugcat: ARROWS/WASD run, SPACE/UP jump, F1 debug lines", Color.light_gray);
    pxl.endPass();
}

pub fn shutdown() !void {
    map.deinit();
    textures.deinit();
}

/// Main level rendering routine (from the ldtk example).
pub fn renderLevel(level: LDtk.Level) void {
    const layer_instances = level.layerInstances orelse return;

    // LDtk stores layers top-to-bottom (index 0 is the top-most layer).
    // Loop backwards to draw bottom layers first (back-to-front rendering).
    var i: usize = layer_instances.len;
    while (i > 0) {
        i -= 1;
        const layer = layer_instances[i];

        // Skip hidden layers
        if (!layer.visible) continue;

        // Calculate world-space offsets for this layer
        const layer_x: f32 = @floatFromInt(level.worldX + layer.__pxTotalOffsetX);
        const layer_y: f32 = @floatFromInt(level.worldY + layer.__pxTotalOffsetY);

        switch (layer.__type) {
            .Entities => {
                renderEntities(layer, layer_x, layer_y);
            },
            .Tiles, .AutoLayer, .IntGrid => {
                const grid_size: f32 = @floatFromInt(layer.__gridSize);
                // Resolve active tileset UID (override instance UID takes precedence if set)
                const tileset_uid = layer.overrideTilesetUid orelse layer.__tilesetDefUid orelse continue;
                const tex = textures.get(tileset_uid) orelse unreachable;

                for (layer.gridTiles) |tile| {
                    drawTile(tile, tex, grid_size, layer_x, layer_y, layer.__opacity);
                }
                for (layer.autoLayerTiles) |tile| {
                    drawTile(tile, tex, grid_size, layer_x, layer_y, layer.__opacity);
                }
            },
        }
    }
}

/// Renders an individual tile instance
fn drawTile(tile: LDtk.TileInstance, tex: Texture, grid_size: f32, layer_x: f32, layer_y: f32, layer_opacity: f64) void {
    // Destination rectangle on screen/world
    const dest_rect = Rect{
        .x = layer_x + @as(f32, @floatFromInt(tile.px[0])),
        .y = layer_y + @as(f32, @floatFromInt(tile.px[1])),
        .w = grid_size,
        .h = grid_size,
    };

    // Source coordinates in the tileset atlas
    var src_x: f32 = @floatFromInt(tile.src[0]);
    var src_y: f32 = @floatFromInt(tile.src[1]);
    var src_w: f32 = grid_size;
    var src_h: f32 = grid_size;

    // Handle horizontal / vertical flip bits using negative dimensions
    if (tile.isFlippedX()) {
        src_x += src_w;
        src_w = -src_w;
    }

    if (tile.isFlippedY()) {
        src_y += src_h;
        src_h = -src_h;
    }

    const src_rect = Rect{
        .x = src_x,
        .y = src_y,
        .w = src_w,
        .h = src_h,
    };

    api.drawTexturedRect(tex, dest_rect, src_rect, Color.fromRgba(1, 1, 1, @floatCast(tile.a * layer_opacity)));
}

/// Render all entities in an Entity layer
pub fn renderEntities(layer: LDtk.LayerInstance, layer_x: f32, layer_y: f32) void {
    if (layer.__type != .Entities) return;

    for (layer.entityInstances) |entity| {
        renderEntity(entity, layer_x, layer_y);
    }
}

/// Render a single entity instance
pub fn renderEntity(entity: LDtk.EntityInstance, layer_x: f32, layer_y: f32) void {
    const width: f32 = @floatFromInt(entity.width);
    const height: f32 = @floatFromInt(entity.height);
    const pivot_x: f32 = @floatCast(entity.__pivot[0]);
    const pivot_y: f32 = @floatCast(entity.__pivot[1]);

    // Calculate top-left world-space position based on pivot
    const x: f32 = layer_x + @as(f32, @floatFromInt(entity.px[0])) - (pivot_x * width);
    const y: f32 = layer_y + @as(f32, @floatFromInt(entity.px[1])) - (pivot_y * height);

    // 1. Draw entity Tile if present
    if (entity.__tile) |tile| {
        const tex = textures.get(tile.tilesetUid) orelse unreachable;

        const dest_rect = Rect{
            .x = x,
            .y = y,
            .w = width,
            .h = height,
        };

        const src_rect = Rect{
            .x = @floatFromInt(tile.x),
            .y = @floatFromInt(tile.y),
            .w = @floatFromInt(tile.w),
            .h = @floatFromInt(tile.h),
        };

        api.drawTexturedRect(tex, dest_rect, src_rect, Color.white);
    } else {
        // Fallback / Debug: Draw a colored rectangle using __smartColor
        var color = parseHexColor(entity.__smartColor);
        color[3] = 0.6;

        api.drawRect(.init(x, y - height), .init(width, height), Color.fromArray(color));
    }
}

/// Converts LDtk hex color strings (e.g. "#FF0055" or "FF0055") to normalized RGBA [0.0 - 1.0]
fn parseHexColor(hex_str: []const u8) [4]f32 {
    var src = hex_str;
    if (src.len > 0 and src[0] == '#') {
        src = src[1..];
    }
    if (src.len < 6) return .{ 1.0, 0.0, 1.0, 1.0 }; // Fallback magenta

    const r = std.fmt.parseInt(u8, src[0..2], 16) catch 255;
    const g = std.fmt.parseInt(u8, src[2..4], 16) catch 0;
    const b = std.fmt.parseInt(u8, src[4..6], 16) catch 255;

    return .{
        @as(f32, @floatFromInt(r)) / 255.0,
        @as(f32, @floatFromInt(g)) / 255.0,
        @as(f32, @floatFromInt(b)) / 255.0,
        1.0,
    };
}
