const std = @import("std");
const math = std.math;
const pxl = @import("../pxl.zig");
const sg = pxl.sokol.gfx;
const shaders = pxl.shaders;

const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const Mat32 = pxl.math.Mat32;
const Texture = @import("texture.zig").Texture;

/// A single interleaved vertex: position, texture coordinate and packed RGBA color.
/// Matches the `batcher` shader's vertex layout (see shaders/batcher.glsl).
pub const Vertex = extern struct {
    pos: Vec2,
    uv: Vec2,
    col: Color,
};

/// Blend modes, mirroring sokol_gp's `sgp_blend_mode` (sokol_gp.h:447).
pub const BlendMode = enum {
    none,
    blend,
    blend_premultiplied,
    add,
    add_premultiplied,
    mod,
    mul,
};

/// Uniform bind slots, matching `SGP_UNIFORM_SLOT_*` and the sokol shader convention.
const UNIFORM_SLOT_VERTEX: u32 = 0;
const UNIFORM_SLOT_FRAGMENT: u32 = 1;

const blend_mode_count = @typeInfo(BlendMode).@"enum".fields.len;

/// Upper bound on `segments` for `drawCircle`/`drawCircleOutline` (bounds their stack buffers).
const max_circle_segments = 64;

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

/// Parameters for `drawSprite`. Sensible defaults: whole texture, white, centered, no rotation.
pub const Sprite = struct {
    texture: Texture,
    /// World position where `anchor` is placed.
    position: Vec2 = Vec2.zero,
    color: Color = Color.white,
    /// Rotation in radians, about `anchor`.
    rotation: f32 = 0,
    scale: Vec2 = Vec2.one,
    /// The point of the sprite pinned to `position` (and rotated/scaled about).
    anchor: Anchor = .center,
    /// Sub-region of the texture in pixels (atlas cell); `null` = the whole texture.
    source: ?Rect = null,
    flip_x: bool = false,
    flip_y: bool = false,
};

pub const BatcherConfig = struct {
    max_verts: u32 = 300_000,
    max_indices: u32 = 600_000,
    max_uniform_bytes: u32 = 64,
};

/// A minimal, fast 2D triangle batcher built directly on sokol-gfx.
///
/// The only primitive is the triangle: every draw is expressed as indexed
/// triangles. Vertices are transformed on the CPU by the current `matrix` as they
/// are pushed, so the shader is a pass-through and draws with different transforms
/// still merge into a single batch. Only a texture change (or a full staging buffer)
/// breaks a batch and forces a `flush`.
///
/// A `flush` issues sokol-gfx draw commands, so it must be called while an
/// `sg.beginPass`/`sg.endPass` is active.
pub const Batcher = struct {
    verts: []Vertex,
    indices: []u16,
    vert_count: u32 = 0,
    index_count: u32 = 0,

    vbuf: sg.Buffer,
    ibuf: sg.Buffer,
    smp: sg.Sampler,
    white: Texture,

    /// The batcher shader, kept so per-blend-mode pipelines can be built lazily.
    shader: sg.Shader,
    /// Lazily-created pipeline per blend mode, indexed by `@intFromEnum(BlendMode)`
    /// (mirrors sokol_gp's `_sgp.pipelines[]`).
    pipelines: [blend_mode_count]sg.Pipeline = @splat(.{}),

    /// img.id -> texture view, mirroring sokol_gp's per-image view lookup.
    view_cache: std.AutoHashMap(u32, sg.View),

    // ---- current draw state (a change to any of these breaks the batch) ----

    /// The current batch texture.
    cur_img: sg.Image,
    /// The current blend mode (ignored while a custom `pipeline` is set).
    blend_mode: BlendMode = .none,
    /// The current custom pipeline; `id == 0` means "use the blend-mode pipeline".
    /// User-owned — not destroyed by the batcher.
    pipeline: sg.Pipeline = .{},
    /// Custom-pipeline uniform staging: `vs` bytes then `fs` bytes.
    uniform_data: []u8,
    uniform_vs_size: u32 = 0,
    uniform_fs_size: u32 = 0,

    /// The current 2D affine transform, applied to vertices on the CPU.
    matrix: Mat32 = Mat32.identity(),

    pub fn init(config: BatcherConfig) !Batcher {
        const verts = try pxl.mem.allocator.alloc(Vertex, config.max_verts);
        errdefer pxl.mem.allocator.free(verts);
        const indices = try pxl.mem.allocator.alloc(u16, config.max_indices);
        errdefer pxl.mem.allocator.free(indices);
        const uniform_data = try pxl.mem.allocator.alloc(u8, config.max_uniform_bytes);
        errdefer pxl.mem.allocator.free(uniform_data);

        const vbuf = sg.makeBuffer(.{
            .usage = .{ .vertex_buffer = true, .stream_update = true },
            .size = config.max_verts * @sizeOf(Vertex),
            .label = "batcher-vbuf",
        });
        const ibuf = sg.makeBuffer(.{
            .usage = .{ .index_buffer = true, .stream_update = true },
            .size = config.max_indices * @sizeOf(u16),
            .label = "batcher-ibuf",
        });

        const smp = sg.makeSampler(.{
            .min_filter = .NEAREST,
            .mag_filter = .NEAREST,
            .wrap_u = .CLAMP_TO_EDGE,
            .wrap_v = .CLAMP_TO_EDGE,
        });

        var white_pixels = [_]u32{0xFFFFFFFF};
        const white = Texture.initWithColorData(white_pixels[0..], 1, 1);

        // per-blend-mode pipelines are created lazily on first use (see `blendPipeline`)
        return .{
            .verts = verts,
            .indices = indices,
            .uniform_data = uniform_data,
            .vbuf = vbuf,
            .ibuf = ibuf,
            .smp = smp,
            .white = white,
            .shader = sg.makeShader(shaders.batcherShaderDesc(sg.queryBackend())),
            .view_cache = std.AutoHashMap(u32, sg.View).init(pxl.mem.allocator),
            .cur_img = white.img,
        };
    }

    pub fn deinit(self: *Batcher) void {
        var it = self.view_cache.valueIterator();
        while (it.next()) |v| sg.destroyView(v.*);
        self.view_cache.deinit();

        for (self.pipelines) |pip| {
            if (pip.id != 0) sg.destroyPipeline(pip);
        }
        sg.destroyShader(self.shader);
        sg.destroyBuffer(self.vbuf);
        sg.destroyBuffer(self.ibuf);
        sg.destroySampler(self.smp);
        self.white.deinit();

        pxl.mem.allocator.free(self.verts);
        pxl.mem.allocator.free(self.indices);
        pxl.mem.allocator.free(self.uniform_data);
    }

    /// The blend state for a given mode, mirroring sokol_gp's `_sgp_blend_state` (sokol_gp.h:1523).
    fn blendState(mode: BlendMode) sg.BlendState {
        return switch (mode) {
            .none => .{
                .enabled = false,
                .src_factor_rgb = .ONE,
                .dst_factor_rgb = .ZERO,
                .op_rgb = .ADD,
                .src_factor_alpha = .ONE,
                .dst_factor_alpha = .ZERO,
                .op_alpha = .ADD,
            },
            .blend => .{
                .enabled = true,
                .src_factor_rgb = .SRC_ALPHA,
                .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
                .op_rgb = .ADD,
                .src_factor_alpha = .ONE,
                .dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
                .op_alpha = .ADD,
            },
            .blend_premultiplied => .{
                .enabled = true,
                .src_factor_rgb = .ONE,
                .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
                .op_rgb = .ADD,
                .src_factor_alpha = .ONE,
                .dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
                .op_alpha = .ADD,
            },
            .add => .{
                .enabled = true,
                .src_factor_rgb = .SRC_ALPHA,
                .dst_factor_rgb = .ONE,
                .op_rgb = .ADD,
                .src_factor_alpha = .ZERO,
                .dst_factor_alpha = .ONE,
                .op_alpha = .ADD,
            },
            .add_premultiplied => .{
                .enabled = true,
                .src_factor_rgb = .ONE,
                .dst_factor_rgb = .ONE,
                .op_rgb = .ADD,
                .src_factor_alpha = .ZERO,
                .dst_factor_alpha = .ONE,
                .op_alpha = .ADD,
            },
            .mod => .{
                .enabled = true,
                .src_factor_rgb = .DST_COLOR,
                .dst_factor_rgb = .ZERO,
                .op_rgb = .ADD,
                .src_factor_alpha = .ZERO,
                .dst_factor_alpha = .ONE,
                .op_alpha = .ADD,
            },
            .mul => .{
                .enabled = true,
                .src_factor_rgb = .DST_COLOR,
                .dst_factor_rgb = .ONE_MINUS_SRC_ALPHA,
                .op_rgb = .ADD,
                .src_factor_alpha = .DST_ALPHA,
                .dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
                .op_alpha = .ADD,
            },
        };
    }

    /// Build a pipeline with the batcher's vertex layout for the given shader and blend
    /// mode. Public companion to `setPipeline` (mirrors sokol_gp's `sgp_make_pipeline`),
    /// so callers can create a layout-compatible pipeline for a custom shader.
    pub fn makePipeline(shader: sg.Shader, mode: BlendMode) sg.Pipeline {
        var layout = sg.VertexLayoutState{};
        layout.buffers[0].stride = @sizeOf(Vertex);
        layout.attrs[shaders.ATTR_batcher_pos] = .{ .format = .FLOAT2, .offset = @offsetOf(Vertex, "pos") };
        layout.attrs[shaders.ATTR_batcher_texcoord0] = .{ .format = .FLOAT2, .offset = @offsetOf(Vertex, "uv") };
        layout.attrs[shaders.ATTR_batcher_color0] = .{ .format = .UBYTE4N, .offset = @offsetOf(Vertex, "col") };

        var pip_desc = sg.PipelineDesc{
            .shader = shader,
            .layout = layout,
            .index_type = .UINT16,
            .color_count = 1,
            .depth = .{ .pixel_format = .NONE },
            .label = "batcher-pipeline",
        };
        pip_desc.colors[0].blend = blendState(mode);
        return sg.makePipeline(pip_desc);
    }

    /// Return the lazily-created pipeline for a blend mode (mirrors `_sgp_lookup_pipeline`).
    fn blendPipeline(self: *Batcher, mode: BlendMode) sg.Pipeline {
        const i = @intFromEnum(mode);
        if (self.pipelines[i].id == 0) self.pipelines[i] = makePipeline(self.shader, mode);
        return self.pipelines[i];
    }

    /// Begin a new batch: reset the staging buffers and all draw state.
    pub fn begin(self: *Batcher, matrix: Mat32) void {
        self.vert_count = 0;
        self.index_count = 0;
        self.matrix = matrix;
        self.cur_img = self.white.img;
        self.blend_mode = .blend;
        self.pipeline = .{};
        self.uniform_vs_size = 0;
        self.uniform_fs_size = 0;
    }

    /// Set the transform applied to subsequently pushed vertices. Does not break the
    /// batch, since the transform is baked into the vertices on the CPU.
    pub fn setMatrix(self: *Batcher, matrix: Mat32) void {
        self.matrix = matrix;
    }

    /// Set the blend mode for subsequent draws. Flushes the current batch if it changes.
    pub fn setBlendMode(self: *Batcher, mode: BlendMode) void {
        if (mode == self.blend_mode) return;
        self.flush();
        self.blend_mode = mode;
    }

    /// Set a custom pipeline that overrides the blend-mode pipeline. `id == 0` clears it.
    /// Flushes the current batch and resets uniforms, like sokol_gp's `sgp_set_pipeline`.
    pub fn setPipeline(self: *Batcher, pipeline: sg.Pipeline) void {
        if (pipeline.id == self.pipeline.id) return;
        self.flush();
        self.pipeline = pipeline;
        self.uniform_vs_size = 0;
        self.uniform_fs_size = 0;
    }

    /// Clear the custom pipeline, returning to the built-in blend-mode pipelines.
    pub fn resetPipeline(self: *Batcher) void {
        self.setPipeline(.{});
    }

    /// Set the uniform data for the current custom pipeline. Pass a pointer to the
    /// vertex-stage uniform struct (or `null`) and likewise for the fragment stage; each
    /// size is derived from the pointee type. Mirrors sokol_gp's `sgp_set_uniform`. Flushes.
    pub fn setUniform(self: *Batcher, vs: anytype, fs: anytype) void {
        self.flush();
        self.uniform_vs_size = self.copyUniform(0, vs);
        self.uniform_fs_size = self.copyUniform(self.uniform_vs_size, fs);
    }

    /// Copy a uniform struct pointed to by `ptr` into `uniform_data` at `offset`, returning
    /// its byte size. `null` writes nothing and returns 0.
    fn copyUniform(self: *Batcher, offset: u32, ptr: anytype) u32 {
        if (@TypeOf(ptr) == @TypeOf(null)) return 0;
        const bytes = std.mem.asBytes(ptr);
        std.debug.assert(offset + bytes.len <= self.uniform_data.len);
        @memcpy(self.uniform_data[offset..][0..bytes.len], bytes);
        return @intCast(bytes.len);
    }

    /// Bind a texture for subsequent draws. Flushes the current batch if the texture changes.
    pub fn setTexture(self: *Batcher, tex: Texture) void {
        if (tex.img.id == self.cur_img.id) return;
        self.flush();
        self.cur_img = tex.img;
    }

    /// Append a mesh of triangles. Each vertex position is transformed by the current
    /// matrix. Indices are relative to `verts` (0-based). Flushes first if it won't fit.
    pub fn pushMesh(self: *Batcher, verts: []const Vertex, indices: []const u16) void {
        std.debug.assert(verts.len <= self.verts.len and indices.len <= self.indices.len);

        const would_overflow = self.vert_count + verts.len > self.verts.len or
            self.index_count + indices.len > self.indices.len or
            self.vert_count + verts.len > std.math.maxInt(u16);
        if (would_overflow) self.flush();

        const base: u16 = @intCast(self.vert_count);
        for (verts, 0..) |v, i| {
            self.verts[self.vert_count + i] = .{
                .pos = self.matrix.transformVec2(v.pos),
                .uv = v.uv,
                .col = v.col,
            };
        }
        self.vert_count += @intCast(verts.len);

        for (indices, 0..) |idx, i| {
            self.indices[self.index_count + i] = base + idx;
        }
        self.index_count += @intCast(indices.len);
    }

    /// Draw a filled triangle using the 1x1 white texture (color only).
    pub fn drawTriangle(self: *Batcher, a: Vec2, b: Vec2, c: Vec2, col: Color) void {
        self.setTexture(self.white);
        const verts = [_]Vertex{
            .{ .pos = a, .uv = Vec2.zero, .col = col },
            .{ .pos = b, .uv = Vec2.zero, .col = col },
            .{ .pos = c, .uv = Vec2.zero, .col = col },
        };
        self.pushMesh(&verts, &.{ 0, 1, 2 });
    }

    /// Draw a quad from four corner vertices (two triangles).
    pub fn drawQuad(self: *Batcher, verts: [4]Vertex) void {
        self.pushMesh(&verts, &.{ 0, 1, 2, 0, 2, 3 });
    }

    // ---- high-level 2D drawing ----

    /// Bind `tex`, then push a quad whose local `corners` are transformed by `model`
    /// composed with the current matrix. The matrix is restored afterwards (no flush).
    fn drawTexturedQuad(self: *Batcher, tex: Texture, model: Mat32, corners: [4]Vec2, uvs: [4]Vec2, col: Color) void {
        self.setTexture(tex);
        const saved = self.matrix;
        self.matrix = saved.mul(model);
        self.drawQuad(.{
            .{ .pos = corners[0], .uv = uvs[0], .col = col },
            .{ .pos = corners[1], .uv = uvs[1], .col = col },
            .{ .pos = corners[2], .uv = uvs[2], .col = col },
            .{ .pos = corners[3], .uv = uvs[3], .col = col },
        });
        self.matrix = saved;
    }

    /// Draw a textured sprite with position, rotation, scale, pivot and an optional
    /// atlas source region (models comfy's `draw_sprite_pro`).
    pub fn drawSprite(self: *Batcher, s: Sprite) void {
        const src = s.source orelse Rect{
            .x = 0,
            .y = 0,
            .w = @floatFromInt(s.texture.width),
            .h = @floatFromInt(s.texture.height),
        };
        const tw: f32 = @floatFromInt(s.texture.width);
        const th: f32 = @floatFromInt(s.texture.height);

        const w = src.w * s.scale.x;
        const h = src.h * s.scale.y;

        // anchor is center-relative [-0.5, 0.5]; convert to a pivot in local [0,w]x[0,h]
        const a = s.anchor.asVec();
        const px = (0.5 + a.x) * w;
        const py = (0.5 + a.y) * h;

        const model = Mat32.fromTranslation(s.position.x, s.position.y)
            .mul(Mat32.fromRotation(s.rotation))
            .mul(Mat32.fromTranslation(-px, -py));

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

        self.drawTexturedQuad(s.texture, model, corners, uvs, s.color);
    }

    /// Draw a texture at its native size with its top-left corner at `position`.
    pub fn drawTexture(self: *Batcher, tex: Texture, position: Vec2) void {
        self.drawSprite(.{ .texture = tex, .position = position, .anchor = .top_left });
    }

    /// Draw the `src` pixel region of `tex` into the `dst` world rect (top-left), tinted by
    /// `color`. Negative `src.w`/`src.h` flip that axis (matches sokol_gp's textured rects).
    pub fn drawTexturedRect(self: *Batcher, tex: Texture, dst: Rect, src: Rect, color: Color) void {
        const tw: f32 = @floatFromInt(tex.width);
        const th: f32 = @floatFromInt(tex.height);
        const _u0 = src.x / tw;
        const v0 = src.y / th;
        const _u1 = (src.x + src.w) / tw;
        const v1 = (src.y + src.h) / th;
        self.setTexture(tex);
        self.drawQuad(.{
            .{ .pos = .init(dst.x, dst.y), .uv = .init(_u0, v0), .col = color },
            .{ .pos = .init(dst.x + dst.w, dst.y), .uv = .init(_u1, v0), .col = color },
            .{ .pos = .init(dst.x + dst.w, dst.y + dst.h), .uv = .init(_u1, v1), .col = color },
            .{ .pos = .init(dst.x, dst.y + dst.h), .uv = .init(_u0, v1), .col = color },
        });
    }

    /// Draw a filled rectangle centered at `center`.
    pub fn drawRect(self: *Batcher, center: Vec2, size: Vec2, color: Color) void {
        self.setTexture(self.white);
        const hw = size.x * 0.5;
        const hh = size.y * 0.5;
        self.drawQuad(.{
            .{ .pos = .init(center.x - hw, center.y - hh), .uv = Vec2.zero, .col = color },
            .{ .pos = .init(center.x + hw, center.y - hh), .uv = Vec2.zero, .col = color },
            .{ .pos = .init(center.x + hw, center.y + hh), .uv = Vec2.zero, .col = color },
            .{ .pos = .init(center.x - hw, center.y + hh), .uv = Vec2.zero, .col = color },
        });
    }

    /// Draw the outline of a rectangle centered at `center` as a border ring, so the
    /// corners are mitered with no gaps or overlap (comfy's inner/outer-rect outline).
    pub fn drawRectOutline(self: *Batcher, center: Vec2, size: Vec2, thickness: f32, color: Color) void {
        self.setTexture(self.white);
        const ht = thickness * 0.5;
        const ox = size.x * 0.5 + ht; // outer half-extents
        const oy = size.y * 0.5 + ht;
        const ix = size.x * 0.5 - ht; // inner half-extents
        const iy = size.y * 0.5 - ht;

        const verts = [8]Vertex{
            // outer TL, TR, BR, BL
            .{ .pos = .init(center.x - ox, center.y - oy), .uv = Vec2.zero, .col = color },
            .{ .pos = .init(center.x + ox, center.y - oy), .uv = Vec2.zero, .col = color },
            .{ .pos = .init(center.x + ox, center.y + oy), .uv = Vec2.zero, .col = color },
            .{ .pos = .init(center.x - ox, center.y + oy), .uv = Vec2.zero, .col = color },
            // inner TL, TR, BR, BL
            .{ .pos = .init(center.x - ix, center.y - iy), .uv = Vec2.zero, .col = color },
            .{ .pos = .init(center.x + ix, center.y - iy), .uv = Vec2.zero, .col = color },
            .{ .pos = .init(center.x + ix, center.y + iy), .uv = Vec2.zero, .col = color },
            .{ .pos = .init(center.x - ix, center.y + iy), .uv = Vec2.zero, .col = color },
        };
        // four border quads (top, right, bottom, left)
        self.pushMesh(&verts, &.{
            0, 1, 5, 0, 5, 4,
            1, 2, 6, 1, 6, 5,
            2, 3, 7, 2, 7, 6,
            3, 0, 4, 3, 4, 7,
        });
    }

    /// Draw a line from `a` to `b` as a thickness-wide quad.
    pub fn drawLine(self: *Batcher, a: Vec2, b: Vec2, thickness: f32, color: Color) void {
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const len = @sqrt(dx * dx + dy * dy);
        if (len < 1e-6) return;

        const s = thickness * 0.5 / len;
        const nx = -dy * s;
        const ny = dx * s;

        self.setTexture(self.white);
        self.drawQuad(.{
            .{ .pos = .init(a.x + nx, a.y + ny), .uv = Vec2.zero, .col = color },
            .{ .pos = .init(b.x + nx, b.y + ny), .uv = Vec2.zero, .col = color },
            .{ .pos = .init(b.x - nx, b.y - ny), .uv = Vec2.zero, .col = color },
            .{ .pos = .init(a.x - nx, a.y - ny), .uv = Vec2.zero, .col = color },
        });
    }

    /// Draw a filled square of side `size` centered at `center`.
    pub fn drawPoint(self: *Batcher, center: Vec2, color: Color, size: f32) void {
        self.drawRect(center, .init(size, size), color);
    }

    /// Draw a filled circle as a triangle fan with `segments` sides.
    pub fn drawCircle(self: *Batcher, center: Vec2, radius: f32, color: Color, segments: u32) void {
        std.debug.assert(segments >= 3 and segments <= max_circle_segments);
        self.setTexture(self.white);

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

        self.pushMesh(verts[0 .. segments + 1], indices[0 .. segments * 3]);
    }

    /// Draw a circle outline of the given thickness as a ring of `segments` quads. Each
    /// segment's end angle overlaps the next slightly so there is never a crack between them.
    pub fn drawCircleOutline(self: *Batcher, center: Vec2, radius: f32, thickness: f32, color: Color, segments: u32) void {
        std.debug.assert(segments >= 3 and segments <= max_circle_segments);
        self.setTexture(self.white);

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

        self.pushMesh(verts[0 .. segments * 4], indices[0 .. segments * 6]);
    }

    /// Upload the staged geometry and issue a draw call for the current texture.
    /// Must be called inside an active sokol-gfx render pass.
    pub fn flush(self: *Batcher) void {
        if (self.index_count == 0) return;

        const v_off = sg.appendBuffer(self.vbuf, sg.asRange(self.verts[0..self.vert_count]));
        const i_off = sg.appendBuffer(self.ibuf, sg.asRange(self.indices[0..self.index_count]));

        var bind = sg.Bindings{};
        bind.vertex_buffers[0] = self.vbuf;
        bind.vertex_buffer_offsets[0] = v_off;
        bind.index_buffer = self.ibuf;
        bind.index_buffer_offset = i_off;
        bind.views[shaders.VIEW_tex] = self.viewFor(self.cur_img);
        bind.samplers[shaders.SMP_smp] = self.smp;

        // a custom pipeline overrides the blend-mode pipeline and carries uniforms
        const custom = self.pipeline.id != 0;
        const pip = if (custom) self.pipeline else self.blendPipeline(self.blend_mode);

        sg.applyPipeline(pip);
        sg.applyBindings(bind);
        if (custom) {
            if (self.uniform_vs_size > 0)
                sg.applyUniforms(UNIFORM_SLOT_VERTEX, sg.asRange(self.uniform_data[0..self.uniform_vs_size]));
            if (self.uniform_fs_size > 0)
                sg.applyUniforms(UNIFORM_SLOT_FRAGMENT, sg.asRange(self.uniform_data[self.uniform_vs_size..][0..self.uniform_fs_size]));
        }
        sg.draw(0, self.index_count, 1);

        self.vert_count = 0;
        self.index_count = 0;
    }

    /// Flush any remaining geometry. Alias for `flush`, marking the end of a batch.
    pub fn end(self: *Batcher) void {
        self.flush();
    }

    fn viewFor(self: *Batcher, img: sg.Image) sg.View {
        if (self.view_cache.get(img.id)) |v| return v;
        const v = sg.makeView(.{ .texture = .{ .image = img } });
        self.view_cache.put(img.id, v) catch {};
        return v;
    }
};
