const std = @import("std");
const math = std.math;
const meta = std.meta;
const mem = std.mem;
const expectEqual = std.testing.expectEqual;

const Vec3 = @import("vector.zig").Vec3;
const Quat = @import("quaternion.zig").Quat;

/// A column-major 3x3 matrix
/// Note: Column-major means accessing data like m.data[COLUMN][ROW].
pub const Mat3 = extern struct {
    data: [3][3]f32,

    /// Shorthand for identity matrix.
    pub fn identity() Mat3 {
        return .{
            .data = .{
                .{ 1, 0, 0 },
                .{ 0, 1, 0 },
                .{ 0, 0, 1 },
            },
        };
    }

    /// Shorthand for matrix with all zeros.
    pub fn zero() Mat3 {
        return Mat3.set(0);
    }

    /// Set all mat3 values to given value.
    pub fn set(value: f32) Mat3 {
        const data: [9]f32 = @splat(value); // .{value} ** 9;
        return Mat3.fromSlice(&data);
    }

    /// Construct new 3x3 matrix from given slice.
    pub fn fromSlice(data: *const [9]f32) Mat3 {
        return .{
            .data = .{
                data[0..3].*,
                data[3..6].*,
                data[6..9].*,
            },
        };
    }

    /// Negate the given matrix.
    pub fn negate(self: Mat3) Mat3 {
        var result = self;
        for (0..result.data.len) |column| {
            for (0..result.data[column].len) |row| {
                result.data[column][row] = -result.data[column][row];
            }
        }
        return result;
    }

    /// Transpose the given matrix.
    pub fn transpose(self: Mat3) Mat3 {
        var result = self;
        for (0..result.data.len) |column| {
            for (column..result.data[column].len) |row| {
                std.mem.swap(f32, &result.data[column][row], &result.data[row][column]);
            }
        }
        return result;
    }

    pub fn getSlice(self: *const Mat3) *const [3][3]f32 {
        return self.data[0..3];
    }

    /// Return true if two matrices are equals.
    pub fn eql(left: Mat3, right: Mat3) bool {
        return meta.eql(left, right);
    }

    pub fn mulByVec3(self: Mat3, v: Vec3) Vec3 {
        const x = (self.data[0][0] * v.x) + (self.data[1][0] * v.y) + (self.data[2][0] * v.z);
        const y = (self.data[0][1] * v.x) + (self.data[1][1] * v.y) + (self.data[2][1] * v.z);
        const z = (self.data[0][2] * v.x) + (self.data[1][2] * v.y) + (self.data[2][2] * v.z);

        return Vec3.init(x, y, z);
    }

    /// Construct a 3x3 matrix from given axis and angle (in degrees).
    pub fn fromRotation(angle_in_degrees: f32, axis: Vec3) Mat3 {
        var result = Mat3.identity();

        const norm_axis = axis.norm();

        const sin_theta = @sin(math.degreesToRadians(angle_in_degrees));
        const cos_theta = @cos(math.degreesToRadians(angle_in_degrees));
        const cos_value = 1 - cos_theta;

        const x = norm_axis.x;
        const y = norm_axis.y;
        const z = norm_axis.z;

        result.data[0][0] = (x * x * cos_value) + cos_theta;
        result.data[0][1] = (x * y * cos_value) + (z * sin_theta);
        result.data[0][2] = (x * z * cos_value) - (y * sin_theta);

        result.data[1][0] = (y * x * cos_value) - (z * sin_theta);
        result.data[1][1] = (y * y * cos_value) + cos_theta;
        result.data[1][2] = (y * z * cos_value) + (x * sin_theta);

        result.data[2][0] = (z * x * cos_value) + (y * sin_theta);
        result.data[2][1] = (z * y * cos_value) - (x * sin_theta);
        result.data[2][2] = (z * z * cos_value) + cos_theta;

        return result;
    }

    pub fn rotate(self: Mat3, angle_in_degrees: f32, axis: Vec3) Mat3 {
        const rotation_mat = Mat3.fromRotation(angle_in_degrees, axis);
        return Mat3.mul(self, rotation_mat);
    }

    /// Construct a rotation matrix from euler angles (X * Y * Z).
    /// Order matters because matrix multiplication are NOT commutative.
    pub fn fromEulerAngles(euler_angle: Vec3) Mat3 {
        const x = Mat3.fromRotation(euler_angle.x, Vec3.right);
        const y = Mat3.fromRotation(euler_angle.y, Vec3.up);
        const z = Mat3.fromRotation(euler_angle.z, Vec3.forward);

        return z.mul(y.mul(x));
    }

    /// Ortho normalize given matrix.
    pub fn orthoNormalize(self: Mat3) Mat3 {
        const column_1 = Vec3.init(self.data[0][0], self.data[0][1], self.data[0][2]).norm();
        const column_2 = Vec3.init(self.data[1][0], self.data[1][1], self.data[1][2]).norm();
        const column_3 = Vec3.init(self.data[2][0], self.data[2][1], self.data[2][2]).norm();

        var result = self;

        result.data[0][0] = column_1.x;
        result.data[0][1] = column_1.y;
        result.data[0][2] = column_1.z;

        result.data[1][0] = column_2.x;
        result.data[1][1] = column_2.y;
        result.data[1][2] = column_2.z;

        result.data[2][0] = column_3.x;
        result.data[2][1] = column_3.y;
        result.data[2][2] = column_3.z;

        return result;
    }

    /// Return the rotation as Euler angles in degrees.
    /// Taken from Mike Day at Insomniac Games (and `glm` as the same function).
    /// For more details: https://d3cw3dd2w32x2b.cloudfront.net/wp-content/uploads/2012/07/euler-angles1.pdf
    pub fn extractEulerAngles(self: Mat3) Vec3 {
        const m = self.orthoNormalize();

        const theta_x = math.atan2(m.data[1][2], m.data[2][2]);
        const c2 = @sqrt(math.pow(f32, m.data[0][0], 2) + math.pow(f32, m.data[0][1], 2));
        const theta_y = math.atan2(-m.data[0][2], @sqrt(c2));
        const s1 = @sin(theta_x);
        const c1 = @cos(theta_x);
        const theta_z = math.atan2(s1 * m.data[2][0] - c1 * m.data[1][0], c1 * m.data[1][1] - s1 * m.data[2][1]);

        return Vec3.init(math.radiansToDegrees(theta_x), math.radiansToDegrees(theta_y), math.radiansToDegrees(theta_z));
    }

    pub fn fromScale(axis: Vec3) Mat3 {
        var result = Mat3.identity();

        result.data[0][0] = axis.x;
        result.data[1][1] = axis.y;
        result.data[2][2] = axis.z;

        return result;
    }

    pub fn scale(self: Mat3, axis: Vec3) Mat3 {
        const scale_mat = Mat3.fromScale(axis);
        return Mat3.mul(scale_mat, self);
    }

    pub fn extractScale(self: Mat3) Vec3 {
        const scale_x = Vec3.init(self.data[0][0], self.data[0][1], self.data[0][2]);
        const scale_y = Vec3.init(self.data[1][0], self.data[1][1], self.data[1][2]);
        const scale_z = Vec3.init(self.data[2][0], self.data[2][1], self.data[2][2]);

        return Vec3.init(scale_x.len(), scale_y.len(), scale_z.len());
    }

    /// Matrices' multiplication.
    /// Produce a new matrix from given two matrices.
    pub fn mul(left: Mat3, right: Mat3) Mat3 {
        var result = Mat3.identity();
        for (0..result.data.len) |column| {
            for (0..result.data[column].len) |row| {
                var sum: f32 = 0;

                for (0..left.data.len) |left_column| {
                    sum += left.data[left_column][row] * right.data[column][left_column];
                }

                result.data[column][row] = sum;
            }
        }
        return result;
    }

    /// Calculate determinant of the given 3x3 matrix.
    pub fn det(self: Mat3) f32 {
        var s: [3]f32 = undefined;
        s[0] = self.data[0][0] * (self.data[1][1] * self.data[2][2] - self.data[1][2] * self.data[2][1]);
        s[1] = self.data[0][1] * (self.data[1][0] * self.data[2][2] - self.data[1][2] * self.data[2][0]);
        s[2] = self.data[0][2] * (self.data[1][0] * self.data[2][1] - self.data[1][1] * self.data[2][0]);
        return s[0] - s[1] + s[2];
    }

    /// Construct inverse 3x3 from given matrix.
    /// Note: This is not the most efficient way to do this.
    /// TODO: Make it more efficient.
    pub fn inv(self: Mat3) Mat3 {
        var inv_mat: Mat3 = undefined;

        const determ = 1 / det(self);

        inv_mat.data[0][0] = determ * (self.data[1][1] * self.data[2][2] - self.data[1][2] * self.data[2][1]);
        inv_mat.data[0][1] = determ * -(self.data[0][1] * self.data[2][2] - self.data[0][2] * self.data[2][1]);
        inv_mat.data[0][2] = determ * (self.data[0][1] * self.data[1][2] - self.data[0][2] * self.data[1][1]);

        inv_mat.data[1][0] = determ * -(self.data[1][0] * self.data[2][2] - self.data[1][2] * self.data[2][0]);
        inv_mat.data[1][1] = determ * (self.data[0][0] * self.data[2][2] - self.data[0][2] * self.data[2][0]);
        inv_mat.data[1][2] = determ * -(self.data[0][0] * self.data[1][2] - self.data[0][2] * self.data[1][0]);

        inv_mat.data[2][0] = determ * (self.data[1][0] * self.data[2][1] - self.data[1][1] * self.data[2][0]);
        inv_mat.data[2][1] = determ * -(self.data[0][0] * self.data[2][1] - self.data[0][1] * self.data[2][0]);
        inv_mat.data[2][2] = determ * (self.data[0][0] * self.data[1][1] - self.data[0][1] * self.data[1][0]);

        return inv_mat;
    }

    pub fn format(
        self: Mat3,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        for (0..3) |i| {
            try writer.print("({d:.2}, {d:.2}, {d:.2})\n", .{
                self.data[0][i],
                self.data[1][i],
                self.data[2][i],
            });
        }
    }
};

test "zalgebra.Mat3.eql" {
    const a = Mat3.identity();
    const b = Mat3.identity();
    const c = Mat3.zero();

    try expectEqual(Mat3.eql(a, b), true);
    try expectEqual(Mat3.eql(a, c), false);
}

test "zalgebra.Mat3.set" {
    const a = Mat3.set(12);
    const b = Mat3{
        .data = .{
            .{ 12, 12, 12 },
            .{ 12, 12, 12 },
            .{ 12, 12, 12 },
        },
    };

    try expectEqual(a, b);
}

test "zalgebra.Mat3.negate" {
    const a = Mat3{
        .data = .{
            .{ 1, 2, 3 },
            .{ 5, -6, 7 },
            .{ 9, 10, 11 },
        },
    };
    const a_negated = Mat3{
        .data = .{
            .{ -1, -2, -3 },
            .{ -5, 6, -7 },
            .{ -9, -10, -11 },
        },
    };

    try expectEqual(a.negate(), a_negated);
}

test "zalgebra.Mat3.transpose" {
    const a = Mat3{
        .data = .{
            .{ 1, 2, 3 },
            .{ 5, 6, 7 },
            .{ 9, 10, 11 },
        },
    };
    const b = Mat3{
        .data = .{
            .{ 1, 5, 9 },
            .{ 2, 6, 10 },
            .{ 3, 7, 11 },
        },
    };

    try expectEqual(a.transpose(), b);
}

test "zalgebra.Mat3.fromSlice" {
    const data = [_]f32{ 1, 0, 0, 0, 1, 0, 0, 0, 1 };
    const result = Mat3.fromSlice(&data);

    try expectEqual(result, Mat3.identity());
}

test "zalgebra.Mat3.fromScale" {
    const a = Mat3.fromScale(Vec3.init(2, 3, 4));

    try expectEqual(a, Mat3{
        .data = .{
            .{ 2, 0, 0 },
            .{ 0, 3, 0 },
            .{ 0, 0, 4 },
        },
    });
}

test "zalgebra.Mat3.scale" {
    const a = Mat3.fromScale(Vec3.init(2, 3, 4));
    const result = Mat3.scale(a, Vec3.set(2));

    try expectEqual(result, Mat3{
        .data = .{
            .{ 4, 0, 0 },
            .{ 0, 6, 0 },
            .{ 0, 0, 8 },
        },
    });
}

test "zalgebra.Mat3.det" {
    const a: Mat3 = .{
        .data = .{
            .{ 2, 0, 4 },
            .{ 0, 2, 0 },
            .{ 4, 0, 2 },
        },
    };

    try expectEqual(a.det(), -24);
}

test "zalgebra.Mat3.inv" {
    const a: Mat3 = .{
        .data = .{
            .{ 2, 0, 4 },
            .{ 0, 2, 0 },
            .{ 4, 0, 2 },
        },
    };

    try expectEqual(a.inv(), Mat3{
        .data = .{
            .{ -0.1666666716337204, 0, 0.3333333432674408 },
            .{ 0, 0.5, 0 },
            .{ 0.3333333432674408, 0, -0.1666666716337204 },
        },
    });
}

test "zalgebra.Mat3.extractEulerAngles" {
    const a = Mat3.fromEulerAngles(Vec3.init(45, -5, 20));
    try expectEqual(a.extractEulerAngles(), Vec3.init(45.000003814697266, -4.99052524, 19.999998092651367));
}

test "zalgebra.Mat3.extractScale" {
    var a = Mat3.fromScale(Vec3.init(2, 4, 8));
    a = a.scale(Vec3.init(2, 4, 8));

    try expectEqual(a.extractScale(), Vec3.init(4, 16, 64));
}
