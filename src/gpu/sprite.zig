const std = @import("std");
const pxl = @import("../pxl.zig");
const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const Mat32 = pxl.math.Mat32;
const Texture = @import("texture.zig").Texture;

/// A rectangle in texture pixel space (top-left origin), used for sprite source regions.
pub const Rect = struct { x: f32 = 0, y: f32 = 0, w: f32 = 0, h: f32 = 0 };

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
