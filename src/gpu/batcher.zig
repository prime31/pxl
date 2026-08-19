const std = @import("std");
const math = std.math;
const pxl = @import("../pxl.zig");
const sg = pxl.sokol.gfx;
const shaders = pxl.shaders;

const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const Mat32 = pxl.math.Mat32;
const Rect = pxl.math.Rect;
const Texture = @import("texture.zig").Texture;

/// A single interleaved vertex: position, texture coordinate and packed RGBA color.
pub const Vertex = extern struct {
    pos: Vec2,
    uv: Vec2,
    col: Color,
};

/// Blend modes, mirroring sokol_gp's `sgp_blend_mode`.
pub const BlendMode = enum {
    none,
    blend,
    blend_premultiplied,
    add,
    add_premultiplied,
    mod,
    mul,
};

const UNIFORM_SLOT_VERTEX: u32 = 0;
const UNIFORM_SLOT_FRAGMENT: u32 = 1;

const blend_mode_count = @typeInfo(BlendMode).@"enum".fields.len;
const max_circle_segments = 64;

/// True when a matrix's linear part is a pure axis scale/flip (optionally with the
/// axes swapped for 90-degree rotations): the off-axis entries are ~zero on either
/// the diagonal or the anti-diagonal. Such draws stay rectangular when each vertex
/// is rounded to the pixel grid, so they're safe to pixel-snap. Arbitrary rotations
/// (non-axis-aligned) would have their corners distorted by per-vertex rounding.
fn isAxisAligned(m: Mat32) bool {
    const eps = 1e-5;
    const diagonal = @abs(m.data[1]) <= eps and @abs(m.data[2]) <= eps;
    const swapped = @abs(m.data[0]) <= eps and @abs(m.data[3]) <= eps;
    return diagonal or swapped;
}

pub const sprite = @import("sprite.zig");
pub const Anchor = sprite.Anchor;
pub const Sprite = sprite.Sprite;
pub const Transform = sprite.Transform;

pub const BatcherConfig = struct {
    /// Max vertices queued per CPU batch (flush target).
    max_verts: u32 = 40_000,
    /// Max indices queued per CPU batch (flush target).
    max_indices: u32 = 60_000,
    /// Multiplier for GPU buffer allocation to allow multiple CPU flushes in a single pass.
    gpu_buffer_factor: u32 = 2,
    /// Max draw commands stored per CPU batch.
    max_cmds: u32 = 2_000,
    /// Max byte size reserved for staged pipeline uniforms.
    max_uniform_bytes: u32 = 2_048,
};

/// A recorded deferred draw command slice.
pub const DrawCmd = struct {
    vert_start: u32,
    index_start: u32,
    index_count: u32,
    img: sg.Image,
    smp: sg.Sampler,
    blend_mode: BlendMode,
    pipeline: sg.Pipeline,
    uniform_vs_offset: u32,
    uniform_vs_size: u32,
    uniform_fs_offset: u32,
    uniform_fs_size: u32,
};

pub const Batcher = struct {
    verts: []Vertex,
    indices: []u16,
    vert_count: u32 = 0,
    index_count: u32 = 0,

    cmds: []DrawCmd,
    cmd_count: u32 = 0,
    cmd_dirty: bool = true,

    vbuf: sg.Buffer,
    ibuf: sg.Buffer,
    smp: sg.Sampler,
    white: Texture,

    shader: sg.Shader,
    pipelines: [blend_mode_count]sg.Pipeline = @splat(.{}),
    view_cache: std.AutoHashMap(u32, sg.View),

    // ---- current recording state ----
    cur_img: sg.Image,
    cur_smp: sg.Sampler,
    blend_mode: BlendMode = .blend,
    pipeline: sg.Pipeline = .{},

    uniform_data: []u8,
    uniform_bytes_count: u32 = 0,
    uniform_vs_offset: u32 = 0,
    uniform_vs_size: u32 = 0,
    uniform_fs_offset: u32 = 0,
    uniform_fs_size: u32 = 0,

    view: Mat32 = Mat32.identity(),
    projection: Mat32 = Mat32.identity(),
    /// Round every vertex to a whole render-target pixel (in screen space, before
    /// projection) so low-res scenes stay crisp even when the camera or a sprite
    /// sits at a fractional position. Set per-pass via `Pass.pixel_snap`.
    pixel_snap: bool = false,

    pub fn init(config: BatcherConfig) !Batcher {
        const verts = try pxl.mem.allocator.alloc(Vertex, config.max_verts);
        errdefer pxl.mem.allocator.free(verts);

        const indices = try pxl.mem.allocator.alloc(u16, config.max_indices);
        errdefer pxl.mem.allocator.free(indices);

        const cmds = try pxl.mem.allocator.alloc(DrawCmd, config.max_cmds);
        errdefer pxl.mem.allocator.free(cmds);

        const uniform_data = try pxl.mem.allocator.alloc(u8, config.max_uniform_bytes);
        errdefer pxl.mem.allocator.free(uniform_data);

        // Scale GPU buffer capacity by gpu_buffer_factor so multiple appendBuffer calls work per frame
        const vbuf = sg.makeBuffer(.{
            .usage = .{ .vertex_buffer = true, .stream_update = true },
            .size = config.max_verts * @sizeOf(Vertex) * config.gpu_buffer_factor,
            .label = "batcher-vbuf",
        });
        const ibuf = sg.makeBuffer(.{
            .usage = .{ .index_buffer = true, .stream_update = true },
            .size = config.max_indices * @sizeOf(u16) * config.gpu_buffer_factor,
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

        return .{
            .verts = verts,
            .indices = indices,
            .cmds = cmds,
            .uniform_data = uniform_data,
            .vbuf = vbuf,
            .ibuf = ibuf,
            .smp = smp,
            .cur_smp = smp,
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
        pxl.mem.allocator.free(self.cmds);
        pxl.mem.allocator.free(self.uniform_data);
    }

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

    fn blendPipeline(self: *Batcher, mode: BlendMode) sg.Pipeline {
        const i = @intFromEnum(mode);
        if (self.pipelines[i].id == 0) self.pipelines[i] = makePipeline(self.shader, mode);
        return self.pipelines[i];
    }

    /// Reset staging buffers and recording state.
    pub fn begin(self: *Batcher, view: Mat32, projection: Mat32, pixel_snap: bool) void {
        self.vert_count = 0;
        self.index_count = 0;
        self.cmd_count = 0;
        self.uniform_bytes_count = 0;
        self.view = view;
        self.projection = projection;
        self.pixel_snap = pixel_snap;
        self.cur_img = self.white.img;
        self.cur_smp = self.smp;
        self.blend_mode = .blend;
        self.pipeline = .{};
        self.uniform_vs_size = 0;
        self.uniform_fs_size = 0;
        self.uniform_vs_offset = 0;
        self.uniform_fs_offset = 0;
        self.cmd_dirty = true;
    }

    pub fn setMatrix(self: *Batcher, matrix: Mat32) void {
        // Replace the whole world->clip transform with a custom matrix (the old
        // single-matrix behavior): treat it as the view with an identity projection.
        self.view = matrix;
        self.projection = Mat32.identity();
    }

    pub fn setBlendMode(self: *Batcher, mode: BlendMode) void {
        if (mode == self.blend_mode) return;
        self.blend_mode = mode;
        self.cmd_dirty = true;
    }

    pub fn setPipeline(self: *Batcher, pipeline: sg.Pipeline) void {
        if (pipeline.id == self.pipeline.id) return;
        self.pipeline = pipeline;
        self.uniform_vs_size = 0;
        self.uniform_fs_size = 0;
        self.cmd_dirty = true;
    }

    pub fn resetPipeline(self: *Batcher) void {
        self.setPipeline(.{});
    }

    pub fn setSampler(self: *Batcher, smp: sg.Sampler) void {
        if (smp.id == self.cur_smp.id) return;
        self.cur_smp = smp;
        self.cmd_dirty = true;
    }

    pub fn resetSampler(self: *Batcher) void {
        self.setSampler(self.smp);
    }

    pub fn setUniform(self: *Batcher, vs: anytype, fs: anytype) void {
        const vs_size = getUniformSize(vs);
        const fs_size = getUniformSize(fs);

        if (self.uniform_bytes_count + vs_size + fs_size > self.uniform_data.len) {
            self.flush();
        }

        self.uniform_vs_offset = self.uniform_bytes_count;
        self.uniform_vs_size = self.copyUniform(self.uniform_vs_offset, vs);
        self.uniform_bytes_count += self.uniform_vs_size;

        self.uniform_fs_offset = self.uniform_bytes_count;
        self.uniform_fs_size = self.copyUniform(self.uniform_fs_offset, fs);
        self.uniform_bytes_count += self.uniform_fs_size;

        self.cmd_dirty = true;
    }

    fn getUniformSize(ptr: anytype) u32 {
        if (@TypeOf(ptr) == @TypeOf(null)) return 0;
        return @intCast(std.mem.asBytes(ptr).len);
    }

    fn copyUniform(self: *Batcher, offset: u32, ptr: anytype) u32 {
        if (@TypeOf(ptr) == @TypeOf(null)) return 0;
        const bytes = std.mem.asBytes(ptr);
        std.debug.assert(offset + bytes.len <= self.uniform_data.len);
        @memcpy(self.uniform_data[offset..][0..bytes.len], bytes);
        return @intCast(bytes.len);
    }

    pub fn setTexture(self: *Batcher, tex: Texture) void {
        if (tex.img.id == self.cur_img.id) return;
        self.cur_img = tex.img;
        self.cmd_dirty = true;
    }

    pub const Mesh = struct {
        verts: []const Vertex,
        indices: []const u16,
        texture: ?Texture = null,
        matrix: ?Mat32 = null,
    };

    pub fn pushMesh(self: *Batcher, mesh: Mesh) void {
        const target_tex = mesh.texture orelse self.white;
        self.setTexture(target_tex);

        std.debug.assert(mesh.verts.len <= self.verts.len and mesh.indices.len <= self.indices.len);

        const current_cmd_verts = if (self.cmd_count > 0 and !self.cmd_dirty)
            (self.vert_count - self.cmds[self.cmd_count - 1].vert_start)
        else
            0;

        const would_overflow = self.vert_count + mesh.verts.len > self.verts.len or
            self.index_count + mesh.indices.len > self.indices.len or
            self.cmd_count >= self.cmds.len or
            current_cmd_verts + mesh.verts.len > std.math.maxInt(u16);

        if (would_overflow) self.flush();

        if (self.cmd_dirty or self.cmd_count == 0) {
            self.cmds[self.cmd_count] = .{
                .index_start = self.index_count,
                .index_count = 0,
                .vert_start = self.vert_count,
                .img = self.cur_img,
                .smp = self.cur_smp,
                .blend_mode = self.blend_mode,
                .pipeline = self.pipeline,
                .uniform_vs_offset = self.uniform_vs_offset,
                .uniform_vs_size = self.uniform_vs_size,
                .uniform_fs_offset = self.uniform_fs_offset,
                .uniform_fs_size = self.uniform_fs_size,
            };
            self.cmd_count += 1;
            self.cmd_dirty = false;
        }

        var cmd = &self.cmds[self.cmd_count - 1];
        const base: u16 = @intCast(self.vert_count - cmd.vert_start);

        if (self.pixel_snap) {
            const screen_mat = if (mesh.matrix) |m| self.view.mul(m) else self.view;
            if (isAxisAligned(screen_mat)) {
                // Pixel-perfect path: transform to screen space, snap each vertex to
                // a whole pixel, then project. Axis-aligned draws (rotation a
                // multiple of 90 degrees) stay rectangular under rounding; arbitrary
                // rotations skip snapping rather than have their corners distorted.
                for (mesh.verts, 0..) |v, i| {
                    var p = screen_mat.transformVec2(v.pos);
                    p.x = @round(p.x);
                    p.y = @round(p.y);
                    p = self.projection.transformVec2(p);
                    self.verts[self.vert_count + i] = .{ .pos = p, .uv = v.uv, .col = v.col };
                }
            } else {
                const current_mat = self.projection.mul(screen_mat);
                for (mesh.verts, 0..) |v, i| {
                    self.verts[self.vert_count + i] = .{
                        .pos = current_mat.transformVec2(v.pos),
                        .uv = v.uv,
                        .col = v.col,
                    };
                }
            }
        } else {
            const current_mat = if (mesh.matrix) |m|
                self.projection.mul(self.view.mul(m))
            else
                self.projection.mul(self.view);
            for (mesh.verts, 0..) |v, i| {
                self.verts[self.vert_count + i] = .{
                    .pos = current_mat.transformVec2(v.pos),
                    .uv = v.uv,
                    .col = v.col,
                };
            }
        }
        self.vert_count += @intCast(mesh.verts.len);

        for (mesh.indices, 0..) |idx, i| {
            self.indices[self.index_count + i] = base + idx;
        }
        self.index_count += @intCast(mesh.indices.len);
        cmd.index_count += @intCast(mesh.indices.len);
    }

    /// Single upload of staged geometry followed by issuing stored draw commands.
    pub fn flush(self: *Batcher) void {
        if (self.index_count == 0) return;

        // 1. Single Buffer Upload
        const v_off: u32 = @intCast(sg.appendBuffer(self.vbuf, sg.asRange(self.verts[0..self.vert_count])));
        const i_off: u32 = @intCast(sg.appendBuffer(self.ibuf, sg.asRange(self.indices[0..self.index_count])));

        // 2. Execute recorded commands
        for (self.cmds[0..self.cmd_count]) |cmd| {
            if (cmd.index_count == 0) continue;

            var bind = sg.Bindings{};
            bind.vertex_buffers[0] = self.vbuf;
            bind.vertex_buffer_offsets[0] = @intCast(v_off + cmd.vert_start * @sizeOf(Vertex));
            bind.index_buffer = self.ibuf;
            bind.index_buffer_offset = @intCast(i_off + cmd.index_start * @sizeOf(u16));
            bind.views[shaders.VIEW_tex] = self.viewFor(cmd.img);
            bind.samplers[shaders.SMP_smp] = cmd.smp;

            const custom = cmd.pipeline.id != 0;
            const pip = if (custom) cmd.pipeline else self.blendPipeline(cmd.blend_mode);

            sg.applyPipeline(pip);
            sg.applyBindings(bind);
            if (custom) {
                if (cmd.uniform_vs_size > 0)
                    sg.applyUniforms(UNIFORM_SLOT_VERTEX, sg.asRange(self.uniform_data[cmd.uniform_vs_offset..][0..cmd.uniform_vs_size]));
                if (cmd.uniform_fs_size > 0)
                    sg.applyUniforms(UNIFORM_SLOT_FRAGMENT, sg.asRange(self.uniform_data[cmd.uniform_fs_offset..][0..cmd.uniform_fs_size]));
            }
            sg.draw(0, cmd.index_count, 1);
        }

        // 3. Reset queue counters
        self.vert_count = 0;
        self.index_count = 0;
        self.cmd_count = 0;

        // 4. Preserve active uniform slice across mid-frame flushes
        if (self.pipeline.id != 0 and (self.uniform_vs_size > 0 or self.uniform_fs_size > 0)) {
            const vs_size = self.uniform_vs_size;
            const fs_size = self.uniform_fs_size;

            if (vs_size > 0) {
                @memcpy(self.uniform_data[0..vs_size], self.uniform_data[self.uniform_vs_offset..][0..vs_size]);
                self.uniform_vs_offset = 0;
            }
            if (fs_size > 0) {
                @memcpy(self.uniform_data[vs_size..][0..fs_size], self.uniform_data[self.uniform_fs_offset..][0..fs_size]);
                self.uniform_fs_offset = vs_size;
            }
            self.uniform_bytes_count = vs_size + fs_size;
        } else {
            self.uniform_bytes_count = 0;
            self.uniform_vs_offset = 0;
            self.uniform_fs_offset = 0;
            self.uniform_vs_size = 0;
            self.uniform_fs_size = 0;
        }

        self.cmd_dirty = true;
    }

    pub fn end(self: *Batcher) void {
        self.resetSampler();
        self.resetPipeline();
        self.flush();
    }

    fn viewFor(self: *Batcher, img: sg.Image) sg.View {
        if (self.view_cache.get(img.id)) |v| return v;
        const v = sg.makeView(.{ .texture = .{ .image = img } });
        self.view_cache.put(img.id, v) catch {};
        return v;
    }
};
