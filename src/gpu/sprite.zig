const std = @import("std");
const pxl = @import("../pxl.zig");

const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const Mat32 = pxl.math.Mat32;
const Rect = pxl.math.Rect;
const Texture = @import("texture.zig").Texture;

/// A sprite anchor point, center-relative and scaled by the sprite size: center is
/// `(0,0)`, top-left is `(-0.5,-0.5)`, bottom-right is `(0.5,0.5)` (y-down screen space).
pub const Anchor = union(enum) {
    center,
    top_left,
    top_center,
    top_right,
    center_left,
    center_right,
    bottom_left,
    bottom_center,
    bottom_right,
    /// Custom center-relative anchor (same convention as the named ones).
    custom: Vec2,

    pub fn asVec(self: Anchor) Vec2 {
        return switch (self) {
            .center => Vec2.zero,
            .top_left => .init(-0.5, -0.5),
            .top_center => .init(0, -0.5),
            .top_right => .init(0.5, -0.5),
            .center_left => .init(-0.5, 0),
            .center_right => .init(0.5, 0),
            .bottom_left => .init(-0.5, 0.5),
            .bottom_center => .init(0, 0.5),
            .bottom_right => .init(0.5, 0.5),
            .custom => |pt| pt,
        };
    }
};

/// 2D Transform parameters: position, rotation, scale, and origin anchor.
pub const Transform = struct {
    pos: Vec2 = Vec2.zero,
    rotation: f32 = 0,
    scale: Vec2 = Vec2.one,
    origin: Anchor = .center,

    /// Compute local transformation matrix given object dimensions (unscaled)
    pub fn toMatrix(self: Transform, width: f32, height: f32) Mat32 {
        const w = width * self.scale.x;
        const h = height * self.scale.y;

        const a = self.origin.asVec();
        const px = (0.5 + a.x) * w;
        const py = (0.5 + a.y) * h;

        return Mat32.fromTranslation(self.pos.x, self.pos.y)
            .mul(Mat32.fromRotation(self.rotation))
            .mul(Mat32.fromTranslation(-px, -py));
    }
};

/// Parameters for `drawSprite`. Sensible defaults: whole texture, white, centered, no rotation.
pub const Sprite = struct {
    texture: Texture,
    transform: Transform = .{},
    color: Color = Color.white,
    /// Sub-region of the texture in pixels (atlas cell); `null` = the whole texture.
    source: ?Rect = null,
    flip_x: bool = false,
    flip_y: bool = false,
};

pub const LoopMode = enum(u8) { loop, once, clamp_forever, ping_pong, ping_pong_once };
pub const PingPongState = enum(u2) { ping, pong };
pub const State = enum(u8) { none, running, paused, completed };

pub const SpriteAnimationFrame = struct {
    texture: Texture,
    source: Rect,
    frame_time: f32,
};

pub const SpriteAnimation = struct {
    name: []const u8,
    frames: []SpriteAnimationFrame,
    loop_mode: LoopMode,
    state: State,
    ping_pong_state: PingPongState,
    current_frame: usize,
    elapsed_time: f32,
    frame_time_left: f32,

    pub fn update(self: *SpriteAnimation) void {
        if (self.state != .running) return;

        self.elapsed_time += pxl.time.dt();
        self.frame_time_left -= pxl.time.dt();
        if (self.frame_time_left <= 0) {
            switch (self.loop_mode) {
                .loop => self.setFrame((self.current_frame + 1) % self.frames.len),
                .once => self.state = .completed,
                .clamp_forever => self.setFrame(self.current_frame),
                .ping_pong => self.setFrame(if (self.ping_pong_state == .ping) 1 else 0),
                .ping_pong_once => self.setFrame(if (self.ping_pong_state == .ping) 1 else 0),
            }
        }
    }

    fn setFrame(self: *SpriteAnimation, index: usize) void {
        self.current_frame = index;
        self.frame_time_left = self.frames[index].frame_time;
    }
};
