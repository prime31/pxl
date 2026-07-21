const std = @import("std");

const math = std.math;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;
const panic = std.debug.panic;

const Mat3 = @import("mat3.zig").Mat3;
const Mat4 = @import("mat4.zig").Mat4;

pub const Vec2 = extern struct {
    x: f32 = 0,
    y: f32 = 0,

    pub fn init(x: f32, y: f32) Vec2 {
        return Vec2{ .x = x, .y = y };
    }

    pub fn fromArray(val: [2]f32) Vec2 {
        return Vec2{ .x = val[0], .y = val[1] };
    }

    pub fn toArray(self: Vec2) [2]f32 {
        return [_]f32{ self.x, self.y };
    }

    pub fn len(v: *const Vec2) f32 {
        return math.sqrt(v.dot(Vec2.init(v.x, v.y)));
    }

    pub fn add(l: *const Vec2, r: Vec2) Vec2 {
        return Vec2{ .x = l.x + r.x, .y = l.y + r.y };
    }

    pub fn sub(l: *const Vec2, r: Vec2) Vec2 {
        return Vec2{ .x = l.x - r.x, .y = l.y - r.y };
    }

    pub fn scale(v: *const Vec2, s: f32) Vec2 {
        return Vec2{ .x = v.x * s, .y = v.y * s };
    }

    pub fn mul(l: *const Vec2, r: Vec2) Vec2 {
        return Vec2{ .x = l.x * r.x, .y = l.y * r.y };
    }

    pub fn norm(v: *const Vec2) Vec2 {
        const l = Vec2.len(v);
        if (l != 0.0) {
            return Vec2{ .x = v.x / l, .y = v.y / l };
        } else {
            return Vec2.zero;
        }
    }

    pub fn dot(v0: *const Vec2, v1: Vec2) f32 {
        return v0.x * v1.x + v0.y * v1.y;
    }

    pub fn angleRadians(self: *const Vec2) f32 {
        return std.math.atan2(f32, self.y, self.x);
    }

    pub fn angleDegrees(self: *const Vec2) f32 {
        return std.math.atan2(f32, self.y, self.x) * (360.0 / (std.math.tau));
    }

    pub fn format(
        self: Vec2,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        _ = fmt;
        try writer.print("Vec2({d}, {d})", .{ self.x, self.y });
    }

    pub const zero = Vec2.init(0.0, 0.0);
    pub const one = Vec2.init(1.0, 1.0);
    pub const x_axis = Vec2.init(1.0, 0.0);
    pub const y_axis = Vec2.init(0.0, 1.0);
};

pub const Vec3 = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,

    pub fn init(x: f32, y: f32, z: f32) Vec3 {
        return .{ .x = x, .y = y, .z = z };
    }

    pub fn fromArray(val: [3]f32) Vec3 {
        return Vec3{ .x = val[0], .y = val[1], .z = val[2] };
    }

    pub fn fromVec4(vec4: Vec4) Vec3 {
        return Vec3.init(vec4.x, vec4.y, vec4.z);
    }

    pub fn fromVector(vec: @Vector(3, f32)) Vec3 {
        return Vec3.init(vec[0], vec[1], vec[2]);
    }

    pub fn toArray(self: Vec3) [3]f32 {
        return [_]f32{ self.x, self.y, self.z };
    }

    pub fn toVector(self: Vec3) @Vector(3, f32) {
        return .{ self.x, self.y, self.z };
    }

    pub fn lerp(start: Vec3, end: Vec3, alpha: f32) Vec3 {
        const t = std.math.clamp(alpha, 0.0, 1.0);
        return start.add((end.sub(start)).scale(t));
    }

    pub fn len(v: Vec3) f32 {
        return math.sqrt(v.dot(Vec3.init(v.x, v.y, v.z)));
    }

    pub fn add(l: Vec3, r: Vec3) Vec3 {
        return Vec3{ .x = l.x + r.x, .y = l.y + r.y, .z = l.z + r.z };
    }

    pub fn set(v: f32) Vec3 {
        return Vec3{ .x = v, .y = v, .z = v };
    }

    pub fn sub(l: Vec3, r: Vec3) Vec3 {
        return Vec3{ .x = l.x - r.x, .y = l.y - r.y, .z = l.z - r.z };
    }

    pub fn scale(v: Vec3, s: f32) Vec3 {
        return Vec3{ .x = v.x * s, .y = v.y * s, .z = v.z * s };
    }

    pub fn mul(l: Vec3, r: Vec3) Vec3 {
        return Vec3{ .x = l.x * r.x, .y = l.y * r.y, .z = l.z * r.z };
    }

    pub fn norm(v: Vec3) Vec3 {
        const l = Vec3.len(v);
        if (l != 0.0) {
            return Vec3{ .x = v.x / l, .y = v.y / l, .z = v.z / l };
        } else {
            return Vec3.zero;
        }
    }

    pub fn cross(v0: Vec3, v1: Vec3) Vec3 {
        return Vec3{ .x = (v0.y * v1.z) - (v0.z * v1.y), .y = (v0.z * v1.x) - (v0.x * v1.z), .z = (v0.x * v1.y) - (v0.y * v1.x) };
    }

    pub fn dot(v0: Vec3, v1: Vec3) f32 {
        return v0.x * v1.x + v0.y * v1.y + v0.z * v1.z;
    }

    pub fn mulMat4(l: Vec3, r: Mat4) Vec3 {
        var res = Vec3.zero;
        res.x += l.x * r.m[0][0];
        res.y += l.x * r.m[0][1];
        res.z += l.x * r.m[0][2];
        res.x += l.y * r.m[1][0];
        res.y += l.y * r.m[1][1];
        res.z += l.y * r.m[1][2];
        res.x += l.z * r.m[2][0];
        res.y += l.z * r.m[2][1];
        res.z += l.z * r.m[2][2];
        res.x += 1.0 * r.m[3][0];
        res.y += 1.0 * r.m[3][1];
        res.z += 1.0 * r.m[3][2];
        return res;
    }

    pub fn rotate(l: Vec3, angle: f32, axis: Vec3) Vec3 {
        // Using the Euler–Rodrigues formula
        const axis_norm = axis.norm();

        const half_angle = math.degreesToRadians(angle) * 0.5;
        const angle_sin = std.math.sin(half_angle);
        const angle_cos = std.math.cos(half_angle);

        const w = axis_norm.scale(angle_sin);
        const wv = w.cross(l.*);
        const wwv = w.cross(wv);

        const swv = wv.scale(angle_cos * 2.0);
        const swwv = wwv.scale(2.0);

        return l.add(swv).add(swwv);
    }

    pub fn min(l: Vec3, r: Vec3) Vec3 {
        return Vec3.init(@min(l.x, r.x), @min(l.y, r.y), @min(l.z, r.z));
    }

    pub fn max(l: Vec3, r: Vec3) Vec3 {
        return Vec3.init(@max(l.x, r.x), @max(l.y, r.y), @max(l.z, r.z));
    }

    pub fn toVec4(v: *const Vec3) Vec4 {
        return Vec4.init(v.x, v.y, v.z, 0.0);
    }

    pub fn format(
        self: Vec3,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        _ = fmt;
        try writer.print("Vec3({d}, {d}, {d})", .{ self.x, self.y, self.z });
    }

    pub const zero = Vec3.init(0.0, 0.0, 0.0);
    pub const one = Vec3.init(1.0, 1.0, 1.0);
    pub const x_axis = Vec3.init(1.0, 0.0, 0.0);
    pub const y_axis = Vec3.init(0.0, 1.0, 0.0);
    pub const z_axis = Vec3.init(0.0, 0.0, 1.0);
    pub const forward = Vec3.init(0.0, 0.0, 1.0);
    pub const up = Vec3.init(0.0, 1.0, 0.0);
    pub const down = Vec3.init(0.0, -1.0, 0.0);
    pub const right = Vec3.init(1.0, 0.0, 0.0);
    pub const left = Vec3.init(-1.0, 0.0, 0.0);
};

pub const Vec4 = extern struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub fn init(x: f32, y: f32, z: f32, w: f32) Vec4 {
        return Vec4{ .x = x, .y = y, .z = z, .w = w };
    }

    pub fn fromArray(val: [4]f32) Vec4 {
        return Vec4{ .x = val[0], .y = val[1], .z = val[2], .w = val[3] };
    }

    pub fn toArray(self: Vec4) [4]f32 {
        return [_]f32{ self.x, self.y, self.z, self.w };
    }

    pub fn add(left: *const Vec4, right: Vec4) Vec3 {
        return Vec4{ .x = left.x + right.x, .y = left.y + right.y, .z = left.z + right.z, .w = left.w + right.w };
    }

    pub fn sub(left: *const Vec4, right: Vec4) Vec3 {
        return Vec4{ .x = left.x - right.x, .y = left.y - right.y, .z = left.z - right.z, .w = left.w - right.w };
    }

    pub fn scale(v: *const Vec4, s: f32) Vec4 {
        return Vec4{ .x = v.x * s, .y = v.y * s, .z = v.z * s, .w = v.w * s };
    }

    pub fn mul(left: *const Vec4, right: Vec4) Vec4 {
        return Vec4{ .x = left.x * right.x, .y = left.y * right.y, .z = left.z * right.z, .w = left.w * right.w };
    }

    pub fn projMat4(v: *const Vec4, self: Mat4) Vec4 {
        const inv_w = 1.0 / (v.x * self.m[0][3] + v.y * self.m[1][3] + v.z * self.m[2][3] + self.m[3][3]);

        const x = (self.m[0][0] * v.x) + (self.m[1][0] * v.y) + (self.m[2][0] * v.z) + (self.m[3][0] * v.w);
        const y = (self.m[0][1] * v.x) + (self.m[1][1] * v.y) + (self.m[2][1] * v.z) + (self.m[3][1] * v.w);
        const z = (self.m[0][2] * v.x) + (self.m[1][2] * v.y) + (self.m[2][2] * v.z) + (self.m[3][2] * v.w);
        const w = (self.m[0][3] * v.x) + (self.m[1][3] * v.y) + (self.m[2][3] * v.z) + (self.m[3][3] * v.w);

        return Vec4.init(x * inv_w, y * inv_w, z * inv_w, w);
    }

    pub fn mulMat4(left: *const Vec4, right: Mat4) Vec4 {
        var res = Vec4.zero;
        res.x += left.x * right.m[0][0];
        res.y += left.x * right.m[0][1];
        res.z += left.x * right.m[0][2];
        res.w += left.x * right.m[0][3];
        res.x += left.y * right.m[1][0];
        res.y += left.y * right.m[1][1];
        res.z += left.y * right.m[1][2];
        res.w += left.y * right.m[1][3];
        res.x += left.z * right.m[2][0];
        res.y += left.z * right.m[2][1];
        res.z += left.z * right.m[2][2];
        res.w += left.z * right.m[2][3];
        res.x += left.w * right.m[3][0];
        res.y += left.w * right.m[3][1];
        res.z += left.w * right.m[3][2];
        res.w += left.w * right.m[3][3];
        return res;
    }

    pub fn len(self: *const Vec4) f32 {
        const v = Vec3.init(self.x, self.y, self.z);
        return math.sqrt(v.dot(Vec3.init(v.x, v.y, v.z)));
    }

    pub fn norm(v: *const Vec4) Vec4 {
        const l = Vec4.len(v);
        if (l != 0.0) {
            return Vec4{ .x = v.x / l, .y = v.y / l, .z = v.z / l, .w = v.w / l };
        } else {
            return Vec4.init(0, 0, 0, 0);
        }
    }

    pub fn toVec3(v: *const Vec4) Vec3 {
        return Vec3.init(v.x, v.y, v.z);
    }

    pub const zero = Vec4.init(0.0, 0.0, 0.0, 1.0);
};

// pub fn GenericVector(comptime dimensions: comptime_int, comptime T: type) type {
//     if (@typeInfo(T) != .float and @typeInfo(T) != .int) {
//         @compileError("Vectors not implemented for " ++ @typeName(T));
//     }

//     if (dimensions < 2 or dimensions > 4) {
//         @compileError("Dimensions must be 2, 3 or 4!");
//     }

//     return extern struct {
//         const Self = @This();
//         const Data = @Vector(dimensions, T);

//         data: Data = @splat(0),

//         pub const Component = switch (dimensions) {
//             2 => enum { x, y },
//             3 => enum { x, y, z },
//             4 => enum { x, y, z, w },
//             else => unreachable,
//         };

//         pub usingnamespace switch (dimensions) {
//             2 => extern struct {
//                 pub inline fn init(vx: T, vy: T) Self {
//                     return .{ .data = [2]T{ vx, vy } };
//                 }

//                 /// Rotate vector by angle (in degrees)
//                 pub fn rotate(self: Self, angle_in_degrees: T) Self {
//                     const sin_theta = @sin(math.degreesToRadians(angle_in_degrees));
//                     const cos_theta = @cos(math.degreesToRadians(angle_in_degrees));
//                     return .{ .data = [2]T{
//                         cos_theta * self.x() - sin_theta * self.y(),
//                         sin_theta * self.x() + cos_theta * self.y(),
//                     } };
//                 }

//                 pub inline fn toVec3(self: Self, vz: T) GenericVector(3, T) {
//                     return GenericVector(3, T).fromVec2(self, vz);
//                 }

//                 pub inline fn toVec4(self: Self, vz: T, vw: T) GenericVector(4, T) {
//                     return GenericVector(4, T).fromVec2(self, vz, vw);
//                 }

//                 pub inline fn fromVec3(vec3: GenericVector(3, T)) Self {
//                     return Self.init(vec3.x(), vec3.y());
//                 }

//                 pub inline fn fromVec4(vec4: GenericVector(4, T)) Self {
//                     return Self.init(vec4.x(), vec4.y());
//                 }
//             },
//             3 => extern struct {
//                 pub inline fn init(vx: T, vy: T, vz: T) Self {
//                     return .{ .data = [3]T{ vx, vy, vz } };
//                 }

//                 pub inline fn z(self: Self) T {
//                     return self.data[2];
//                 }

//                 pub inline fn zMut(self: *Self) *T {
//                     return &self.data[2];
//                 }

//                 /// Shorthand for (0, 0, 1).
//                 pub fn forward() Self {
//                     return init(0, 0, 1);
//                 }

//                 /// Shorthand for (0, 0, -1).
//                 pub fn back() Self {
//                     return forward().negate();
//                 }

//                 /// Construct the cross product (as vector) from two vectors.
//                 pub fn cross(first_vector: Self, second_vector: Self) Self {
//                     const x1 = first_vector.x();
//                     const y1 = first_vector.y();
//                     const z1 = first_vector.z();

//                     const x2 = second_vector.x();
//                     const y2 = second_vector.y();
//                     const z2 = second_vector.z();

//                     const result_x = (y1 * z2) - (z1 * y2);
//                     const result_y = (z1 * x2) - (x1 * z2);
//                     const result_z = (x1 * y2) - (y1 * x2);
//                     return init(result_x, result_y, result_z);
//                 }

//                 pub inline fn toVec2(self: Self) GenericVector(2, T) {
//                     return GenericVector(2, T).fromVec3(self);
//                 }

//                 pub inline fn toVec4(self: Self, vw: T) GenericVector(4, T) {
//                     return GenericVector(4, T).fromVec3(self, vw);
//                 }

//                 pub inline fn fromVec2(vec2: GenericVector(2, T), vz: T) Self {
//                     return Self.init(vec2.x(), vec2.y(), vz);
//                 }

// pub inline fn fromVec4(vec4: GenericVector(4, T)) Self {
//     return Self.init(vec4.x(), vec4.y(), vec4.z());
// }
//             },
//             4 => extern struct {
//                 /// Construct new vector.
//                 pub inline fn init(vx: T, vy: T, vz: T, vw: T) Self {
//                     return .{ .data = [4]T{ vx, vy, vz, vw } };
//                 }

//                 /// Shorthand for (0, 0, 1, 0).
//                 pub fn forward() Self {
//                     return init(0, 0, 1, 0);
//                 }

//                 /// Shorthand for (0, 0, -1, 0).
//                 pub fn back() Self {
//                     return forward().negate();
//                 }

//                 pub inline fn z(self: Self) T {
//                     return self.data[2];
//                 }

//                 pub inline fn w(self: Self) T {
//                     return self.data[3];
//                 }

//                 pub inline fn zMut(self: *Self) *T {
//                     return &self.data[2];
//                 }

//                 pub inline fn wMut(self: *Self) *T {
//                     return &self.data[3];
//                 }

//                 pub inline fn toVec2(self: Self) GenericVector(2, T) {
//                     return GenericVector(2, T).fromVec4(self);
//                 }

//                 pub inline fn toVec3(self: Self) GenericVector(3, T) {
//                     return GenericVector(3, T).fromVec4(self);
//                 }

//                 pub inline fn fromVec2(vec2: GenericVector(2, T), vz: T, vw: T) Self {
//                     return Self.init(vec2.x(), vec2.y(), vz, vw);
//                 }

//                 pub inline fn fromVec3(vec3: GenericVector(3, T), vw: T) Self {
//                     return Self.init(vec3.x(), vec3.y(), vec3.z(), vw);
//                 }
//             },
//             else => unreachable,
//         };

//         pub inline fn x(self: Self) T {
//             return self.data[0];
//         }

//         pub inline fn y(self: Self) T {
//             return self.data[1];
//         }

//         pub inline fn xMut(self: *Self) *T {
//             return &self.data[0];
//         }

//         pub inline fn yMut(self: *Self) *T {
//             return &self.data[1];
//         }

//         /// Set all components to the same given value.
//         pub fn set(val: T) Self {
//             const result: Data = @splat(val);
//             return .{ .data = result };
//         }

//         /// Shorthand for (0..).
//         pub fn zero() Self {
//             return set(0);
//         }

//         /// Shorthand for (1..).
//         pub fn one() Self {
//             return set(1);
//         }

//         /// Shorthand for (0, 1).
//         pub fn up() Self {
//             return switch (dimensions) {
//                 2 => Self.init(0, 1),
//                 3 => Self.init(0, 1, 0),
//                 4 => Self.init(0, 1, 0, 0),
//                 else => unreachable,
//             };
//         }

//         /// Shorthand for (0, -1).
//         pub fn down() Self {
//             return up().negate();
//         }

//         /// Shorthand for (1, 0).
//         pub fn right() Self {
//             return switch (dimensions) {
//                 2 => Self.init(1, 0),
//                 3 => Self.init(1, 0, 0),
//                 4 => Self.init(1, 0, 0, 0),
//                 else => unreachable,
//             };
//         }

//         /// Shorthand for (-1, 0).
//         pub fn left() Self {
//             return right().negate();
//         }

//         /// Negate the given vector.
//         pub fn negate(self: Self) Self {
//             return self.scale(-1);
//         }

//         /// Cast a type to another type.
//         /// It's like builtins: @intCast, @floatCast, @floatFromInt, @intFromFloat.
//         pub fn cast(self: Self, comptime dest_type: type) GenericVector(dimensions, dest_type) {
//             const dest_info = @typeInfo(dest_type);

//             if (dest_info != .float and dest_info != .int) {
//                 panic("Error, dest type should be integer or float.\n", .{});
//             }

//             var result: [dimensions]dest_type = undefined;

//             for (result, 0..) |_, i| {
//                 result[i] = math.lossyCast(dest_type, self.data[i]);
//             }
//             return .{ .data = result };
//         }

//         /// Construct new vector from slice.
//         pub fn fromSlice(slice: []const T) Self {
//             const result = slice[0..dimensions].*;
//             return .{ .data = result };
//         }

//         pub fn fromArray(array: [dimensions]T) Self {
//             return .{ .data = array };
//         }

//         /// Transform vector to array.
//         pub fn toArray(self: Self) [dimensions]T {
//             return self.data;
//         }

//         /// Return the angle (in degrees) between two vectors.
//         pub fn getAngle(first_vector: Self, second_vector: Self) T {
//             const dot_product = dot(norm(first_vector), norm(second_vector));
//             return math.radiansToDegrees(math.acos(dot_product));
//         }

//         /// Return the length (magnitude) of given vector.
//         /// √[x^2 + y^2 + z^2 ...]
//         pub fn length(self: Self) T {
//             return @sqrt(self.dot(self));
//         }

//         /// Return the length (magnitude) squared of given vector.
//         /// x^2 + y^2 + z^2 ...
//         pub fn lengthSq(self: Self) T {
//             return self.dot(self);
//         }

//         /// Return the distance between two points.
//         /// √[(x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2 ...]
//         pub fn distance(first_vector: Self, second_vector: Self) T {
//             return length(first_vector.sub(second_vector));
//         }

//         /// Construct new normalized vector from a given one.
//         pub fn norm(self: Self) Self {
//             const l = self.length();
//             if (l == 0) {
//                 return self;
//             }
//             const result = self.data / @as(Data, @splat(l));
//             return .{ .data = result };
//         }

//         /// Return true if two vectors are equals.
//         pub fn eql(first_vector: Self, second_vector: Self) bool {
//             return @reduce(.And, first_vector.data == second_vector.data);
//         }

//         /// Substraction between two given vector.
//         pub fn sub(first_vector: Self, second_vector: Self) Self {
//             const result = first_vector.data - second_vector.data;
//             return .{ .data = result };
//         }

//         /// Addition betwen two given vector.
//         pub fn add(first_vector: Self, second_vector: Self) Self {
//             const result = first_vector.data + second_vector.data;
//             return .{ .data = result };
//         }

//         /// Component wise multiplication betwen two given vector.
//         pub fn mul(first_vector: Self, second_vector: Self) Self {
//             const result = first_vector.data * second_vector.data;
//             return .{ .data = result };
//         }

//         /// Component wise division betwen two given vector.
//         pub fn div(first_vector: Self, second_vector: Self) Self {
//             const result = first_vector.data / second_vector.data;
//             return .{ .data = result };
//         }

//         /// Construct vector from the max components in two vectors
//         pub fn max(first_vector: Self, second_vector: Self) Self {
//             const result = @max(first_vector.data, second_vector.data);
//             return .{ .data = result };
//         }

//         /// Construct vector from the min components in two vectors
//         pub fn min(first_vector: Self, second_vector: Self) Self {
//             const result = @min(first_vector.data, second_vector.data);
//             return .{ .data = result };
//         }

//         /// Construct new vector after multiplying each components by a given scalar
//         pub fn scale(self: Self, scalar: T) Self {
//             const result = self.data * @as(Data, @splat(scalar));
//             return .{ .data = result };
//         }

//         /// Return the dot product between two given vector.
//         /// (x1 * x2) + (y1 * y2) + (z1 * z2) ...
//         pub fn dot(first_vector: Self, second_vector: Self) T {
//             return @reduce(.Add, first_vector.data * second_vector.data);
//         }

//         /// Linear interpolation between two vectors
//         pub fn lerp(first_vector: Self, second_vector: Self, t: T) Self {
//             const from = first_vector.data;
//             const to = second_vector.data;

//             const result = from + (to - from) * @as(Data, @splat(t));
//             return .{ .data = result };
//         }

//         pub fn swizzle(self: Self, comptime comps: []const u8) SwizzleType(comps.len) {
//             if (comps.len == 1) {
//                 return self.data[@intFromEnum(@field(Component, &.{comps[0]}))];
//             }

//             var result = GenericVector(comps.len, T).zero();
//             inline for (comps, 0..) |comp, i| {
//                 result.data[i] = self.data[@intFromEnum(@field(Component, &.{comp}))];
//             }
//             return result;
//         }

//         fn SwizzleType(comps_len: usize) type {
//             return switch (comps_len) {
//                 1 => T,
//                 else => GenericVector(comps_len, T),
//             };
//         }
//     };
// }
