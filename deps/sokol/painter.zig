pub const c = @import("microui_c");

const std = @import("std");
const sg = @import("sokol").gfx;

const __root = @This();
pub const SGP_NO_ERROR: c_int = 0;
pub const SGP_ERROR_SOKOL_INVALID: c_int = 1;
pub const SGP_ERROR_VERTICES_FULL: c_int = 2;
pub const SGP_ERROR_UNIFORMS_FULL: c_int = 3;
pub const SGP_ERROR_COMMANDS_FULL: c_int = 4;
pub const SGP_ERROR_VERTICES_OVERFLOW: c_int = 5;
pub const SGP_ERROR_TRANSFORM_STACK_OVERFLOW: c_int = 6;
pub const SGP_ERROR_TRANSFORM_STACK_UNDERFLOW: c_int = 7;
pub const SGP_ERROR_STATE_STACK_OVERFLOW: c_int = 8;
pub const SGP_ERROR_STATE_STACK_UNDERFLOW: c_int = 9;
pub const SGP_ERROR_ALLOC_FAILED: c_int = 10;
pub const SGP_ERROR_MAKE_VERTEX_BUFFER_FAILED: c_int = 11;
pub const SGP_ERROR_MAKE_WHITE_IMAGE_FAILED: c_int = 12;
pub const SGP_ERROR_MAKE_NEAREST_SAMPLER_FAILED: c_int = 13;
pub const SGP_ERROR_MAKE_COMMON_SHADER_FAILED: c_int = 14;
pub const SGP_ERROR_MAKE_COMMON_PIPELINE_FAILED: c_int = 15;
pub const enum_sgp_error = c_uint;
pub const sgp_error = enum_sgp_error;
pub const SGP_BLENDMODE_NONE: c_int = 0;
pub const SGP_BLENDMODE_BLEND: c_int = 1;
pub const SGP_BLENDMODE_BLEND_PREMULTIPLIED: c_int = 2;
pub const SGP_BLENDMODE_ADD: c_int = 3;
pub const SGP_BLENDMODE_ADD_PREMULTIPLIED: c_int = 4;
pub const SGP_BLENDMODE_MOD: c_int = 5;
pub const SGP_BLENDMODE_MUL: c_int = 6;
pub const _SGP_BLENDMODE_NUM: c_int = 7;
pub const enum_sgp_blend_mode = c_uint;
pub const sgp_blend_mode = enum_sgp_blend_mode;
pub const SGP_VS_ATTR_COORD: c_int = 0;
pub const SGP_VS_ATTR_COLOR: c_int = 1;
pub const enum_sgp_vs_attr_location = c_uint;
pub const sgp_vs_attr_location = enum_sgp_vs_attr_location;
pub const SGP_UNIFORM_SLOT_VERTEX: c_int = 0;
pub const SGP_UNIFORM_SLOT_FRAGMENT: c_int = 1;
pub const enum_sgp_uniform_slot = c_uint;
pub const sgp_uniform_slot = enum_sgp_uniform_slot;

pub const BlendMode = enum(c_uint) {
    none,
    blend,
    blend_premultiplied,
    add,
    add_premultiplied,
    mod,
    mul,
};

pub const struct_sgp_isize = extern struct {
    w: c_int = 0,
    h: c_int = 0,
};
pub const sgp_isize = struct_sgp_isize;
pub const struct_sgp_irect = extern struct {
    x: c_int = 0,
    y: c_int = 0,
    w: c_int = 0,
    h: c_int = 0,
};
pub const sgp_irect = struct_sgp_irect;
pub const struct_sgp_rect = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    w: f32 = 0,
    h: f32 = 0,
    pub const draw_filled_rects = __root.draw_filled_rects;
    pub const rects = __root.draw_filled_rects;
};
pub const sgp_rect = struct_sgp_rect;
pub const struct_sgp_textured_rect = extern struct {
    dst: sgp_rect = @import("std").mem.zeroes(sgp_rect),
    src: sgp_rect = @import("std").mem.zeroes(sgp_rect),
};
pub const sgp_textured_rect = struct_sgp_textured_rect;
pub const struct_sgp_vec2 = extern struct {
    x: f32 = 0,
    y: f32 = 0,
    pub const draw_points = __root.draw_points;
    pub const draw_lines_strip = __root.draw_lines_strip;
    pub const draw_filled_triangles_strip = __root.draw_filled_triangles_strip;
    pub const points = __root.draw_points;
    pub const strip = __root.draw_lines_strip;
};
pub const sgp_vec2 = struct_sgp_vec2;
pub const sgp_point = sgp_vec2;
pub const struct_sgp_line = extern struct {
    a: sgp_point = @import("std").mem.zeroes(sgp_point),
    b: sgp_point = @import("std").mem.zeroes(sgp_point),
    pub const draw_lines = __root.draw_lines;
    pub const lines = __root.draw_lines;
};
pub const sgp_line = struct_sgp_line;
pub const struct_sgp_triangle = extern struct {
    a: sgp_point = @import("std").mem.zeroes(sgp_point),
    b: sgp_point = @import("std").mem.zeroes(sgp_point),
    c: sgp_point = @import("std").mem.zeroes(sgp_point),
    pub const draw_filled_triangles = __root.draw_filled_triangles;
    pub const triangles = __root.draw_filled_triangles;
};
pub const sgp_triangle = struct_sgp_triangle;
pub const struct_sgp_mat2x3 = extern struct {
    v: [2][3]f32 = @import("std").mem.zeroes([2][3]f32),
};
pub const sgp_mat2x3 = struct_sgp_mat2x3;
pub const struct_sgp_color = extern struct {
    r: f32 = 0,
    g: f32 = 0,
    b: f32 = 0,
    a: f32 = 0,
};
pub const sgp_color = struct_sgp_color;
pub const struct_sgp_color_ub4 = extern struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,
};
pub const sgp_color_ub4 = struct_sgp_color_ub4;
pub const struct_sgp_vertex = extern struct {
    position: sgp_vec2 = @import("std").mem.zeroes(sgp_vec2),
    texcoord: sgp_vec2 = @import("std").mem.zeroes(sgp_vec2),
    color: sgp_color_ub4 = @import("std").mem.zeroes(sgp_color_ub4),
};
pub const sgp_vertex = struct_sgp_vertex;
pub const union_sgp_uniform_data = extern union {
    floats: [8]f32,
    bytes: [32]u8,
};
pub const sgp_uniform_data = union_sgp_uniform_data;
pub const struct_sgp_uniform = extern struct {
    vs_size: u16 = 0,
    fs_size: u16 = 0,
    data: sgp_uniform_data = @import("std").mem.zeroes(sgp_uniform_data),
};
pub const sgp_uniform = struct_sgp_uniform;
pub const struct_sgp_textures_uniform = extern struct {
    count: u32 = 0,
    images: [4]sg.sg_image = @import("std").mem.zeroes([4]sg.sg_image),
    samplers: [4]sg.sg_sampler = @import("std").mem.zeroes([4]sg.sg_sampler),
};
pub const sgp_textures_uniform = struct_sgp_textures_uniform;
pub const struct_sgp_state = extern struct {
    frame_size: sgp_isize = @import("std").mem.zeroes(sgp_isize),
    viewport: sgp_irect = @import("std").mem.zeroes(sgp_irect),
    scissor: sgp_irect = @import("std").mem.zeroes(sgp_irect),
    proj: sgp_mat2x3 = @import("std").mem.zeroes(sgp_mat2x3),
    transform: sgp_mat2x3 = @import("std").mem.zeroes(sgp_mat2x3),
    mvp: sgp_mat2x3 = @import("std").mem.zeroes(sgp_mat2x3),
    thickness: f32 = 0,
    color: sgp_color_ub4 = @import("std").mem.zeroes(sgp_color_ub4),
    textures: sgp_textures_uniform = @import("std").mem.zeroes(sgp_textures_uniform),
    uniform: sgp_uniform = @import("std").mem.zeroes(sgp_uniform),
    blend_mode: sgp_blend_mode = @import("std").mem.zeroes(sgp_blend_mode),
    pipeline: sg.sg_pipeline = @import("std").mem.zeroes(sg.sg_pipeline),
    _base_vertex: u32 = 0,
    _base_uniform: u32 = 0,
    _base_command: u32 = 0,
};
pub const sgp_state = struct_sgp_state;
pub const struct_sgp_desc = extern struct {
    max_vertices: u32 = 0,
    max_commands: u32 = 0,
    color_format: sg.PixelFormat = @import("std").mem.zeroes(sg.PixelFormat),
    depth_format: sg.PixelFormat = @import("std").mem.zeroes(sg.PixelFormat),
    sample_count: c_int = 0,
    pub const setup = __root.setup;
};
pub const sgp_desc = struct_sgp_desc;
pub const struct_sgp_pipeline_desc = extern struct {
    shader: sg.sg_shader = @import("std").mem.zeroes(sg.sg_shader),
    primitive_type: sg.sg_primitive_type = @import("std").mem.zeroes(sg.sg_primitive_type),
    blend_mode: sgp_blend_mode = @import("std").mem.zeroes(sgp_blend_mode),
    color_format: sg.sg_pixel_format = @import("std").mem.zeroes(sg.sg_pixel_format),
    depth_format: sg.sg_pixel_format = @import("std").mem.zeroes(sg.sg_pixel_format),
    sample_count: c_int = 0,
    has_vs_color: bool = false,
    pub const make_pipeline = __root.make_pipeline;
    pub const pipeline = __root.make_pipeline;
};
pub const sgp_pipeline_desc = struct_sgp_pipeline_desc;
pub fn setup(desc: *const sgp_desc) void {
    sgp_setup(desc);
}
extern fn sgp_setup(desc: [*c]const sgp_desc) void;

pub fn shutdown() void {
    sgp_shutdown();
}
extern fn sgp_shutdown() void;

pub fn is_valid() bool {
    return sgp_is_valid();
}
extern fn sgp_is_valid() bool;

pub fn get_last_error() sgp_error {
    return sgp_get_last_error();
}
extern fn sgp_get_last_error() sgp_error;

pub fn get_error_message(@"error": sgp_error) []const u8 {
    return std.mem.span(sgp_get_error_message(@"error"));
}
extern fn sgp_get_error_message(@"error": sgp_error) [*c]const u8;

pub fn make_pipeline(desc: [*c]const sgp_pipeline_desc) sg.sg_pipeline {
    return sgp_make_pipeline(desc);
}
extern fn sgp_make_pipeline(desc: [*c]const sgp_pipeline_desc) sg.sg_pipeline;

pub fn begin(width: c_int, height: c_int) void {
    sgp_begin(width, height);
}
extern fn sgp_begin(width: c_int, height: c_int) void;

pub fn flush() void {
    sgp_flush();
}
extern fn sgp_flush() void;

pub fn end() void {
    sgp_end();
}
extern fn sgp_end() void;

pub fn project(left: f32, right: f32, top: f32, bottom: f32) void {
    sgp_project(left, right, top, bottom);
}
extern fn sgp_project(left: f32, right: f32, top: f32, bottom: f32) void;

pub fn reset_project() void {
    sgp_reset_project();
}
extern fn sgp_reset_project() void;

pub fn push_transform() void {
    sgp_push_transform();
}
extern fn sgp_push_transform() void;

pub fn pop_transform() void {
    sgp_pop_transform();
}
extern fn sgp_pop_transform() void;

pub fn reset_transform() void {
    sgp_reset_transform();
}
extern fn sgp_reset_transform() void;

pub fn translate(x: f32, y: f32) void {
    sgp_translate(x, y);
}
extern fn sgp_translate(x: f32, y: f32) void;

pub fn rotate(theta: f32) void {
    sgp_rotate(theta);
}
extern fn sgp_rotate(theta: f32) void;

pub fn rotate_at(theta: f32, x: f32, y: f32) void {
    sgp_rotate_at(theta, x, y);
}
extern fn sgp_rotate_at(theta: f32, x: f32, y: f32) void;

pub fn scale(sx: f32, sy: f32) void {
    sgp_scale(sx, sy);
}
extern fn sgp_scale(sx: f32, sy: f32) void;

pub fn scale_at(sx: f32, sy: f32, x: f32, y: f32) void {
    sgp_scale_at(sx, sy, x, y);
}
extern fn sgp_scale_at(sx: f32, sy: f32, x: f32, y: f32) void;

pub fn set_pipeline(pipeline: sg.sg_pipeline) void {
    sgp_set_pipeline(pipeline);
}
extern fn sgp_set_pipeline(pipeline: sg.sg_pipeline) void;

pub fn reset_pipeline() void {
    sgp_reset_pipeline();
}
extern fn sgp_reset_pipeline() void;

pub fn set_uniform(vs_data: ?*const anyopaque, vs_size: u32, fs_data: ?*const anyopaque, fs_size: u32) void {
    sgp_set_uniform(vs_data, vs_size, fs_data, fs_size);
}
extern fn sgp_set_uniform(vs_data: ?*const anyopaque, vs_size: u32, fs_data: ?*const anyopaque, fs_size: u32) void;

pub fn reset_uniform() void {
    sgp_reset_uniform();
}
extern fn sgp_reset_uniform() void;

pub fn setBlendMode(blend_mode: BlendMode) void {
    sgp_set_blend_mode(@intFromEnum(blend_mode));
}
extern fn sgp_set_blend_mode(blend_mode: sgp_blend_mode) void;

pub fn reset_blend_mode() void {
    sgp_reset_blend_mode();
}
extern fn sgp_reset_blend_mode() void;

pub fn set_color(r: f32, g: f32, b: f32, a: f32) void {
    sgp_set_color(r, g, b, a);
}
extern fn sgp_set_color(r: f32, g: f32, b: f32, a: f32) void;

pub fn reset_color() void {
    sgp_reset_color();
}
extern fn sgp_reset_color() void;

pub fn set_image(channel: c_int, image: sg.Image) void {
    sgp_set_image(channel, image);
}
extern fn sgp_set_image(channel: c_int, image: sg.Image) void;

pub fn unset_image(channel: c_int) void {
    sgp_unset_image(channel);
}
extern fn sgp_unset_image(channel: c_int) void;

pub fn reset_image(channel: c_int) void {
    sgp_reset_image(channel);
}
extern fn sgp_reset_image(channel: c_int) void;

pub fn set_sampler(channel: c_int, sampler: sg.Sampler) void {
    sgp_set_sampler(channel, sampler);
}
extern fn sgp_set_sampler(channel: c_int, sampler: sg.Sampler) void;

pub fn reset_sampler(channel: c_int) void {
    sgp_reset_sampler(channel);
}
extern fn sgp_reset_sampler(channel: c_int) void;

pub fn viewport(x: c_int, y: c_int, w: c_int, h: c_int) void {
    sgp_viewport(x, y, w, h);
}
extern fn sgp_viewport(x: c_int, y: c_int, w: c_int, h: c_int) void;

pub fn reset_viewport() void {
    sgp_reset_viewport();
}
extern fn sgp_reset_viewport() void;

pub fn scissor(x: c_int, y: c_int, w: c_int, h: c_int) void {
    sgp_scissor(x, y, w, h);
}
extern fn sgp_scissor(x: c_int, y: c_int, w: c_int, h: c_int) void;

pub fn reset_scissor() void {
    sgp_reset_scissor();
}
extern fn sgp_reset_scissor() void;

pub fn reset_state() void {
    sgp_reset_state();
}
extern fn sgp_reset_state() void;

pub fn clear() void {
    sgp_clear();
}
extern fn sgp_clear() void;

pub fn draw(primitive_type: sg.PrimitiveType, vertices: [*c]const sgp_vertex, count: u32) void {
    sgp_draw(primitive_type, vertices, count);
}
extern fn sgp_draw(primitive_type: sg.PrimitiveType, vertices: [*c]const sgp_vertex, count: u32) void;

pub fn draw_points(points: [*c]const sgp_point, count: u32) void {
    sgp_draw_points(points, count);
}
extern fn sgp_draw_points(points: [*c]const sgp_point, count: u32) void;

pub fn draw_point(x: f32, y: f32) void {
    sgp_draw_point(x, y);
}
extern fn sgp_draw_point(x: f32, y: f32) void;

pub fn draw_lines(lines: [*c]const sgp_line, count: u32) void {
    sgp_draw_lines(lines, count);
}
extern fn sgp_draw_lines(lines: [*c]const sgp_line, count: u32) void;

pub fn draw_line(ax: f32, ay: f32, bx: f32, by: f32) void {
    sgp_draw_line(ax, ay, bx, by);
}
extern fn sgp_draw_line(ax: f32, ay: f32, bx: f32, by: f32) void;

pub fn draw_lines_strip(points: [*c]const sgp_point, count: u32) void {
    sgp_draw_lines_strip(points, count);
}
extern fn sgp_draw_lines_strip(points: [*c]const sgp_point, count: u32) void;

pub fn draw_filled_triangles(triangles: [*c]const sgp_triangle, count: u32) void {
    sgp_draw_filled_triangles(triangles, count);
}
extern fn sgp_draw_filled_triangles(triangles: [*c]const sgp_triangle, count: u32) void;

pub fn draw_filled_triangle(ax: f32, ay: f32, bx: f32, by: f32, cx: f32, cy: f32) void {
    sgp_draw_filled_triangle(ax, ay, bx, by, cx, cy);
}
extern fn sgp_draw_filled_triangle(ax: f32, ay: f32, bx: f32, by: f32, cx: f32, cy: f32) void;

pub fn draw_filled_triangles_strip(points: [*c]const sgp_point, count: u32) void {
    sgp_draw_filled_triangles_strip(points, count);
}
extern fn sgp_draw_filled_triangles_strip(points: [*c]const sgp_point, count: u32) void;

pub fn draw_filled_rects(rects: [*c]const sgp_rect, count: u32) void {
    sgp_draw_filled_rects(rects, count);
}
extern fn sgp_draw_filled_rects(rects: [*c]const sgp_rect, count: u32) void;

pub fn draw_filled_rect(x: f32, y: f32, w: f32, h: f32) void {
    sgp_draw_filled_rect(x, y, w, h);
}
extern fn sgp_draw_filled_rect(x: f32, y: f32, w: f32, h: f32) void;

pub fn draw_textured_rects(channel: c_int, rects: [*c]const sgp_textured_rect, count: u32) void {
    sgp_draw_textured_rects(channel, rects, count);
}
extern fn sgp_draw_textured_rects(channel: c_int, rects: [*c]const sgp_textured_rect, count: u32) void;

pub fn draw_textured_rect(channel: c_int, dest_rect: sgp_rect, src_rect: sgp_rect) void {
    sgp_draw_textured_rect(channel, dest_rect, src_rect);
}
extern fn sgp_draw_textured_rect(channel: c_int, dest_rect: sgp_rect, src_rect: sgp_rect) void;

pub fn query_state() [*c]sgp_state {
    return sgp_query_state();
}
extern fn sgp_query_state() [*c]sgp_state;

pub fn query_desc() sgp_desc {
    return sgp_query_desc();
}
extern fn sgp_query_desc() sgp_desc;
