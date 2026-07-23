const std = @import("std");
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

    pub fn init(max_verts: u32, max_indices: u32, max_uniform_bytes: u32) !Batcher {
        const verts = try pxl.mem.allocator.alloc(Vertex, max_verts);
        errdefer pxl.mem.allocator.free(verts);
        const indices = try pxl.mem.allocator.alloc(u16, max_indices);
        errdefer pxl.mem.allocator.free(indices);
        const uniform_data = try pxl.mem.allocator.alloc(u8, max_uniform_bytes);
        errdefer pxl.mem.allocator.free(uniform_data);

        const vbuf = sg.makeBuffer(.{
            .usage = .{ .vertex_buffer = true, .stream_update = true },
            .size = max_verts * @sizeOf(Vertex),
            .label = "batcher-vbuf",
        });
        const ibuf = sg.makeBuffer(.{
            .usage = .{ .index_buffer = true, .stream_update = true },
            .size = max_indices * @sizeOf(u16),
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
        self.blend_mode = .none;
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

    /// Set the uniform data for the current custom pipeline (vertex-stage bytes followed
    /// by fragment-stage bytes). Mirrors sokol_gp's `sgp_set_uniform`. Flushes the batch.
    pub fn setUniform(self: *Batcher, vs_data: ?*const anyopaque, vs_size: u32, fs_data: ?*const anyopaque, fs_size: u32) void {
        std.debug.assert(vs_size + fs_size <= self.uniform_data.len);
        self.flush();

        if (vs_size > 0) {
            const src: [*]const u8 = @ptrCast(vs_data.?);
            @memcpy(self.uniform_data[0..vs_size], src[0..vs_size]);
        }
        if (fs_size > 0) {
            const src: [*]const u8 = @ptrCast(fs_data.?);
            @memcpy(self.uniform_data[vs_size..][0..fs_size], src[0..fs_size]);
        }
        self.uniform_vs_size = vs_size;
        self.uniform_fs_size = fs_size;
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
