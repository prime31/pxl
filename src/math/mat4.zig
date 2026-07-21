const std = @import("std");
const math = std.math;
const meta = std.meta;
const mem = std.mem;
const expectEqual = std.testing.expectEqual;

const Vec3 = @import("vector.zig").Vec3;
const Vec4 = @import("vector.zig").Vec4;
const Quat = @import("quaternion.zig").Quat;

pub const perspective = Mat4.perspective;
pub const perspectiveReversedZ = Mat4.perspectiveReversedZ;
pub const orthographic = Mat4.orthographic;
pub const lookAt = Mat4.lookAt;

/// A column-major 4x4 matrix
/// Note: Column-major means accessing data like m.data[COLUMN][ROW].
pub const Mat4 = extern struct {
    data: [4][4]f32,

    /// Shorthand for identity matrix.
    pub fn identity() Mat4 {
        return .{
            .data = .{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 0, 0, 0, 1 },
            },
        };
    }

    /// Shorthand for matrix with all zeros.
    pub fn zero() Mat4 {
        return Mat4.set(0);
    }

    /// Set all mat4 values to given value.
    pub fn set(value: f32) Mat4 {
        const data: [16]f32 = @splat(value); // ** 16;
        return Mat4.fromSlice(&data);
    }

    /// Construct new 4x4 matrix from given slice.
    pub fn fromSlice(data: *const [16]f32) Mat4 {
        return .{
            .data = .{
                data[0..4].*,
                data[4..8].*,
                data[8..12].*,
                data[12..16].*,
            },
        };
    }

    /// Negate the given matrix.
    pub fn negate(self: Mat4) Mat4 {
        var result = self;
        for (0..result.data.len) |column| {
            for (0..result.data[column].len) |row| {
                result.data[column][row] = -result.data[column][row];
            }
        }
        return result;
    }

    /// Transpose the given matrix.
    pub fn transpose(self: Mat4) Mat4 {
        var result = self;
        for (0..result.data.len) |column| {
            for (column..4) |row| {
                std.mem.swap(f32, &result.data[column][row], &result.data[row][column]);
            }
        }
        return result;
    }

    pub fn getSlice(self: *const Mat4) *const [4][4]f32 {
        return self.data[0..4];
    }

    /// Return true if two matrices are equals.
    pub fn eql(left: Mat4, right: Mat4) bool {
        return meta.eql(left, right);
    }

    pub fn mulByVec4(self: Mat4, v: Vec4) Vec4 {
        const x = (self.data[0][0] * v.x) + (self.data[1][0] * v.y) + (self.data[2][0] * v.z) + (self.data[3][0] * v.w);
        const y = (self.data[0][1] * v.x) + (self.data[1][1] * v.y) + (self.data[2][1] * v.z) + (self.data[3][1] * v.w);
        const z = (self.data[0][2] * v.x) + (self.data[1][2] * v.y) + (self.data[2][2] * v.z) + (self.data[3][2] * v.w);
        const w = (self.data[0][3] * v.x) + (self.data[1][3] * v.y) + (self.data[2][3] * v.z) + (self.data[3][3] * v.w);

        return Vec4.init(x, y, z, w);
    }

    /// Construct 4x4 translation matrix by multiplying identity matrix and
    /// given translation vector.
    pub fn fromTranslate(axis: Vec3) Mat4 {
        var result = Mat4.identity();
        result.data[3][0] = axis.x;
        result.data[3][1] = axis.y;
        result.data[3][2] = axis.z;

        return result;
    }

    /// Make a translation between the given matrix and the given axis.
    pub fn translate(self: Mat4, axis: Vec3) Mat4 {
        const trans_mat = Mat4.fromTranslate(axis);
        return Mat4.mul(trans_mat, self);
    }

    /// Get translation Vec3 from current matrix.
    pub fn extractTranslation(self: Mat4) Vec3 {
        return Vec3.init(self.data[3][0], self.data[3][1], self.data[3][2]);
    }

    /// Construct a 4x4 matrix from given axis and angle (in degrees).
    pub fn fromRotation(angle_in_degrees: f32, axis: Vec3) Mat4 {
        var result = Mat4.identity();

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

    pub fn rotate(self: Mat4, angle_in_degrees: f32, axis: Vec3) Mat4 {
        const rotation_mat = Mat4.fromRotation(angle_in_degrees, axis);
        return Mat4.mul(self, rotation_mat);
    }

    /// Construct a rotation matrix from euler angles (X * Y * Z).
    /// Order matters because matrix multiplication are NOT commutative.
    pub fn fromEulerAngles(euler_angle: Vec3) Mat4 {
        const x = Mat4.fromRotation(euler_angle.x, Vec3.right);
        const y = Mat4.fromRotation(euler_angle.y, Vec3.up);
        const z = Mat4.fromRotation(euler_angle.z, Vec3.forward);

        return z.mul(y.mul(x));
    }

    /// Ortho normalize given matrix.
    pub fn orthoNormalize(self: Mat4) Mat4 {
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
    pub fn extractEulerAngles(self: Mat4) Vec3 {
        const m = self.orthoNormalize();

        const theta_x = math.atan2(m.data[1][2], m.data[2][2]);
        const c2 = @sqrt(math.pow(f32, m.data[0][0], 2) + math.pow(f32, m.data[0][1], 2));
        const theta_y = math.atan2(-m.data[0][2], @sqrt(c2));
        const s1 = @sin(theta_x);
        const c1 = @cos(theta_x);
        const theta_z = math.atan2(s1 * m.data[2][0] - c1 * m.data[1][0], c1 * m.data[1][1] - s1 * m.data[2][1]);

        return Vec3.init(math.radiansToDegrees(theta_x), math.radiansToDegrees(theta_y), math.radiansToDegrees(theta_z));
    }

    pub fn fromScale(axis: Vec3) Mat4 {
        var result = Mat4.identity();

        result.data[0][0] = axis.x;
        result.data[1][1] = axis.y;
        result.data[2][2] = axis.z;

        return result;
    }

    pub fn scale(self: Mat4, axis: Vec3) Mat4 {
        const scale_mat = Mat4.fromScale(axis);
        return Mat4.mul(scale_mat, self);
    }

    pub fn extractScale(self: Mat4) Vec3 {
        const scale_x = Vec3.init(self.data[0][0], self.data[0][1], self.data[0][2]);
        const scale_y = Vec3.init(self.data[1][0], self.data[1][1], self.data[1][2]);
        const scale_z = Vec3.init(self.data[2][0], self.data[2][1], self.data[2][2]);

        return Vec3.init(scale_x.len(), scale_y.len(), scale_z.len());
    }

    /// Construct a perspective 4x4 matrix.
    /// Note: Field of view is given in degrees.
    /// Also for more details https://www.khronos.org/registry/OpenGL-Refpages/gl2.1/xhtml/gluPerspective.xml.
    pub fn perspective(fovy_in_degrees: f32, aspect_ratio: f32, z_near: f32, z_far: f32) Mat4 {
        var result = Mat4.identity();

        const f = 1 / @tan(math.degreesToRadians(fovy_in_degrees) * 0.5);

        result.data[0][0] = f / aspect_ratio;
        result.data[1][1] = f;
        result.data[2][2] = (z_near + z_far) / (z_near - z_far);
        result.data[2][3] = -1;
        result.data[3][2] = 2 * z_far * z_near / (z_near - z_far);
        result.data[3][3] = 0;

        return result;
    }

    /// Construct a perspective 4x4 matrix with reverse Z and infinite far plane.
    /// Note: Field of view is given in degrees.
    /// Also for more details https://www.khronos.org/registry/OpenGL-Refpages/gl2.1/xhtml/gluPerspective.xml.
    /// For Reversed-Z details https://nlguillemot.wordpress.com/2016/12/07/reversed-z-in-opengl/
    pub fn perspectiveReversedZ(fovy_in_degrees: f32, aspect_ratio: f32, z_near: f32) Mat4 {
        var result = Mat4.identity();

        const f = 1 / @tan(math.degreesToRadians(fovy_in_degrees) * 0.5);

        result.data[0][0] = f / aspect_ratio;
        result.data[1][1] = f;
        result.data[2][2] = 0;
        result.data[2][3] = -1;
        result.data[3][2] = z_near;
        result.data[3][3] = 0;

        return result;
    }

    /// Construct an orthographic 4x4 matrix.
    pub fn orthographic(left: f32, right: f32, bottom: f32, top: f32, z_near: f32, z_far: f32) Mat4 {
        var result = Mat4.zero();

        result.data[0][0] = 2 / (right - left);
        result.data[1][1] = 2 / (top - bottom);
        result.data[2][2] = 2 / (z_near - z_far);
        result.data[3][3] = 1;

        result.data[3][0] = (left + right) / (left - right);
        result.data[3][1] = (bottom + top) / (bottom - top);
        result.data[3][2] = (z_far + z_near) / (z_near - z_far);

        return result;
    }

    /// Right-handed lookAt function.
    pub fn lookAt(eye: Vec3, target: Vec3, up: Vec3) Mat4 {
        const f = Vec3.sub(target, eye).norm();
        const s = Vec3.cross(f, up).norm();
        const u = Vec3.cross(s, f);

        var result: Mat4 = undefined;
        result.data[0][0] = s.x;
        result.data[0][1] = u.x;
        result.data[0][2] = -f.x;
        result.data[0][3] = 0;

        result.data[1][0] = s.y;
        result.data[1][1] = u.y;
        result.data[1][2] = -f.y;
        result.data[1][3] = 0;

        result.data[2][0] = s.z;
        result.data[2][1] = u.z;
        result.data[2][2] = -f.z;
        result.data[2][3] = 0;

        result.data[3][0] = -Vec3.dot(s, eye);
        result.data[3][1] = -Vec3.dot(u, eye);
        result.data[3][2] = Vec3.dot(f, eye);
        result.data[3][3] = 1;

        return result;
    }

    /// Matrices' multiplication.
    /// Produce a new matrix from given two matrices.
    pub fn mul(left: Mat4, right: Mat4) Mat4 {
        var result = Mat4.identity();
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

    fn detsubs(self: Mat4) [12]f32 {
        return .{
            self.data[0][0] * self.data[1][1] - self.data[1][0] * self.data[0][1],
            self.data[0][0] * self.data[1][2] - self.data[1][0] * self.data[0][2],
            self.data[0][0] * self.data[1][3] - self.data[1][0] * self.data[0][3],
            self.data[0][1] * self.data[1][2] - self.data[1][1] * self.data[0][2],
            self.data[0][1] * self.data[1][3] - self.data[1][1] * self.data[0][3],
            self.data[0][2] * self.data[1][3] - self.data[1][2] * self.data[0][3],

            self.data[2][0] * self.data[3][1] - self.data[3][0] * self.data[2][1],
            self.data[2][0] * self.data[3][2] - self.data[3][0] * self.data[2][2],
            self.data[2][0] * self.data[3][3] - self.data[3][0] * self.data[2][3],
            self.data[2][1] * self.data[3][2] - self.data[3][1] * self.data[2][2],
            self.data[2][1] * self.data[3][3] - self.data[3][1] * self.data[2][3],
            self.data[2][2] * self.data[3][3] - self.data[3][2] * self.data[2][3],
        };
    }

    /// Calculate determinant of the given 4x4 matrix.
    pub fn det(self: Mat4) f32 {
        const s = detsubs(self);
        return s[0] * s[11] - s[1] * s[10] + s[2] * s[9] + s[3] * s[8] - s[4] * s[7] + s[5] * s[6];
    }

    /// Construct inverse 4x4 from given matrix.
    /// Note: This is not the most efficient way to do this.
    /// TODO: Make it more efficient.
    pub fn inv(self: Mat4) Mat4 {
        var inv_mat: Mat4 = undefined;

        const s = detsubs(self);

        const determ = 1 / (s[0] * s[11] - s[1] * s[10] + s[2] * s[9] + s[3] * s[8] - s[4] * s[7] + s[5] * s[6]);

        inv_mat.data[0][0] = determ * (self.data[1][1] * s[11] - self.data[1][2] * s[10] + self.data[1][3] * s[9]);
        inv_mat.data[0][1] = determ * -(self.data[0][1] * s[11] - self.data[0][2] * s[10] + self.data[0][3] * s[9]);
        inv_mat.data[0][2] = determ * (self.data[3][1] * s[5] - self.data[3][2] * s[4] + self.data[3][3] * s[3]);
        inv_mat.data[0][3] = determ * -(self.data[2][1] * s[5] - self.data[2][2] * s[4] + self.data[2][3] * s[3]);

        inv_mat.data[1][0] = determ * -(self.data[1][0] * s[11] - self.data[1][2] * s[8] + self.data[1][3] * s[7]);
        inv_mat.data[1][1] = determ * (self.data[0][0] * s[11] - self.data[0][2] * s[8] + self.data[0][3] * s[7]);
        inv_mat.data[1][2] = determ * -(self.data[3][0] * s[5] - self.data[3][2] * s[2] + self.data[3][3] * s[1]);
        inv_mat.data[1][3] = determ * (self.data[2][0] * s[5] - self.data[2][2] * s[2] + self.data[2][3] * s[1]);

        inv_mat.data[2][0] = determ * (self.data[1][0] * s[10] - self.data[1][1] * s[8] + self.data[1][3] * s[6]);
        inv_mat.data[2][1] = determ * -(self.data[0][0] * s[10] - self.data[0][1] * s[8] + self.data[0][3] * s[6]);
        inv_mat.data[2][2] = determ * (self.data[3][0] * s[4] - self.data[3][1] * s[2] + self.data[3][3] * s[0]);
        inv_mat.data[2][3] = determ * -(self.data[2][0] * s[4] - self.data[2][1] * s[2] + self.data[2][3] * s[0]);

        inv_mat.data[3][0] = determ * -(self.data[1][0] * s[9] - self.data[1][1] * s[7] + self.data[1][2] * s[6]);
        inv_mat.data[3][1] = determ * (self.data[0][0] * s[9] - self.data[0][1] * s[7] + self.data[0][2] * s[6]);
        inv_mat.data[3][2] = determ * -(self.data[3][0] * s[3] - self.data[3][1] * s[1] + self.data[3][2] * s[0]);
        inv_mat.data[3][3] = determ * (self.data[2][0] * s[3] - self.data[2][1] * s[1] + self.data[2][2] * s[0]);

        return inv_mat;
    }

    /// Return 4x4 matrix from given all transform components; `translation`, `rotation` and `scale`.
    /// The final order is T * R * S.
    /// Note: `rotation` could be `Vec3` (Euler angles) or a `quat`.
    pub fn recompose(translation: Vec3, rotation: anytype, scalar: Vec3) Mat4 {
        var r = switch (@TypeOf(rotation)) {
            Quat => Quat.toMat4(rotation),
            Vec3 => Mat4.fromEulerAngles(rotation),
            else => @compileError("Recompose not implemented for " ++ @typeName(@TypeOf(rotation))),
        };

        r.data[0][0] *= scalar.x;
        r.data[0][1] *= scalar.x;
        r.data[0][2] *= scalar.x;
        r.data[1][0] *= scalar.y;
        r.data[1][1] *= scalar.y;
        r.data[1][2] *= scalar.y;
        r.data[2][0] *= scalar.z;
        r.data[2][1] *= scalar.z;
        r.data[2][2] *= scalar.z;

        r.data[3][0] = translation.x;
        r.data[3][1] = translation.y;
        r.data[3][2] = translation.z;

        return r;
    }

    /// Return `translation`, `rotation` and `scale` components from given matrix.
    /// For now, the rotation returned is a quaternion. If you want to get Euler angles
    /// from it, just do: `returned_quat.extractEulerAngles()`.
    /// Note: We ortho nornalize the given matrix before extracting the rotation.
    pub fn decompose(self: Mat4) struct { t: Vec3, r: Quat, s: Vec3 } {
        const t = self.extractTranslation();
        const s = self.extractScale();
        const r = Quat.fromMat4(self.orthoNormalize());

        return .{
            .t = t,
            .r = r,
            .s = s,
        };
    }

    pub fn format(
        self: Mat4,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        for (0..4) |i| {
            try writer.print("({d:.2}, {d:.2}, {d:.2}, {d:.2})\n", .{
                self.data[0][i],
                self.data[1][i],
                self.data[2][i],
                self.data[3][i],
            });
        }
    }
};

test "zalgebra.Mat4.eql" {
    const a = Mat4.identity();
    const b = Mat4.identity();
    const c = Mat4.zero();

    try expectEqual(Mat4.eql(a, b), true);
    try expectEqual(Mat4.eql(a, c), false);
}

test "zalgebra.Mat4.set" {
    const a = Mat4.set(12);
    const b = Mat4{
        .data = .{
            .{ 12, 12, 12, 12 },
            .{ 12, 12, 12, 12 },
            .{ 12, 12, 12, 12 },
            .{ 12, 12, 12, 12 },
        },
    };

    try expectEqual(a, b);
}

test "zalgebra.Mat4.negate" {
    const a = Mat4{
        .data = .{
            .{ 1, 2, 3, 4 },
            .{ 5, -6, 7, 8 },
            .{ 9, 10, 11, -12 },
            .{ 13, 14, 15, 16 },
        },
    };
    const a_negated = Mat4{
        .data = .{
            .{ -1, -2, -3, -4 },
            .{ -5, 6, -7, -8 },
            .{ -9, -10, -11, 12 },
            .{ -13, -14, -15, -16 },
        },
    };

    try expectEqual(a.negate(), a_negated);
}

test "zalgebra.Mat4.transpose" {
    const a = Mat4{
        .data = .{
            .{ 1, 2, 3, 4 },
            .{ 5, 6, 7, 8 },
            .{ 9, 10, 11, 12 },
            .{ 13, 14, 15, 16 },
        },
    };
    const b = Mat4{
        .data = .{
            .{ 1, 5, 9, 13 },
            .{ 2, 6, 10, 14 },
            .{ 3, 7, 11, 15 },
            .{ 4, 8, 12, 16 },
        },
    };

    try expectEqual(a.transpose(), b);
}

test "zalgebra.Mat4.fromSlice" {
    const data = [_]f32{ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };
    const result = Mat4.fromSlice(&data);

    try expectEqual(result, Mat4.identity());
}

test "zalgebra.Mat4.fromTranslate" {
    const a = Mat4.fromTranslate(Vec3.init(2, 3, 4));

    try expectEqual(a, Mat4{
        .data = .{
            .{ 1, 0, 0, 0 },
            .{ 0, 1, 0, 0 },
            .{ 0, 0, 1, 0 },
            .{ 2, 3, 4, 1 },
        },
    });
}

test "zalgebra.Mat4.translate" {
    const a = Mat4.fromTranslate(Vec3.init(2, 3, 2));
    const result = Mat4.translate(a, Vec3.init(2, 3, 4));

    try expectEqual(result, Mat4{
        .data = .{
            .{ 1, 0, 0, 0 },
            .{ 0, 1, 0, 0 },
            .{ 0, 0, 1, 0 },
            .{ 4, 6, 6, 1 },
        },
    });
}

test "zalgebra.Mat4.fromScale" {
    const a = Mat4.fromScale(Vec3.init(2, 3, 4));

    try expectEqual(a, Mat4{
        .data = .{
            .{ 2, 0, 0, 0 },
            .{ 0, 3, 0, 0 },
            .{ 0, 0, 4, 0 },
            .{ 0, 0, 0, 1 },
        },
    });
}

test "zalgebra.Mat4.scale" {
    const a = Mat4.fromScale(Vec3.init(2, 3, 4));
    const result = Mat4.scale(a, Vec3.set(2));

    try expectEqual(result, Mat4{
        .data = .{
            .{ 4, 0, 0, 0 },
            .{ 0, 6, 0, 0 },
            .{ 0, 0, 8, 0 },
            .{ 0, 0, 0, 1 },
        },
    });
}

test "zalgebra.Mat4.det" {
    const a: Mat4 = .{
        .data = .{
            .{ 2, 0, 0, 4 },
            .{ 0, 2, 0, 0 },
            .{ 0, 0, 2, 0 },
            .{ 4, 0, 0, 2 },
        },
    };

    try expectEqual(a.det(), -48);
}

test "zalgebra.Mat4.inv" {
    const a: Mat4 = .{
        .data = .{
            .{ 2, 0, 0, 4 },
            .{ 0, 2, 0, 0 },
            .{ 0, 0, 2, 0 },
            .{ 4, 0, 0, 2 },
        },
    };

    try expectEqual(a.inv(), Mat4{
        .data = .{
            .{ -0.1666666716337204, 0, 0, 0.3333333432674408 },
            .{ 0, 0.5, 0, 0 },
            .{ 0, 0, 0.5, 0 },
            .{ 0.3333333432674408, 0, 0, -0.1666666716337204 },
        },
    });
}

test "zalgebra.Mat4.extractTranslation" {
    var a = Mat4.fromTranslate(Vec3.init(2, 3, 2));
    a = a.translate(Vec3.init(2, 3, 2));

    try expectEqual(a.extractTranslation(), Vec3.init(4, 6, 4));
}

test "zalgebra.Mat4.extractEulerAngles" {
    const a = Mat4.fromEulerAngles(Vec3.init(45, -5, 20));
    try expectEqual(a.extractEulerAngles(), Vec3.init(45.000003814697266, -4.99052524, 19.999998092651367));
}

test "zalgebra.Mat4.extractScale" {
    var a = Mat4.fromScale(Vec3.init(2, 4, 8));
    a = a.scale(Vec3.init(2, 4, 8));

    try expectEqual(a.extractScale(), Vec3.init(4, 16, 64));
}

test "zalgebra.Mat4.recompose" {
    const result = Mat4.recompose(
        Vec3.set(2),
        Vec3.init(45, 5, 0),
        Vec3.one,
    );

    try expectEqual(result, Mat4{ .data = .{
        .{ 0.9961947202682495, 0, -0.08715573698282242, 0 },
        .{ 0.06162841245532036, 0.7071067690849304, 0.704416036605835, 0 },
        .{ 0.06162841245532036, -0.7071067690849304, 0.704416036605835, 0 },
        .{ 2, 2, 2, 1 },
    } });
}

test "zalgebra.Mat4.decompose" {
    const a = Mat4.recompose(
        Vec3.init(10, 5, 5),
        Vec3.init(45, 5, 0),
        Vec3.set(1),
    );

    const result = a.decompose();

    try expectEqual(result.t, Vec3.init(10, 5, 5));
    try expectEqual(result.s, Vec3.set(1));
    try expectEqual(result.r.extractEulerAngles(), Vec3.init(45, 5, 0.00000010712935250012379));
}
