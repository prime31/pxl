const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;
const BlendMode = pxl.gpu.BlendMode;
const Vertex = pxl.gpu.Vertex;
const Vec = pxl.util.Vec;
const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;

const Curve = struct {
    points: [4]f32,
    values: [4]f32,

    fn eval(self: *const Curve, t: f32) f32 {
        const clamped = std.math.clamp(t, 0.0, 1.0);
        var i: usize = 0;
        while (i < self.points.len - 1) : (i += 1) {
            const x0 = self.points[i];
            const x1 = self.points[i + 1];
            if (clamped <= x1) {
                const factor = if (@abs(x1 - x0) > 1e-6) (clamped - x0) / (x1 - x0) else 0.0;
                return self.values[i] + (self.values[i + 1] - self.values[i]) * factor;
            }
        }
        return self.values[self.values.len - 1];
    }
};

const ColorCurve = struct {
    points: [3]f32,
    colors: [3]Color,

    fn eval(self: *const ColorCurve, t: f32) Color {
        const clamped = std.math.clamp(t, 0.0, 1.0);
        var i: usize = 0;
        while (i < self.points.len - 1) : (i += 1) {
            const x0 = self.points[i];
            const x1 = self.points[i + 1];
            if (clamped <= x1) {
                const factor = if (@abs(x1 - x0) > 1e-6) (clamped - x0) / (x1 - x0) else 0.0;
                return lerpColor(self.colors[i], self.colors[i + 1], factor);
            }
        }
        return self.colors[self.colors.len - 1];
    }
};

fn lerpColor(start: Color, end: Color, t: f32) Color {
    const clamped = std.math.clamp(t, 0.0, 1.0);
    const s = start.asArray();
    const e = end.asArray();
    return Color.fromArray(.{
        s[0] + (e[0] - s[0]) * clamped,
        s[1] + (e[1] - s[1]) * clamped,
        s[2] + (e[2] - s[2]) * clamped,
        s[3] + (e[3] - s[3]) * clamped,
    });
}

const RibbonEdge = struct {
    left: Vec2,
    right: Vec2,
    color: Color,
};

const max_ribbon_points = 140;
const max_ribbon_verts = max_ribbon_points * 2;
const max_ribbon_indices = (max_ribbon_points - 1) * 6;

const Trail = struct {
    positions: Vec(Vec2),
    last_vertex_at: Vec2,
    trail_length: f32,
    width: f32,
    min_point_distance: f32,
    color_start: Color,
    color_end: Color,
    max_vertices: usize,
    fade_start_distance: f32,
    fade_end_distance: f32,
    width_curve: Curve,
    color_curve: ?ColorCurve,
    blend_mode: BlendMode,
    is_enabled: bool,

    fn init(width: f32, trail_length: f32, color_start: Color, color_end: Color) !Trail {
        var positions: Vec(Vec2) = .empty;
        positions.ensureTotalCapacity(128);
        return .{
            .positions = positions,
            .last_vertex_at = Vec2.zero,
            .trail_length = trail_length,
            .width = width,
            .min_point_distance = 8.0,
            .color_start = color_start,
            .color_end = color_end,
            .max_vertices = 64,
            .fade_start_distance = trail_length * 0.35,
            .fade_end_distance = trail_length * 0.85,
            .width_curve = .{
                .points = .{ 0.0, 0.35, 0.75, 1.0 },
                .values = .{ 0.15, 0.8, 0.95, 0.0 },
            },
            .color_curve = .{
                .points = .{ 0.0, 0.5, 1.0 },
                .colors = .{ color_start, Color.fromRgba(1.0, 0.85, 0.2, 0.95), color_end },
            },
            .blend_mode = .blend,
            .is_enabled = true,
        };
    }

    fn deinit(self: *Trail) void {
        self.positions.deinit();
    }

    fn clear(self: *Trail) void {
        self.positions.clearRetainingCapacity();
        self.last_vertex_at = Vec2.zero;
    }

    fn update(self: *Trail, position: Vec2) void {
        if (self.is_enabled) {
            const delta = position.sub(self.last_vertex_at);
            const dx = delta.x;
            const dy = delta.y;
            const distance = @sqrt(dx * dx + dy * dy);
            const min_vertex_distance = self.min_point_distance;

            if (self.positions.items.len == 0) {
                self.positions.append(position);
                self.last_vertex_at = position;
            } else if (distance > min_vertex_distance) {
                const num_steps = @max(1, @as(usize, @intFromFloat(@ceil(distance / min_vertex_distance))));
                var i: usize = 1;
                while (i <= num_steps) : (i += 1) {
                    const t = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(num_steps));
                    const interpolated = self.last_vertex_at.scale(1.0 - t).add(position.scale(t));
                    self.positions.append(interpolated);
                }

                while (self.positions.items.len > 2 and self.totalDistance() > self.trail_length) {
                    _ = self.positions.orderedRemove(0);
                }
                while (self.positions.items.len > self.max_vertices) {
                    _ = self.positions.orderedRemove(0);
                }
                self.last_vertex_at = position;
            }
        } else if (self.positions.items.len > 0) {
            const first = self.positions.items[0];
            const dx = position.x - first.x;
            const dy = position.y - first.y;
            const distance_to_head = @sqrt(dx * dx + dy * dy);
            while (self.positions.items.len > 1 and distance_to_head > self.trail_length) {
                _ = self.positions.orderedRemove(0);
            }
        }
    }

    fn totalDistance(self: *const Trail) f32 {
        var total: f32 = 0.0;
        var i: usize = 0;
        while (i + 1 < self.positions.items.len) : (i += 1) {
            const a = self.positions.items[i];
            const b = self.positions.items[i + 1];
            const dx = b.x - a.x;
            const dy = b.y - a.y;
            total += @sqrt(dx * dx + dy * dy);
        }
        return total;
    }

    fn direction(a: Vec2, b: Vec2) Vec2 {
        const delta = b.sub(a);
        const len_sq = delta.dot(delta);
        if (len_sq <= 1e-6) return Vec2.zero;
        return delta.scale(1.0 / @sqrt(len_sq));
    }

    fn perpendicular(v: Vec2) Vec2 {
        return Vec2.init(-v.y, v.x);
    }

    fn pointColor(self: *const Trail, pct: f32) Color {
        const base_col = if (self.color_curve) |curve| curve.eval(pct) else lerpColor(self.color_start, self.color_end, pct);
        const alpha = if (self.is_enabled) 1.0 else @max(0.0, 1.0 - pct * pct);
        const rgba = base_col.asArray();
        return Color.fromRgba(rgba[0], rgba[1], rgba[2], rgba[3] * alpha);
    }

    fn edgeAt(self: *const Trail, index: usize) ?RibbonEdge {
        const count = self.positions.items.len;
        if (count < 2 or index >= count) return null;

        const current = self.positions.items[index];
        var prev_dir = if (index > 0)
            direction(self.positions.items[index - 1], current)
        else
            direction(current, self.positions.items[index + 1]);
        var next_dir = if (index + 1 < count)
            direction(current, self.positions.items[index + 1])
        else
            direction(self.positions.items[index - 1], current);

        if (prev_dir.dot(prev_dir) <= 1e-6) prev_dir = next_dir;
        if (next_dir.dot(next_dir) <= 1e-6) next_dir = prev_dir;
        if (prev_dir.dot(prev_dir) <= 1e-6) return null;

        var tangent = prev_dir.add(next_dir);
        if (tangent.dot(tangent) <= 1e-6) {
            tangent = next_dir;
        } else {
            tangent = tangent.norm();
        }

        const normal = perpendicular(next_dir);
        var miter = perpendicular(tangent);
        if (miter.dot(miter) <= 1e-6) miter = normal;

        const pct = @as(f32, @floatFromInt(index)) / @as(f32, @floatFromInt(count - 1));
        const half_width = self.width * self.width_curve.eval(pct) * 0.5;
        const denom = @abs(miter.dot(normal));
        const miter_len = if (denom > 1e-3)
            @min(half_width / denom, half_width * 2.0)
        else
            half_width;
        const offset = miter.scale(miter_len);
        const color = self.pointColor(pct);

        return .{
            .left = current.add(offset),
            .right = current.sub(offset),
            .color = color,
        };
    }

    fn draw(self: *Trail) void {
        if (self.positions.items.len <= 1) return;

        const point_count = @min(self.positions.items.len, max_ribbon_points);
        if (point_count <= 1) return;

        var verts: [max_ribbon_verts]Vertex = undefined;
        var indices: [max_ribbon_indices]u16 = undefined;
        var vert_count: usize = 0;
        var index_count: usize = 0;

        var i: usize = 0;
        while (i < point_count) : (i += 1) {
            const edge = self.edgeAt(i) orelse continue;
            verts[vert_count] = .{ .pos = edge.left, .uv = Vec2.zero, .col = edge.color };
            verts[vert_count + 1] = .{ .pos = edge.right, .uv = Vec2.zero, .col = edge.color };

            if (i + 1 < point_count) {
                const base: u16 = @intCast(vert_count);
                indices[index_count + 0] = base;
                indices[index_count + 1] = base + 2;
                indices[index_count + 2] = base + 3;
                indices[index_count + 3] = base;
                indices[index_count + 4] = base + 3;
                indices[index_count + 5] = base + 1;
                index_count += 6;
            }

            vert_count += 2;
        }

        api.setBlendMode(self.blend_mode);
        api.pushMesh(.{
            .verts = verts[0..vert_count],
            .indices = indices[0..index_count],
        });
        api.setBlendMode(.blend);

        const tail = self.positions.items[self.positions.items.len - 1];
        api.drawCircle(tail, 5.0, 12, Color.white);
    }
};

var trail: Trail = undefined;

pub fn config() pxl.Config {
    return .{
        .gfx = .{
            .clear_color = Color.fromBytes(8, 10, 20, 255),
        },
    };
}

pub fn setup() !void {
    trail = try Trail.init(18.0, 220.0, Color.fromRgba(0.18, 0.48, 1.0, 1.0), Color.fromRgba(1.0, 0.3, 0.35, 0.0));
    trail.min_point_distance = 8.0;
    trail.max_vertices = 64;
}

pub fn shutdown() !void {
    trail.deinit();
}

pub fn update() !void {
    const mouse = pxl.input.mousePos();

    if (pxl.input.keyPressed(.e)) {
        trail.is_enabled = !trail.is_enabled;
    }

    if (pxl.input.keyPressed(.b)) {
        trail.blend_mode = if (trail.blend_mode == .blend) .add else .blend;
    }

    trail.update(mouse);

    if (pxl.input.keyPressed(.space)) {
        trail.clear();
    }
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = Color.fromBytes(8, 10, 20, 255) });

    const w = pxl.window.renderWidthf();
    const h = pxl.window.renderHeightf();

    var x: f32 = 0;
    while (x <= w) : (x += 24) {
        api.drawLine(.init(x, 0), .init(x, h), 1, Color.fromRgba(0.16, 0.2, 0.28, 0.4));
    }
    var y: f32 = 0;
    while (y <= h) : (y += 24) {
        api.drawLine(.init(0, y), .init(w, y), 1, Color.fromRgba(0.16, 0.2, 0.28, 0.4));
    }

    trail.draw();
    api.drawText(null, .init(12, 12), "Mouse trail. SPACE clears. E toggles trail. B toggles blend/add.", Color.white);

    pxl.endPass();
}
