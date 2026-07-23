const std = @import("std");
const math = std.math;

const Vec2 = @import("vector.zig").Vec2;

/// A 2D affine transform stored as 6 floats (2 rows x 3 columns), the same shape
/// as sokol_gp's `sgp_mat2x3`. This is all a 2D renderer needs: a 2x2 linear part
/// plus a translation. Transforming a point maps
///     (x, y) -> (x*data[0] + y*data[2] + data[4], x*data[1] + y*data[3] + data[5])
///
/// Layout:
///     data[0] = m00   data[2] = m10   data[4] = tx
///     data[1] = m01   data[3] = m11   data[5] = ty
pub const Mat32 = extern struct {
    data: [6]f32 = .{ 1, 0, 0, 1, 0, 0 },

    /// The identity transform.
    pub fn identity() Mat32 {
        return .{ .data = .{ 1, 0, 0, 1, 0, 0 } };
    }

    /// Compose two transforms: `self.mul(r)` applies `r` first, then `self`.
    pub fn mul(self: Mat32, r: Mat32) Mat32 {
        return .{ .data = .{
            r.data[0] * self.data[0] + r.data[1] * self.data[2],
            r.data[0] * self.data[1] + r.data[1] * self.data[3],
            r.data[2] * self.data[0] + r.data[3] * self.data[2],
            r.data[2] * self.data[1] + r.data[3] * self.data[3],
            r.data[4] * self.data[0] + r.data[5] * self.data[2] + self.data[4],
            r.data[4] * self.data[1] + r.data[5] * self.data[3] + self.data[5],
        } };
    }

    /// Transform a point by this matrix (mirrors `_sgp_mat3_vec2_mul`).
    pub fn transformVec2(self: Mat32, v: Vec2) Vec2 {
        return .{
            .x = v.x * self.data[0] + v.y * self.data[2] + self.data[4],
            .y = v.x * self.data[1] + v.y * self.data[3] + self.data[5],
        };
    }

    pub fn fromTranslation(x: f32, y: f32) Mat32 {
        return .{ .data = .{ 1, 0, 0, 1, x, y } };
    }

    pub fn fromScale(x: f32, y: f32) Mat32 {
        return .{ .data = .{ x, 0, 0, y, 0, 0 } };
    }

    pub fn fromRotation(radians: f32) Mat32 {
        const c = @cos(radians);
        const s = @sin(radians);
        return .{ .data = .{ c, s, -s, c, 0, 0 } };
    }

    /// Screen -> clip-space projection for a `width` x `height` framebuffer with the
    /// origin at the top-left and +y pointing down. Matches sokol_gp's `_sgp_default_proj`.
    pub fn orthographic(width: f32, height: f32) Mat32 {
        return .{ .data = .{ 2.0 / width, 0, 0, -2.0 / height, -1, 1 } };
    }

    /// General orthographic projection mapping the given rectangle to clip space.
    /// Matches sokol_gp's `sgp_project`.
    pub fn ortho(left: f32, right: f32, bottom: f32, top: f32) Mat32 {
        const w = right - left;
        const h = top - bottom;
        return .{ .data = .{ 2.0 / w, 0, 0, 2.0 / h, -(right + left) / w, -(top + bottom) / h } };
    }
};

test "Mat32 transform and compose" {
    const t = std.testing;

    const id = Mat32.identity();
    const p = id.transformVec2(.{ .x = 3, .y = 4 });
    try t.expectEqual(@as(f32, 3), p.x);
    try t.expectEqual(@as(f32, 4), p.y);

    // translate then scale (scale applied last): p -> (p + (1,2)) * 2
    const m = Mat32.fromScale(2, 2).mul(Mat32.fromTranslation(1, 2));
    const q = m.transformVec2(.{ .x = 0, .y = 0 });
    try t.expectEqual(@as(f32, 2), q.x);
    try t.expectEqual(@as(f32, 4), q.y);
}
