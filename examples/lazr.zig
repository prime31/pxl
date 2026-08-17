// Lazr — a movement-feel playground. Ports the core of Lazr's Hero.cs (idle,
// run, jump, fall, slide, wall-climb, dash) onto pxl's LDtk tilemap + state
// machine, with every feel constant live-tunable in the microui panel.
//
// Controls:
//   move: arrows / wasd / dpad / left stick
//   jump: space / z / gamepad south (A)
//   dash: x / left shift / gamepad east (B)
//   grab: c / left control / gamepad west (X)

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
const StateMachine = pxl.util.StateMachine;
const LayerInstance = LDtk.LayerInstance;
const moveBody = pxl.tilemap.moveBody;
const rectOverlapsSolid = pxl.tilemap.rectOverlapsSolid;

const Feel = struct {
    gravity: f32 = 1800, // px/s² (~Lazr's 0.5 px/f² at 60fps)
    friction: f32 = 0.899, // horizontal velocity retained per 60fps frame
    max_speed: f32 = 300, // px/s (Lazr's 5 px/f terminal)
    max_fall: f32 = 300,
    ground_accel: f32 = 720, // 0.2 px/f²
    air_accel: f32 = 1044, // 0.29 px/f²
    slide_accel: f32 = 1404, // 0.39 px/f²
    slide_duration: f32 = 0.33,
    jump_impulse: f32 = 276, // px/s (Lazr's -4.6 px/f impulse)
    jump_hop: f32 = 0,
    jump_gravity_scale: f32 = 0.2, // gravity multiplier while rising & jump held (Lazr's jumpBonus)
    jump_hold_time: f32 = 0.12, // seconds the reduced gravity lasts before rising at full gravity
    jump_cut_rate: f32 = 7.2, // how fast gravity returns to full when jump is released
    coyote_time: f32 = 0.08,
    jump_buffer_time: f32 = 0.08,
    air_jumps: f32 = 1,
    air_jump_impulse_scale: f32 = 1.0,
    dash_boost: f32 = 60, // one-shot velocity kick on dash entry (px/s)
    dash_accel: f32 = 1116, // continuous dash thrust (px/s², Lazr's 0.31 px/f²)
    dash_speed: f32 = 320, // dash speed cap
    dash_duration: f32 = 0.5,
    dash_cooldown: f32 = 0.58,
    climb_speed: f32 = 90,
    wall_stick: f32 = 30,
    wall_jump_impulse_y: f32 = 276,
    wall_jump_impulse_x: f32 = 240,
    climb_hop_impulse: f32 = 300,
    climb_hop_x: f32 = 120,
    grab_reach: f32 = 4,
    grab_box_height: f32 = 5,
    camera_speed: f32 = 8,
    camera_lookahead: f32 = 24,
};

var feel: Feel = .{};

const State = enum { idle, run, jump, fall, slide, climb_wall, dash_tran, dash };

const Cell = struct { x: u8, y: u8 };
const Anim = struct { cells: []const Cell, fps: f32 = 10, loops: bool = true };

// Frame cells lifted from Lazr's Hero.cs (16x32 cells on a 256x256 atlas).
const anim_idle = Anim{ .cells = &.{
    .{ .x = 6, .y = 1 },  .{ .x = 7, .y = 1 },  .{ .x = 8, .y = 1 },  .{ .x = 9, .y = 1 },
    .{ .x = 10, .y = 1 }, .{ .x = 11, .y = 1 }, .{ .x = 12, .y = 1 }, .{ .x = 13, .y = 1 },
}, .fps = 6 };
const anim_run = Anim{ .cells = &.{
    .{ .x = 0, .y = 4 }, .{ .x = 1, .y = 4 }, .{ .x = 2, .y = 4 },  .{ .x = 3, .y = 4 },
    .{ .x = 4, .y = 4 }, .{ .x = 5, .y = 4 }, .{ .x = 6, .y = 4 },  .{ .x = 7, .y = 4 },
    .{ .x = 8, .y = 4 }, .{ .x = 9, .y = 4 }, .{ .x = 10, .y = 4 }, .{ .x = 11, .y = 4 },
}, .fps = 20 };
const anim_jump = Anim{ .cells = &.{ .{ .x = 4, .y = 0 }, .{ .x = 5, .y = 0 }, .{ .x = 6, .y = 0 } }, .fps = 12, .loops = false };
const anim_fall = Anim{ .cells = &.{ .{ .x = 7, .y = 0 }, .{ .x = 8, .y = 0 } }, .fps = 6 };
const anim_slide = Anim{ .cells = &.{ .{ .x = 11, .y = 0 }, .{ .x = 12, .y = 0 } }, .fps = 8 };
const anim_climb = Anim{ .cells = &.{ .{ .x = 2, .y = 2 }, .{ .x = 3, .y = 2 }, .{ .x = 4, .y = 2 } }, .fps = 8 };
const anim_climb_hold = Anim{ .cells = &.{.{ .x = 1, .y = 2 }}, .fps = 1 };
const anim_dash_tran = Anim{ .cells = &.{ .{ .x = 12, .y = 5 }, .{ .x = 13, .y = 5 }, .{ .x = 14, .y = 5 }, .{ .x = 15, .y = 5 } }, .fps = 12, .loops = false };
const anim_dash_side = Anim{ .cells = &.{ .{ .x = 6, .y = 6 }, .{ .x = 7, .y = 6 } }, .fps = 12 };
const anim_dash_up = Anim{ .cells = &.{ .{ .x = 0, .y = 6 }, .{ .x = 1, .y = 6 } }, .fps = 12 };
const anim_dash_down = Anim{ .cells = &.{ .{ .x = 2, .y = 6 }, .{ .x = 3, .y = 6 } }, .fps = 12 };
const anim_dash_diag_down = Anim{ .cells = &.{ .{ .x = 4, .y = 6 }, .{ .x = 5, .y = 6 } }, .fps = 12 };
const anim_dash_diag_up = Anim{ .cells = &.{ .{ .x = 8, .y = 6 }, .{ .x = 9, .y = 6 } }, .fps = 12 };
const anim_dash_none = Anim{ .cells = &.{.{ .x = 15, .y = 5 }}, .fps = 1 };

var map: *LDtk = undefined;
var collision: LayerInstance = undefined;
var hero_tex: *Texture = undefined;
var hero: Hero = .{};

var textures: std.AutoHashMap(i64, Texture) = undefined;

var camera: pxl.Camera = .{ .position = .init(320, 168), .zoom = 1.0, .rotation = 0 };
var show_debug: bool = true;

const Hero = struct {
    rect: Rect = .{},
    state: CollisionState = .{ .pixel_perfect = false },
    vel: Vec2 = .zero,
    facing: f32 = 1,
    sm: StateMachine(State, @This()) = .{ .current = .fall },

    anim: Anim = anim_idle,
    anim_time: f32 = 0,
    anim_index: usize = 0,

    coyote: f32 = 0,
    jump_buffer: f32 = 0,
    jump_time: f32 = 0,
    jump_gravity_scale_current: f32 = 1.0,
    grab_lockout: f32 = 0,
    air_jumps: f32 = 0,
    dash_time: f32 = 0,
    dash_cooldown: f32 = 0,
    slide_time: f32 = 0,
    trans_time: f32 = 0,
    dash_dir: Vec2 = .zero,

    fn init(self: *Hero, x: f32, y: f32) void {
        self.* = .{};
        self.rect = .{ .x = x - 4.5, .y = y - 15, .w = 9, .h = 15 };
    }

    fn update(self: *Hero) void {
        const dt = pxl.time.dt();
        self.dash_cooldown = @max(0, self.dash_cooldown - dt);
        self.coyote = @max(0, self.coyote - dt);
        self.jump_buffer = @max(0, self.jump_buffer - dt);
        self.grab_lockout = @max(0, self.grab_lockout - dt);

        if (self.state.below) {
            self.coyote = feel.coyote_time;
            self.air_jumps = feel.air_jumps;
        }

        if (input.isActionJustPressed("jump")) self.jump_buffer = feel.jump_buffer_time;

        self.sm.tick(self);
        self.applyPhysics();
        self.resolveVerticalState();
    }

    pub fn stateChanged(self: *Hero, prev: State, next: State) void {
        _ = prev;
        switch (next) {
            .idle => self.setAnim(anim_idle),
            .run => self.setAnim(anim_run),
            .jump => {
                self.setAnim(anim_jump);
                self.jump_time = 0;
            },
            .fall => self.setAnim(anim_fall),
            .slide => {
                self.setAnim(anim_slide);
                self.slide_time = feel.slide_duration;
            },
            .climb_wall => self.setAnim(anim_climb),
            .dash_tran => {
                self.setAnim(anim_dash_tran);
                self.trans_time = @as(f32, @floatFromInt(anim_dash_tran.cells.len)) / anim_dash_tran.fps;
            },
            .dash => self.setAnim(dashAnimFor(self.dash_dir)),
        }
    }

    pub fn idleState(self: *Hero) void {
        const move = moveInput();
        if (self.jump_buffer > 0 and self.tryJump(move.x)) return;
        if (move.x != 0) self.sm.change(self, .run);
    }

    pub fn runState(self: *Hero) void {
        const move = moveInput();
        if (move.x == 0) {
            self.sm.change(self, .idle);
            return;
        }
        self.facing = if (move.x > 0) 1 else -1;
        self.vel.x += move.x * feel.ground_accel * pxl.time.dt();
        self.vel.x = clampf(self.vel.x, -feel.max_speed, feel.max_speed);
        if (self.jump_buffer > 0 and self.tryJump(move.x)) return;
        if (input.isActionJustPressed("dash") and self.dash_cooldown <= 0) {
            self.sm.change(self, .slide);
            self.vel.x = self.facing * feel.max_speed;
            self.dash_cooldown = feel.dash_cooldown;
        }
    }

    pub fn jumpState(self: *Hero) void {
        const move = moveInput();
        self.airControl(move.x);
        if (self.jump_buffer > 0 and self.air_jumps > 0) self.airJump();
        if (input.isActionJustPressed("dash")) {
            self.tryDash(move);
            return;
        }
        if (self.tryWallGrab()) self.sm.change(self, .climb_wall);
    }

    pub fn fallState(self: *Hero) void {
        const move = moveInput();
        self.airControl(move.x);
        if (self.jump_buffer > 0 and self.air_jumps > 0) self.airJump();
        if (input.isActionJustPressed("dash")) {
            self.tryDash(move);
            return;
        }
        if (self.tryWallGrab()) self.sm.change(self, .climb_wall);
    }

    pub fn slideState(self: *Hero) void {
        const move = moveInput();
        self.slide_time -= pxl.time.dt();
        if (move.x != 0 and (move.x > 0) == (self.facing > 0)) {
            self.vel.x += move.x * feel.slide_accel * pxl.time.dt();
            self.vel.x = clampf(self.vel.x, -feel.max_speed, feel.max_speed);
        }
        if (self.jump_buffer > 0 and self.tryJump(move.x)) return;
        if (self.slide_time <= 0) self.sm.change(self, .idle);
    }

    pub fn climbWallState(self: *Hero) void {
        const move = moveInput();
        if (self.state.below) {
            self.sm.change(self, if (move.x != 0) .run else .idle);
            return;
        }
        self.dash_cooldown = 0; // Lazr refreshes the dash after a wall climb

        if (move.y < 0) {
            self.setAnim(anim_climb);
            self.vel.y = -feel.climb_speed;
        } else if (move.y > 0) {
            self.setAnim(anim_climb);
            self.vel.y = feel.climb_speed;
        } else {
            self.setAnim(anim_climb_hold);
            self.vel.y = 0;
        }
        self.vel.x = self.facing * feel.wall_stick;

        if (self.jump_buffer > 0) {
            self.jump_buffer = 0;
            self.facing = -self.facing;
            self.vel.y = -feel.wall_jump_impulse_y;
            self.vel.x = self.facing * feel.wall_jump_impulse_x;
            self.jump_gravity_scale_current = feel.jump_gravity_scale;
            self.grab_lockout = 0.15;
            self.sm.change(self, .jump);
            return;
        }
        if (input.isActionJustPressed("dash")) {
            self.tryDash(move);
            return;
        }
        if (!self.touchingWall()) {
            if (move.y < 0) {
                self.vel.y = -feel.climb_hop_impulse;
                self.vel.x = self.facing * feel.climb_hop_x;
                self.jump_gravity_scale_current = feel.jump_gravity_scale;
                self.grab_lockout = 0.15;
                self.sm.change(self, .jump);
            } else {
                self.sm.change(self, .fall);
            }
        }
    }

    pub fn dashTranState(self: *Hero) void {
        if (self.jump_buffer > 0) {
            self.cancelDashJump();
            return;
        }
        self.steerDash();
        self.vel.x += self.dash_dir.x * feel.dash_accel * pxl.time.dt();
        self.vel.y += self.dash_dir.y * feel.dash_accel * pxl.time.dt();
        if (self.tryWallGrab()) {
            self.sm.change(self, .climb_wall);
            return;
        }
        self.trans_time -= pxl.time.dt();
        self.dash_time -= pxl.time.dt();
        if (self.dash_time <= 0) {
            self.sm.change(self, .fall);
        } else if (self.trans_time <= 0) {
            self.sm.change(self, .dash);
        }
    }

    pub fn dashState(self: *Hero) void {
        if (self.jump_buffer > 0) {
            self.cancelDashJump();
            return;
        }
        self.steerDash();
        self.setAnim(dashAnimFor(self.dash_dir));
        self.vel.x += self.dash_dir.x * feel.dash_accel * pxl.time.dt();
        self.vel.y += self.dash_dir.y * feel.dash_accel * pxl.time.dt();
        if (self.tryWallGrab()) {
            self.sm.change(self, .climb_wall);
            return;
        }
        self.dash_time -= pxl.time.dt();
        if (self.dash_time <= 0) self.sm.change(self, .fall);
    }

    fn steerDash(self: *Hero) void {
        const move = moveInput();
        if (move.x != 0 or move.y != 0) {
            self.dash_dir = move.norm();
            if (move.x != 0) self.facing = if (move.x > 0) 1 else -1;
        }
    }

    fn cancelDashJump(self: *Hero) void {
        self.jump_buffer = 0;
        self.dash_time = 0;
        self.vel.y = -feel.jump_impulse; // keep horizontal dash momentum
        self.jump_gravity_scale_current = feel.jump_gravity_scale;
        self.sm.change(self, .jump);
    }

    fn tryJump(self: *Hero, move_x: f32) bool {
        if (self.jump_buffer <= 0) return false;
        const grounded = self.state.below or self.coyote > 0;
        if (!grounded and self.air_jumps <= 0) return false;
        self.jump_buffer = 0;
        if (grounded) {
            self.coyote = 0;
            self.vel.y = -feel.jump_impulse;
            self.vel.x += move_x * feel.jump_hop;
        } else {
            self.air_jumps -= 1;
            self.vel.y = -feel.jump_impulse * feel.air_jump_impulse_scale;
        }
        self.jump_gravity_scale_current = feel.jump_gravity_scale;
        self.sm.change(self, .jump);
        return true;
    }

    fn airJump(self: *Hero) void {
        self.jump_buffer = 0;
        self.air_jumps -= 1;
        self.vel.y = -feel.jump_impulse * feel.air_jump_impulse_scale;
        self.jump_gravity_scale_current = feel.jump_gravity_scale;
        self.sm.change(self, .jump);
    }

    fn airControl(self: *Hero, move_x: f32) void {
        if (move_x != 0) {
            self.facing = if (move_x > 0) 1 else -1;
            self.vel.x += move_x * feel.air_accel * pxl.time.dt();
            self.vel.x = clampf(self.vel.x, -feel.max_speed, feel.max_speed);
        }
    }

    fn tryDash(self: *Hero, move: Vec2) void {
        if (self.dash_cooldown > 0) return;
        var dir = move;
        if (dir.x == 0 and dir.y == 0) dir = .init(self.facing, 0);
        self.dash_dir = dir.norm();
        if (dir.x != 0) self.facing = if (dir.x > 0) 1 else -1;
        self.vel = self.vel.add(self.dash_dir.scale(feel.dash_boost));
        self.dash_time = feel.dash_duration;
        self.dash_cooldown = feel.dash_cooldown;
        self.sm.change(self, .dash_tran);
    }

    fn tryWallGrab(self: *Hero) bool {
        if (self.grab_lockout > 0) return false;
        if (!input.isActionPressed("grab")) return false;
        if (self.wallSolid(1)) {
            self.facing = 1;
            return true;
        }
        if (self.wallSolid(-1)) {
            self.facing = -1;
            return true;
        }
        return false;
    }

    fn touchingWall(self: *Hero) bool {
        return self.wallSolid(self.facing);
    }

    fn wallSolid(self: *Hero, side: f32) bool {
        const box = self.wallGrabBox(side);
        return rectOverlapsSolid(collision, box.center(), box.w, box.h);
    }

    fn wallGrabBox(self: *Hero, side: f32) Rect {
        const reach = feel.grab_reach;
        const y = self.rect.y + (self.rect.h - feel.grab_box_height) * 0.5;
        return if (side > 0)
            .{ .x = self.rect.right(), .y = y, .w = reach, .h = feel.grab_box_height }
        else
            .{ .x = self.rect.x - reach, .y = y, .w = reach, .h = feel.grab_box_height };
    }

    fn applyPhysics(self: *Hero) void {
        const dt = pxl.time.dt();
        const dashing = self.sm.current == .dash or self.sm.current == .dash_tran;
        const climbing = self.sm.current == .climb_wall;

        const fric = std.math.pow(f32, feel.friction, 60.0 * dt);
        if (dashing) {
            self.vel.x *= fric;
            self.vel.y *= fric;
        } else if (!climbing) {
            const rising = self.sm.current == .jump and self.vel.y < 0;
            if (rising and input.isActionPressed("jump") and self.jump_time < feel.jump_hold_time) {
                self.jump_gravity_scale_current = feel.jump_gravity_scale;
            } else if (rising) {
                self.jump_gravity_scale_current = @min(1.0, self.jump_gravity_scale_current + feel.jump_cut_rate * dt);
            } else {
                self.jump_gravity_scale_current = 1.0;
            }
            self.jump_time += dt;
            self.vel.y += feel.gravity * self.jump_gravity_scale_current * dt;
            self.vel.x *= fric;
        }

        const max_x = @max(feel.max_speed, feel.dash_speed);
        self.vel.x = clampf(self.vel.x, -max_x, max_x);
        self.vel.y = clampf(self.vel.y, -feel.max_fall, feel.max_fall);

        moveBody(map, &self.rect, &self.state, self.vel, collision);

        if (self.state.below and self.vel.y > 0) self.vel.y = 0;
        if (self.state.above and self.vel.y < 0) self.vel.y = 0;
        if (self.state.left and self.vel.x < 0) self.vel.x = 0;
        if (self.state.right and self.vel.x > 0) self.vel.x = 0;
    }

    fn resolveVerticalState(self: *Hero) void {
        switch (self.sm.current) {
            .climb_wall, .dash, .dash_tran => return,
            else => {},
        }
        if (self.state.below) {
            if (self.sm.current == .jump or self.sm.current == .fall) {
                self.air_jumps = feel.air_jumps;
                const move = moveInput();
                self.sm.change(self, if (move.x != 0) .run else .idle);
            }
        } else {
            if (self.sm.current == .idle or self.sm.current == .run) {
                self.sm.change(self, if (self.vel.y < 0) .jump else .fall);
            } else if (self.sm.current == .jump and self.vel.y >= 0) {
                self.sm.change(self, .fall);
            }
        }
    }

    fn setAnim(self: *Hero, a: Anim) void {
        if (self.anim.cells.ptr == a.cells.ptr) return;
        self.anim = a;
        self.anim_time = 0;
        self.anim_index = 0;
    }

    fn currentCell(self: *Hero) Cell {
        self.anim_time += pxl.time.dt();
        const frame_duration = 1.0 / self.anim.fps;
        if (self.anim_time >= frame_duration) {
            const advance: usize = @intFromFloat(self.anim_time / frame_duration);
            self.anim_time -= @as(f32, @floatFromInt(advance)) * frame_duration;
            self.anim_index += advance;
            if (self.anim_index >= self.anim.cells.len) {
                if (self.anim.loops) {
                    self.anim_index %= self.anim.cells.len;
                } else {
                    self.anim_index = self.anim.cells.len - 1;
                }
            }
        }
        return self.anim.cells[self.anim_index];
    }
};

fn moveInput() Vec2 {
    return input.getVector("left", "right", "up", "down", .square);
}

fn clampf(v: f32, lo: f32, hi: f32) f32 {
    return std.math.clamp(v, lo, hi);
}

fn dashAnimFor(dir: Vec2) Anim {
    if (dir.x != 0 and dir.y < 0) return anim_dash_diag_up;
    if (dir.x != 0 and dir.y > 0) return anim_dash_diag_down;
    if (dir.y < 0) return anim_dash_up;
    if (dir.y > 0) return anim_dash_down;
    if (dir.x != 0) return anim_dash_side;
    return anim_dash_none;
}

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
    map = try pxl.assets.loadTilemap(.ldtk);
    if (map.root.defs) |defs| {
        for (defs.tilesets) |tileset| {
            if (tileset.relPath) |rel_path| {
                var path_buf: [512]u8 = undefined;
                const path = std.fmt.bufPrintZ(&path_buf, "assets/maps/{s}", .{rel_path}) catch return error.NameTooLong;
                const id = pxl.assets.findTextureId(path) orelse {
                    std.debug.print("tileset texture not in asset manifest: {s}\n", .{path});
                    return error.AssetNotFound;
                };
                const tex = try pxl.assets.loadTexture(id);
                try textures.put(tileset.uid, tex.*);
            } else if (tileset.embedAtlas) |atlas| {
                if (atlas == .LdtkIcons) {
                    const id = pxl.assets.findTextureId("assets/maps/ldtk_icons.png") orelse return error.AssetNotFound;
                    const tex = try pxl.assets.loadTexture(id);
                    try textures.put(tileset.uid, tex.*);
                }
            }
        }
    }

    hero_tex = try pxl.assets.loadTexture(.sheet_hero_body1);

    // The IntGrid layer is the collision source (index 2 in ldtk.ldtk).
    for (map.root.levels[0].layerInstances.?) |layer| {
        if (layer.__type == .IntGrid) {
            collision = layer;
            break;
        }
    }

    hero.init(164, 156);

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
    input.addBinding("jump", .key(.z));
    input.addBinding("jump", .gamepadButton(.south));

    input.addBinding("dash", .key(.x));
    input.addBinding("dash", .key(.left_shift));
    input.addBinding("dash", .gamepadButton(.east));

    input.addBinding("grab", .key(.c));
    input.addBinding("grab", .key(.left_control));
    input.addBinding("grab", .gamepadButton(.west));
}

pub fn update() !void {
    hero.update();
    updateCamera();
    feelPanel();
}

fn updateCamera() void {
    const target = hero.rect.center().x + hero.facing * feel.camera_lookahead;
    const blend = 1.0 - std.math.exp(-feel.camera_speed * pxl.time.dt());
    camera.position.x += (target - camera.position.x) * blend;
    camera.position.x = std.math.clamp(camera.position.x, 320, 848 - 320);
}

fn feelPanel() void {
    if (mu.beginWindowEx("Move & Jump", .{ .x = 5, .y = 5, .w = 205, .h = 350 }, .{ .align_center = false })) {
        mu.layoutRow(1, &[_]c_int{-1}, 0);
        _ = mu.checkbox("show debug", &show_debug);
        slider("gravity", &feel.gravity, 0, 4000, 25);
        slider("friction", &feel.friction, 0.8, 0.99, 0.001);
        slider("max speed", &feel.max_speed, 50, 800, 10);
        slider("max fall", &feel.max_fall, 50, 800, 10);
        slider("ground accel", &feel.ground_accel, 0, 3000, 25);
        slider("air accel", &feel.air_accel, 0, 3000, 25);
        slider("jump impulse", &feel.jump_impulse, 100, 800, 10);
        slider("jump gravity", &feel.jump_gravity_scale, 0, 1, 0.05);
        slider("jump hold s", &feel.jump_hold_time, 0, 0.3, 0.01);
        slider("jump cut rate", &feel.jump_cut_rate, 0, 20, 0.5);
        slider("coyote s", &feel.coyote_time, 0, 0.3, 0.01);
        slider("buffer s", &feel.jump_buffer_time, 0, 0.3, 0.01);
        slider("air jumps", &feel.air_jumps, 0, 2, 1);
        mu.endWindow();
    }

    if (mu.beginWindowEx("Dash & Slide", .{ .x = 215, .y = 5, .w = 205, .h = 350 }, .{ .align_center = false })) {
        slider("dash boost", &feel.dash_boost, 0, 300, 5);
        slider("dash accel", &feel.dash_accel, 0, 4000, 25);
        slider("dash speed", &feel.dash_speed, 100, 800, 10);
        slider("dash dur s", &feel.dash_duration, 0.05, 0.8, 0.01);
        slider("dash cd s", &feel.dash_cooldown, 0, 1, 0.01);
        slider("slide accel", &feel.slide_accel, 0, 3000, 25);
        slider("slide dur s", &feel.slide_duration, 0.05, 0.8, 0.01);
        mu.endWindow();
    }

    if (mu.beginWindowEx("Climb", .{ .x = 425, .y = 5, .w = 205, .h = 350 }, .{ .align_center = false })) {
        slider("climb speed", &feel.climb_speed, 20, 300, 5);
        slider("wall stick", &feel.wall_stick, 10, 200, 5);
        slider("wall jump Y", &feel.wall_jump_impulse_y, 100, 800, 10);
        slider("wall jump X", &feel.wall_jump_impulse_x, 100, 800, 10);
        slider("climb hop Y", &feel.climb_hop_impulse, 100, 800, 10);
        slider("climb hop X", &feel.climb_hop_x, 0, 400, 10);
        slider("grab box h", &feel.grab_box_height, 2, 15, 0.5);
        mu.endWindow();
    }
}

fn slider(label: [*:0]const u8, value: *f32, low: f32, high: f32, step: f32) void {
    mu.layoutRow(2, &[_]c_int{ 70, -1 }, 0);
    mu.label(label);
    _ = mu.slider(value, low, high, step);
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = Color.black, .camera = camera });
    renderLevel(map.root.levels[0]);
    drawHero();

    if (show_debug) {
        pxl.dbg.drawHollowRect(hero.rect.pos(), hero.rect.w, hero.rect.h, 1, Color.green);
        const box = hero.wallGrabBox(hero.facing);
        pxl.dbg.drawHollowRect(box.pos(), box.w, box.h, 1, Color.pink);
        pxl.dbg.drawTextFmt("{s} {d:.0},{d:.0}", .{ @tagName(hero.sm.current), hero.vel.x, hero.vel.y }, .init(hero.rect.x, hero.rect.y - 22), Color.yellow);
    }

    pxl.endPass();
}

fn drawHero() void {
    const cell = hero.currentCell();
    const src = Rect.init(@as(f32, @floatFromInt(cell.x)) * 16, @as(f32, @floatFromInt(cell.y)) * 32, 16, 32);
    const feet = Vec2.init(hero.rect.center().x, hero.rect.bottom());
    api.drawSprite(.{ .texture = hero_tex.*, .source = src, .flip_x = hero.facing > 0 }, .{ .pos = feet, .origin = .bottom_center, .scale = .one });
}

pub fn shutdown() !void {
    textures.deinit();
    pxl.assets.destroy(map);
    pxl.assets.destroy(hero_tex);
}

fn renderLevel(level: LDtk.Level) void {
    const layer_instances = level.layerInstances orelse return;

    var i: usize = layer_instances.len;
    while (i > 0) {
        i -= 1;
        const layer = layer_instances[i];
        if (!layer.visible) continue;

        const layer_x: f32 = @floatFromInt(level.worldX + layer.__pxTotalOffsetX);
        const layer_y: f32 = @floatFromInt(level.worldY + layer.__pxTotalOffsetY);

        switch (layer.__type) {
            .Entities => renderEntities(layer, layer_x, layer_y),
            .Tiles, .AutoLayer, .IntGrid => {
                const grid_size: f32 = @floatFromInt(layer.__gridSize);
                const tileset_uid = layer.overrideTilesetUid orelse layer.__tilesetDefUid orelse continue;
                const tex = textures.get(tileset_uid) orelse unreachable;

                for (layer.gridTiles) |tile| drawTile(tile, tex, grid_size, layer_x, layer_y, layer.__opacity);
                for (layer.autoLayerTiles) |tile| drawTile(tile, tex, grid_size, layer_x, layer_y, layer.__opacity);
            },
        }
    }
}

fn drawTile(tile: LDtk.TileInstance, tex: Texture, grid_size: f32, layer_x: f32, layer_y: f32, layer_opacity: f64) void {
    const dest_rect = Rect{
        .x = layer_x + @as(f32, @floatFromInt(tile.px[0])),
        .y = layer_y + @as(f32, @floatFromInt(tile.px[1])),
        .w = grid_size,
        .h = grid_size,
    };

    var src_x: f32 = @floatFromInt(tile.src[0]);
    var src_y: f32 = @floatFromInt(tile.src[1]);
    var src_w: f32 = grid_size;
    var src_h: f32 = grid_size;

    if (tile.isFlippedX()) {
        src_x += src_w;
        src_w = -src_w;
    }
    if (tile.isFlippedY()) {
        src_y += src_h;
        src_h = -src_h;
    }

    const src_rect = Rect{ .x = src_x, .y = src_y, .w = src_w, .h = src_h };
    api.drawTexturedRect(tex, dest_rect, src_rect, Color.fromRgba(1, 1, 1, @floatCast(tile.a * layer_opacity)));
}

fn renderEntities(layer: LDtk.LayerInstance, layer_x: f32, layer_y: f32) void {
    if (layer.__type != .Entities) return;
    for (layer.entityInstances) |entity| renderEntity(entity, layer_x, layer_y);
}

fn renderEntity(entity: LDtk.EntityInstance, layer_x: f32, layer_y: f32) void {
    const width: f32 = @floatFromInt(entity.width);
    const height: f32 = @floatFromInt(entity.height);
    const pivot_x: f32 = @floatCast(entity.__pivot[0]);
    const pivot_y: f32 = @floatCast(entity.__pivot[1]);

    const x: f32 = layer_x + @as(f32, @floatFromInt(entity.px[0])) - (pivot_x * width);
    const y: f32 = layer_y + @as(f32, @floatFromInt(entity.px[1])) - (pivot_y * height);

    if (entity.__tile) |tile| {
        const tex = textures.get(tile.tilesetUid) orelse unreachable;
        api.drawTexturedRect(tex, Rect{ .x = x, .y = y, .w = width, .h = height }, Rect{
            .x = @floatFromInt(tile.x),
            .y = @floatFromInt(tile.y),
            .w = @floatFromInt(tile.w),
            .h = @floatFromInt(tile.h),
        }, Color.white);
    } else {
        var color = parseHexColor(entity.__smartColor);
        color[3] = 0.6;
        api.drawRect(.init(x, y - height), .init(width, height), Color.fromArray(color));
    }
}

fn parseHexColor(hex_str: []const u8) [4]f32 {
    var src = hex_str;
    if (src.len > 0 and src[0] == '#') src = src[1..];
    if (src.len < 6) return .{ 1.0, 0.0, 1.0, 1.0 };

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
