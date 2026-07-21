const std = @import("std");
const math = std.math;

pub const rand = @import("rand.zig");

pub const Vec2 = @import("vector.zig").Vec2;
pub const Vec3 = @import("vector.zig").Vec3;
pub const Vec4 = @import("vector.zig").Vec4;

pub const Quat = @import("quaternion.zig").Quat;
pub const Mat3 = @import("mat3.zig").Mat3;
pub const Mat4 = @import("mat4.zig").Mat4;

pub const perspective = Mat4.perspective;
pub const perspectiveReversedZ = Mat4.perspectiveReversedZ;
pub const orthographic = Mat4.orthographic;
pub const lookAt = Mat4.lookAt;

/// Linearly map `v` from [from, to] to [map_from, map_to]
pub inline fn linearMap(_v: f32, from: f32, to: f32, map_from: f32, map_to: f32) f32 {
    const v = if (from < to) math.clamp(_v, from, to) else math.clamp(_v, to, from);
    return map_from + (map_to - map_from) * (v - from) / (to - from);
}

/// Smoothly map from [from, to] to [map_from, map_to], checkout link https://en.wikipedia.org/wiki/Smoothstep
pub inline fn smoothMap(_v: f32, from: f32, to: f32, map_from: f32, map_to: f32) f32 {
    const v = if (from < to) math.clamp(_v, from, to) else math.clamp(_v, to, from);
    var step = (v - from) / (to - from);
    step = step * step * (3 - 2 * step); // smooth to [0, 1], using equation: 3x^2 - 2x^3
    return map_from + (map_to - map_from) * step;
}
