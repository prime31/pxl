const std = @import("std");
const pxl = @import("pxl.zig");
const math = std.math;

const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const Mat32 = pxl.math.Mat32;
const sg = pxl.sg;

const Vertex = pxl.gpu.Vertex;
const BlendMode = pxl.gpu.BlendMode;
const Rect = pxl.gpu.Rect;
const Anchor = pxl.gpu.Anchor;
const Sprite = pxl.gpu.Sprite;
const Texture = pxl.gpu.Texture;

const max_circle_segments = 64;

// ---- Pipeline & Batcher State API ----

pub fn setMatrix(matrix: Mat32) void {
    pxl.batcher.setMatrix(matrix);
}

pub fn setBlendMode(mode: BlendMode) void {
    pxl.batcher.setBlendMode(mode);
}

pub fn setPipeline(pipeline: sg.Pipeline) void {
    pxl.batcher.setPipeline(pipeline);
}

pub fn resetPipeline() void {
    pxl.batcher.resetPipeline();
}

pub fn setUniform(vs: anytype, fs: anytype) void {
    pxl.batcher.setUniform(vs, fs);
}

pub fn setTexture(tex: Texture) void {
    pxl.batcher.setTexture(tex);
}

pub fn makePipeline(shader: sg.Shader, mode: BlendMode) sg.Pipeline {
    return pxl.gpu.Batcher.makePipeline(shader, mode);
}

pub fn pushMesh(verts: []const Vertex, indices: []const u16) void {
    pxl.batcher.pushMesh(verts, indices);
}

// ---- High-Level 2D Drawing API ----

/// Draw a filled triangle using the 1x1 white texture (color only).
pub fn drawTriangle(a: Vec2, b: Vec2, c: Vec2, col: Color) void {
    pxl.batcher.setTexture(pxl.batcher.white);
    const verts = [_]Vertex{
        .{ .pos = a, .uv = Vec2.zero, .col = col },
        .{ .pos = b, .uv = Vec2.zero, .col = col },
        .{ .pos = c, .uv = Vec2.zero, .col = col },
    };
    pxl.batcher.pushMesh(&verts, &.{ 0, 1, 2 });
}

/// Draw a quad from four corner vertices (two triangles).
pub fn drawQuad(verts: [4]Vertex) void {
    pxl.batcher.pushMesh(&verts, &.{ 0, 1, 2, 0, 2, 3 });
}

/// Bind `tex`, then push a quad whose local `corners` are transformed by `model`
/// composed with the current matrix. The matrix is restored afterwards (no flush).
fn drawTexturedQuad(tex: Texture, model: Mat32, corners: [4]Vec2, uvs: [4]Vec2, col: Color) void {
    pxl.batcher.setTexture(tex);
    const saved = pxl.batcher.matrix;
    pxl.batcher.matrix = saved.mul(model);
    drawQuad(.{
        .{ .pos = corners[0], .uv = uvs[0], .col = col },
        .{ .pos = corners[1], .uv = uvs[1], .col = col },
        .{ .pos = corners[2], .uv = uvs[2], .col = col },
        .{ .pos = corners[3], .uv = uvs[3], .col = col },
    });
    pxl.batcher.matrix = saved;
}

const Transform = pxl.gpu.Transform;
const Camera = pxl.gpu.Camera;

/// Draw a textured sprite with position, rotation, scale, pivot and an optional
/// atlas source region (models comfy's `draw_sprite_pro`).
pub fn drawSprite(s: Sprite) void {
    const src = s.source orelse Rect{
        .x = 0,
        .y = 0,
        .w = @floatFromInt(s.texture.width),
        .h = @floatFromInt(s.texture.height),
    };
    const tw: f32 = @floatFromInt(s.texture.width);
    const th: f32 = @floatFromInt(s.texture.height);

    const w = src.w * s.transform.scale.x;
    const h = src.h * s.transform.scale.y;

    const model = s.transform.toMatrix(src.w, src.h);

    const corners = [4]Vec2{
        .init(0, 0),
        .init(w, 0),
        .init(w, h),
        .init(0, h),
    };

    var ul = src.x / tw;
    var vt = src.y / th;
    var ur = (src.x + src.w) / tw;
    var vb = (src.y + src.h) / th;
    if (s.flip_x) std.mem.swap(f32, &ul, &ur);
    if (s.flip_y) std.mem.swap(f32, &vt, &vb);

    const uvs = [4]Vec2{
        .init(ul, vt),
        .init(ur, vt),
        .init(ur, vb),
        .init(ul, vb),
    };

    drawTexturedQuad(s.texture, model, corners, uvs, s.color);
}

/// Draw a texture at its native size with its top-left corner at `position`.
pub fn drawTexture(tex: Texture, position: Vec2) void {
    drawSprite(.{ .texture = tex, .transform = .{ .pos = position, .origin = .top_left } });
}

/// Draw a texture using a Transform and color tint.
pub fn drawTextureEx(tex: Texture, transform: Transform, color: Color) void {
    drawSprite(.{ .texture = tex, .transform = transform, .color = color });
}

/// Draw the `src` pixel region of `tex` into the `dst` world rect (top-left), tinted by
/// `color`. Negative `src.w`/`src.h` flip that axis (matches sokol_gp's textured rects).
pub fn drawTexturedRect(tex: Texture, dst: Rect, src: Rect, color: Color) void {
    const tw: f32 = @floatFromInt(tex.width);
    const th: f32 = @floatFromInt(tex.height);
    const _u0 = src.x / tw;
    const v0 = src.y / th;
    const _u1 = (src.x + src.w) / tw;
    const v1 = (src.y + src.h) / th;
    pxl.batcher.setTexture(tex);
    drawQuad(.{
        .{ .pos = .init(dst.x, dst.y), .uv = .init(_u0, v0), .col = color },
        .{ .pos = .init(dst.x + dst.w, dst.y), .uv = .init(_u1, v0), .col = color },
        .{ .pos = .init(dst.x + dst.w, dst.y + dst.h), .uv = .init(_u1, v1), .col = color },
        .{ .pos = .init(dst.x, dst.y + dst.h), .uv = .init(_u0, v1), .col = color },
    });
}

/// Draw a filled rectangle with position, size, origin alignment, and tint color.
pub fn drawRectEx(pos: Vec2, size: Vec2, origin: Anchor, color: Color) void {
    pxl.batcher.setTexture(pxl.batcher.white);
    const a = origin.asVec(); // center-relative [-0.5, 0.5]
    const ox = (0.5 + a.x) * size.x;
    const oy = (0.5 + a.y) * size.y;
    const x0 = pos.x - ox;
    const y0 = pos.y - oy;
    const x1 = x0 + size.x;
    const y1 = y0 + size.y;

    drawQuad(.{
        .{ .pos = .init(x0, y0), .uv = Vec2.zero, .col = color },
        .{ .pos = .init(x1, y0), .uv = Vec2.zero, .col = color },
        .{ .pos = .init(x1, y1), .uv = Vec2.zero, .col = color },
        .{ .pos = .init(x0, y1), .uv = Vec2.zero, .col = color },
    });
}

/// Draw a filled rectangle with `pos` as its top-left corner.
pub fn drawRect(pos: Vec2, size: Vec2, color: Color) void {
    drawRectEx(pos, size, .top_left, color);
}

/// Draw the outline of a rectangle with position, size, origin alignment, thickness, and color.
pub fn drawRectOutlineEx(pos: Vec2, size: Vec2, origin: Anchor, thickness: f32, color: Color) void {
    pxl.batcher.setTexture(pxl.batcher.white);
    const a = origin.asVec();
    const ox_offset = (0.5 + a.x) * size.x;
    const oy_offset = (0.5 + a.y) * size.y;
    const center_x = pos.x - ox_offset + size.x * 0.5;
    const center_y = pos.y - oy_offset + size.y * 0.5;

    const ht = thickness * 0.5;
    const ox = size.x * 0.5 + ht; // outer half-extents
    const oy = size.y * 0.5 + ht;
    const ix = size.x * 0.5 - ht; // inner half-extents
    const iy = size.y * 0.5 - ht;

    const verts = [8]Vertex{
        // outer TL, TR, BR, BL
        .{ .pos = .init(center_x - ox, center_y - oy), .uv = Vec2.zero, .col = color },
        .{ .pos = .init(center_x + ox, center_y - oy), .uv = Vec2.zero, .col = color },
        .{ .pos = .init(center_x + ox, center_y + oy), .uv = Vec2.zero, .col = color },
        .{ .pos = .init(center_x - ox, center_y + oy), .uv = Vec2.zero, .col = color },
        // inner TL, TR, BR, BL
        .{ .pos = .init(center_x - ix, center_y - iy), .uv = Vec2.zero, .col = color },
        .{ .pos = .init(center_x + ix, center_y - iy), .uv = Vec2.zero, .col = color },
        .{ .pos = .init(center_x + ix, center_y + iy), .uv = Vec2.zero, .col = color },
        .{ .pos = .init(center_x - ix, center_y + iy), .uv = Vec2.zero, .col = color },
    };
    // four border quads (top, right, bottom, left)
    pxl.batcher.pushMesh(&verts, &.{
        0, 1, 5, 0, 5, 4,
        1, 2, 6, 1, 6, 5,
        2, 3, 7, 2, 7, 6,
        3, 0, 4, 3, 4, 7,
    });
}

/// Draw the outline of a rectangle with `pos` as its top-left corner.
pub fn drawRectOutline(pos: Vec2, size: Vec2, thickness: f32, color: Color) void {
    drawRectOutlineEx(pos, size, .top_left, thickness, color);
}

/// Draw a line from `a` to `b` as a thickness-wide quad.
pub fn drawLine(a: Vec2, b: Vec2, thickness: f32, color: Color) void {
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const len = @sqrt(dx * dx + dy * dy);
    if (len < 1e-6) return;

    const s = thickness * 0.5 / len;
    const nx = -dy * s;
    const ny = dx * s;

    drawQuad(.{
        .{ .pos = .init(a.x + nx, a.y + ny), .uv = Vec2.zero, .col = color },
        .{ .pos = .init(b.x + nx, b.y + ny), .uv = Vec2.zero, .col = color },
        .{ .pos = .init(b.x - nx, b.y - ny), .uv = Vec2.zero, .col = color },
        .{ .pos = .init(a.x - nx, a.y - ny), .uv = Vec2.zero, .col = color },
    });
}

/// Draw a filled square of side `size` centered at `center`.
pub fn drawPoint(center: Vec2, color: Color, size: f32) void {
    drawRectEx(center, .init(size, size), .center, color);
}

/// Draw a filled circle as a triangle fan with `segments` sides.
pub fn drawCircle(center: Vec2, radius: f32, color: Color, segments: u32) void {
    std.debug.assert(segments >= 3 and segments <= max_circle_segments);
    pxl.batcher.setTexture(pxl.batcher.white);

    var verts: [max_circle_segments + 1]Vertex = undefined;
    var indices: [max_circle_segments * 3]u16 = undefined;

    verts[0] = .{ .pos = center, .uv = Vec2.zero, .col = color };
    const step = math.tau / @as(f32, @floatFromInt(segments));
    for (0..segments) |i| {
        const a = step * @as(f32, @floatFromInt(i));
        verts[i + 1] = .{
            .pos = .init(center.x + @cos(a) * radius, center.y + @sin(a) * radius),
            .uv = Vec2.zero,
            .col = color,
        };
        const next: u16 = @intCast((i + 1) % segments + 1);
        indices[i * 3 + 0] = 0;
        indices[i * 3 + 1] = @intCast(i + 1);
        indices[i * 3 + 2] = next;
    }

    pxl.batcher.pushMesh(verts[0 .. segments + 1], indices[0 .. segments * 3]);
}

/// Draw a circle outline of the given thickness as a ring of `segments` quads. Each
/// segment's end angle overlaps the next slightly so there is never a crack between them.
pub fn drawCircleOutline(center: Vec2, radius: f32, thickness: f32, color: Color, segments: u32) void {
    std.debug.assert(segments >= 3 and segments <= max_circle_segments);
    pxl.batcher.setTexture(pxl.batcher.white);

    const inner = radius - thickness * 0.5;
    const outer = radius + thickness * 0.5;

    var verts: [max_circle_segments * 4]Vertex = undefined;
    var indices: [max_circle_segments * 6]u16 = undefined;

    const step = math.tau / @as(f32, @floatFromInt(segments));
    const overlap = step * 0.25; // bridge any sub-pixel seam into the next segment
    for (0..segments) |k| {
        const a0 = step * @as(f32, @floatFromInt(k));
        const a1 = step * @as(f32, @floatFromInt(k + 1)) + overlap;
        const c0 = @cos(a0);
        const s0 = @sin(a0);
        const c1 = @cos(a1);
        const s1 = @sin(a1);

        const base = k * 4;
        verts[base + 0] = .{ .pos = .init(center.x + c0 * inner, center.y + s0 * inner), .uv = Vec2.zero, .col = color };
        verts[base + 1] = .{ .pos = .init(center.x + c0 * outer, center.y + s0 * outer), .uv = Vec2.zero, .col = color };
        verts[base + 2] = .{ .pos = .init(center.x + c1 * outer, center.y + s1 * outer), .uv = Vec2.zero, .col = color };
        verts[base + 3] = .{ .pos = .init(center.x + c1 * inner, center.y + s1 * inner), .uv = Vec2.zero, .col = color };

        const b: u16 = @intCast(base);
        indices[k * 6 + 0] = b;
        indices[k * 6 + 1] = b + 1;
        indices[k * 6 + 2] = b + 2;
        indices[k * 6 + 3] = b;
        indices[k * 6 + 4] = b + 2;
        indices[k * 6 + 5] = b + 3;
    }

    pxl.batcher.pushMesh(verts[0 .. segments * 4], indices[0 .. segments * 6]);
}
