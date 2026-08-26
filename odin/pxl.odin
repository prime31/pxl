package pxl

foreign import libc "system:c"

foreign libc {
	pxl_run :: proc(config: Config, callbacks: Callbacks) ---
	pxl_pass_begin :: proc(pass: Pass) ---
	pxl_pass_end :: proc() ---
	pxl_draw_rect :: proc(x, y, w, h: f32, color: Color) ---
	pxl_draw_line :: proc(x1, y1, x2, y2, thickness: f32, color: Color) ---
	pxl_draw_circle :: proc(cx, cy, radius: f32, segments: u32, color: Color) ---
	pxl_draw_text :: proc(text: cstring, x, y: f32, color: Color) ---
	pxl_draw_texture :: proc(texture: ^Texture, x, y: f32) ---
	pxl_draw_textured_rect :: proc(texture: ^Texture, dst_x, dst_y, dst_w, dst_h, src_x, src_y, src_w, src_h: f32, color: Color) ---
	pxl_time_dt :: proc() -> f32 ---
	pxl_time_fps :: proc() -> u32 ---
	pxl_input_key_pressed :: proc(keycode: i32) -> bool ---
	pxl_input_add_binding :: proc(action: rawptr, action_len: uint, keycode: i32) ---
	pxl_input_get_vector :: proc(neg_x: rawptr, neg_x_len: uint, pos_x: rawptr, pos_x_len: uint, neg_y: rawptr, neg_y_len: uint, pos_y: rawptr, pos_y_len: uint, diagonal: i32) -> Vec2 ---
	pxl_input_mouse_pos :: proc(x, y: ^f32) ---
	pxl_window_widthf :: proc() -> f32 ---
	pxl_window_heightf :: proc() -> f32 ---
	pxl_assets_load_texture_path :: proc(path: rawptr, path_len: uint) -> ^Texture ---
	pxl_assets_destroy_texture :: proc(texture: ^Texture) ---
	pxl_aseprite_find_id :: proc(path: rawptr, path_len: uint) -> u32 ---
	pxl_aseprite_load_path :: proc(path: rawptr, path_len: uint) -> ^Texture ---
	pxl_aseprite_tag_anim :: proc(tag_id: u32) -> u32 ---
	pxl_anim_player_create :: proc() -> ^Anim_Player ---
	pxl_anim_player_destroy :: proc(player: ^Anim_Player) ---
	pxl_anim_player_play :: proc(player: ^Anim_Player, animation: u32) ---
	pxl_anim_player_update :: proc(player: ^Anim_Player, dt: f32) ---
	pxl_anim_player_finished :: proc(player: ^Anim_Player) -> bool ---
	pxl_anim_player_current_frame :: proc(player: ^Anim_Player, texture: ^^Texture, src_x, src_y, src_w, src_h: ^f32, color: ^Color, flip_x, flip_y: ^bool) -> bool ---
}

Color :: distinct u32
Vec2 :: struct {x, y: f32}
Rect :: struct {x, y, w, h: f32}
Texture :: struct {}
Anim_Player :: struct {}

Axis_Diagonal :: enum i32 {RAW, NORMALIZED, SQUARE, DIGITAL}
Keycode :: enum i32 {SPACE = 32, W = 87, R = 82, LEFT = 263, RIGHT = 262, DOWN = 264, UP = 265}
Resolution_Policy :: enum i32 {DEFAULT, NO_BORDER, NO_BORDER_PIXEL_PERFECT, SHOW_ALL, SHOW_ALL_PIXEL_PERFECT, BEST_FIT}

Config :: struct {
	window_title: cstring,
	width, height, sample_count, swap_interval: i32,
	high_dpi, fullscreen, debug_render_enabled: bool,
	clear_color: Color,
	disable_vsync, enable_clipboard, enable_dragndrop, srgb, hdr: bool,
	design_width, design_height, resolution_policy: i32,
	bloom_enabled: bool,
	bloom_downsample: i32,
	bloom_threshold, bloom_intensity, bloom_blur_radius: f32,
}

Callbacks :: struct {setup, update, render, shutdown: #type proc()}
Pass :: struct {clear_color_value: u32, has_clear_color, has_camera: bool, cam_offset_x, cam_offset_y, cam_zoom, cam_rotation: f32, pixel_snap: bool}

color_rgba :: proc(r, g, b, a: u8) -> Color {return Color(u32(r) | u32(g)<<8 | u32(b)<<16 | u32(a)<<24)}
color_rgb :: proc(r, g, b: u8) -> Color {return color_rgba(r, g, b, 255)}
begin_pass :: proc(clear: Color) {pxl_pass_begin(Pass{clear_color_value = u32(clear), has_clear_color = true, pixel_snap = true})}
end_pass :: proc() {pxl_pass_end()}
rect :: proc(pos, size: Vec2, color: Color) {pxl_draw_rect(pos.x, pos.y, size.x, size.y, color)}
circle :: proc(center: Vec2, radius: f32, segments: u32, color: Color) {pxl_draw_circle(center.x, center.y, radius, segments, color)}
line :: proc(a, b: Vec2, thickness: f32, color: Color) {pxl_draw_line(a.x, a.y, b.x, b.y, thickness, color)}
text :: proc(value: string, pos: Vec2, color: Color) {pxl_draw_text(cstring(raw_data(value)), pos.x, pos.y, color)}
texture :: proc(value: ^Texture, pos: Vec2) {pxl_draw_texture(value, pos.x, pos.y)}
textured_rect :: proc(value: ^Texture, dst, src: Rect, color: Color) {pxl_draw_textured_rect(value, dst.x, dst.y, dst.w, dst.h, src.x, src.y, src.w, src.h, color)}
dt :: proc() -> f32 {return pxl_time_dt()}
fps :: proc() -> u32 {return pxl_time_fps()}
key_pressed :: proc(key: Keycode) -> bool {return pxl_input_key_pressed(i32(key))}
add_binding :: proc(action: string, key: Keycode) {pxl_input_add_binding(raw_data(action), uint(len(action)), i32(key))}
get_vector :: proc(neg_x, pos_x, neg_y, pos_y: string, diagonal: Axis_Diagonal) -> Vec2 {return pxl_input_get_vector(raw_data(neg_x), uint(len(neg_x)), raw_data(pos_x), uint(len(pos_x)), raw_data(neg_y), uint(len(neg_y)), raw_data(pos_y), uint(len(pos_y)), i32(diagonal))}
scale :: proc(v: Vec2, amount: f32) -> Vec2 {return Vec2{v.x * amount, v.y * amount}}
mouse_pos :: proc() -> Vec2 {x, y: f32; pxl_input_mouse_pos(&x, &y); return Vec2{x, y}}
window_width :: proc() -> f32 {return pxl_window_widthf()}
window_height :: proc() -> f32 {return pxl_window_heightf()}
load_texture :: proc(path: string) -> ^Texture {return pxl_assets_load_texture_path(raw_data(path), uint(len(path)))}
load_aseprite :: proc(path: string) -> ^Texture {return pxl_aseprite_load_path(raw_data(path), uint(len(path)))}
find_aseprite :: proc(path: string) -> u32 {return pxl_aseprite_find_id(raw_data(path), uint(len(path)))}
aseprite_anim :: proc(tag: u32) -> u32 {return pxl_aseprite_tag_anim(tag)}
destroy_texture :: proc(texture: ^Texture) {if texture != nil {pxl_assets_destroy_texture(texture)}}
anim_player_create :: proc() -> ^Anim_Player {return pxl_anim_player_create()}
anim_player_destroy :: proc(player: ^Anim_Player) {pxl_anim_player_destroy(player)}
anim_play :: proc(player: ^Anim_Player, animation: u32) {pxl_anim_player_play(player, animation)}
anim_update :: proc(player: ^Anim_Player, delta: f32) {pxl_anim_player_update(player, delta)}
anim_finished :: proc(player: ^Anim_Player) -> bool {return pxl_anim_player_finished(player)}
anim_current_frame :: proc(player: ^Anim_Player, texture: ^^Texture, src: ^Rect, color: ^Color) -> bool {flip_x, flip_y: bool; return pxl_anim_player_current_frame(player, texture, &src.x, &src.y, &src.w, &src.h, color, &flip_x, &flip_y)}
run :: proc(config: Config, callbacks: Callbacks) {pxl_run(config, callbacks)}
