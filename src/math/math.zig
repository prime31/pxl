const std = @import("std");
const math = std.math;

pub const rand = @import("rand.zig");

pub const Color = @import("color.zig").Color;
pub const Edge = @import("edge.zig").Edge;
pub const Rect = @import("rect.zig").Rect;
pub const RectI = @import("rect.zig").RectI;
pub const RectU = @import("rect.zig").RectU;
pub const Axis = enum(u2) { x, y };

pub const Vec2 = @import("vector.zig").Vec2;
pub const Vec3 = @import("vector.zig").Vec3;
pub const Vec4 = @import("vector.zig").Vec4;

pub const Quat = @import("quaternion.zig").Quat;
pub const Mat3 = @import("mat3.zig").Mat3;
pub const Mat32 = @import("mat32.zig").Mat32;
pub const Mat4 = @import("mat4.zig").Mat4;

pub const ease = @import("tween/ease.zig");
pub const interp = @import("tween/interp.zig");
pub const lerp = interp.lerp;
pub const lerpClamped = interp.lerpClamped;

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

/// Converts degrees to radian
pub fn toRadians(deg: anytype) @TypeOf(deg) {
    math.degreesToRadians(deg);
}

/// Converts radian to degree
pub fn toDegrees(rad: anytype) @TypeOf(rad) {
    return math.radiansToDegrees(rad);
}

pub fn isEven(val: anytype) bool {
    std.debug.assert(@typeInfo(@TypeOf(val)) == .Int or @typeInfo(@TypeOf(val)) == .ComptimeInt);
    return @mod(val, 2) == 0;
}

pub fn ifloor(comptime T: type, val: f32) T {
    return @as(T, @intFromFloat(@floor(val)));
}

pub fn iclamp(x: i32, a: i32, b: i32) i32 {
    return @max(a, @min(b, x));
}

// returns true if val is between start and end
pub fn between(val: anytype, start: anytype, end: anytype) bool {
    return start <= val and val <= end;
}

pub fn repeat(t: f32, len: f32) f32 {
    return t - std.math.floor(t / len) * len;
}

pub fn pingpong(t: f32, len: f32) f32 {
    const tt = repeat(t, len * 2);
    return len - @abs(tt - len);
}
