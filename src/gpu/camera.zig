const std = @import("std");
const pxl = @import("../pxl.zig");
const Vec2 = pxl.math.Vec2;
const Mat32 = pxl.math.Mat32;

pub const Camera = struct {
    position: Vec2 = .zero,
    rotation: f32 = 0,
    zoom: f32 = 1.0,
    offset: ?Vec2 = null,

    /// Compute the combined view-projection matrix for this camera given target dimensions
    pub fn getMatrix(self: Camera, screen_width: f32, screen_height: f32) Mat32 {
        const off = self.offset orelse Vec2.init(screen_width * 0.5, screen_height * 0.5);
        const projection = Mat32.orthographic(screen_width, screen_height);
        const zoom_val = if (self.zoom == 0) 1.0 else self.zoom;

        const view = Mat32.fromTranslation(off.x, off.y)
            .mul(Mat32.fromRotation(-self.rotation))
            .mul(Mat32.fromScale(zoom_val, zoom_val))
            .mul(Mat32.fromTranslation(-self.position.x, -self.position.y));

        return projection.mul(view);
    }

    /// Convert screen pixel coordinates to world space
    pub fn screenToWorld(self: Camera, screen_pos: Vec2, screen_width: f32, screen_height: f32) Vec2 {
        const off = self.offset orelse Vec2.init(screen_width * 0.5, screen_height * 0.5);
        const zoom_val = if (self.zoom == 0) 1.0 else self.zoom;

        const rel = screen_pos.sub(off);
        const rot_mat = Mat32.fromRotation(self.rotation);
        const unrotated = rot_mat.transformVec2(rel);
        const unscaled = unrotated.scale(1.0 / zoom_val);
        return unscaled.add(self.position);
    }

    /// Convert world coordinates to screen pixel space
    pub fn worldToScreen(self: Camera, world_pos: Vec2, screen_width: f32, screen_height: f32) Vec2 {
        const off = self.offset orelse Vec2.init(screen_width * 0.5, screen_height * 0.5);
        const zoom_val = if (self.zoom == 0) 1.0 else self.zoom;

        const rel = world_pos.sub(self.position);
        const scaled = rel.scale(zoom_val);
        const rot_mat = Mat32.fromRotation(-self.rotation);
        const rotated = rot_mat.transformVec2(scaled);
        return rotated.add(off);
    }
};
