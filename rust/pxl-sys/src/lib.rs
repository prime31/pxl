//! Raw FFI bindings for the pxl game framework.
//! See `pxl.h` for documentation of each function.

#![allow(non_camel_case_types, non_snake_case, clippy::too_many_arguments)]

use std::ffi::c_char;

// ── Math types ───────────────────────────────────────────────────────────────

#[repr(C)]
#[derive(Debug, Clone, Copy, Default)]
pub struct PxlVec2 {
    pub x: f32,
    pub y: f32,
}

#[repr(C)]
#[derive(Debug, Clone, Copy, Default)]
pub struct PxlRect {
    pub x: f32,
    pub y: f32,
    pub w: f32,
    pub h: f32,
}

pub type PxlColor = u32;

// ── Opaque handles ───────────────────────────────────────────────────────────

#[repr(C)]
pub struct PxlTexture {
    _private: [u8; 0],
}
#[repr(C)]
pub struct PxlFont {
    _private: [u8; 0],
}
#[repr(C)]
pub struct PxlTilemap {
    _private: [u8; 0],
}
#[repr(C)]
pub struct PxlAnimPlayer {
    _private: [u8; 0],
}

// ── Config types ─────────────────────────────────────────────────────────────

#[repr(C)]
pub struct PxlConfig {
    pub window_title: *const c_char,
    pub width: i32,
    pub height: i32,
    pub sample_count: i32,
    pub swap_interval: i32,
    pub high_dpi: bool,
    pub fullscreen: bool,
    pub debug_render_enabled: bool,
    pub clear_color: PxlColor,
    pub disable_vsync: bool,
    pub enable_clipboard: bool,
    pub enable_dragndrop: bool,
    pub srgb: bool,
    pub hdr: bool,
    pub design_width: i32,
    pub design_height: i32,
    pub resolution_policy: i32,
    pub bloom_enabled: bool,
    pub bloom_downsample: i32,
    pub bloom_threshold: f32,
    pub bloom_intensity: f32,
    pub bloom_blur_radius: f32,
}

#[repr(C)]
pub struct PxlCallbacks {
    pub setup: Option<unsafe extern "C" fn()>,
    pub update: Option<unsafe extern "C" fn()>,
    pub render: Option<unsafe extern "C" fn()>,
    pub shutdown: Option<unsafe extern "C" fn()>,
}

#[repr(C)]
pub struct PxlPass {
    pub clear_color_value: u32,
    pub has_clear_color: bool,
    pub has_camera: bool,
    pub cam_offset_x: f32,
    pub cam_offset_y: f32,
    pub cam_zoom: f32,
    pub cam_rotation: f32,
    pub pixel_snap: bool,
}

#[repr(C)]
#[derive(Clone, Copy)]
pub struct PxlAnimCell {
    pub x: u16,
    pub y: u16,
}

// ── Enums ────────────────────────────────────────────────────────────────────

pub type PxlAnchor = i32;
pub type PxlBlendMode = i32;
pub type PxlSfxPreset = i32;
pub type PxlLoopMode = i32;
pub type PxlKeycode = i32;
pub type PxlMouseButton = i32;
pub type PxlGamepadButton = i32;

// ── FFI declarations ─────────────────────────────────────────────────────────

extern "C" {
    // Entrypoint
    pub fn pxl_run(config: PxlConfig, callbacks: PxlCallbacks);

    // Pass
    pub fn pxl_pass_begin(pass: PxlPass);
    pub fn pxl_pass_end();

    // Drawing
    pub fn pxl_draw_rect(x: f32, y: f32, w: f32, h: f32, color: PxlColor);
    pub fn pxl_draw_line(x1: f32, y1: f32, x2: f32, y2: f32, thickness: f32, color: PxlColor);
    pub fn pxl_draw_circle(cx: f32, cy: f32, radius: f32, segments: u32, color: PxlColor);
    pub fn pxl_draw_circle_outline(
        cx: f32,
        cy: f32,
        radius: f32,
        thickness: f32,
        segments: u32,
        color: PxlColor,
    );
    pub fn pxl_draw_point(cx: f32, cy: f32, size: f32, color: PxlColor);

    #[allow(clippy::too_many_arguments)]
    pub fn pxl_draw_sprite(
        tex: *const PxlTexture,
        src_x: f32,
        src_y: f32,
        src_w: f32,
        src_h: f32,
        pos_x: f32,
        pos_y: f32,
        rotation: f32,
        scale_x: f32,
        scale_y: f32,
        color: PxlColor,
        flip_x: bool,
        flip_y: bool,
        origin: PxlAnchor,
    );

    pub fn pxl_draw_texture(tex: *const PxlTexture, x: f32, y: f32);
    pub fn pxl_draw_textured_rect(
        tex: *const PxlTexture,
        dst_x: f32,
        dst_y: f32,
        dst_w: f32,
        dst_h: f32,
        src_x: f32,
        src_y: f32,
        src_w: f32,
        src_h: f32,
        color: PxlColor,
    );

    pub fn pxl_draw_text(text: *const c_char, x: f32, y: f32, color: PxlColor);
    pub fn pxl_draw_text_len(text: *const u8, text_len: usize, x: f32, y: f32, color: PxlColor);

    pub fn pxl_draw_set_blend_mode(mode: PxlBlendMode);
    pub fn pxl_draw_reset_blend_mode();

    // Time
    pub fn pxl_time_dt() -> f32;
    pub fn pxl_time_fps() -> u32;
    pub fn pxl_time_time() -> f32;
    pub fn pxl_time_frame_count() -> u32;

    // Input
    pub fn pxl_input_key_down(keycode: i32) -> bool;
    pub fn pxl_input_key_pressed(keycode: i32) -> bool;
    pub fn pxl_input_key_up(keycode: i32) -> bool;

    pub fn pxl_input_mouse_down(button: i32) -> bool;
    pub fn pxl_input_mouse_pressed(button: i32) -> bool;
    pub fn pxl_input_mouse_pos(x: *mut f32, y: *mut f32);

    pub fn pxl_input_is_action_pressed(action: *const u8, action_len: usize) -> bool;
    pub fn pxl_input_is_action_just_pressed(action: *const u8, action_len: usize) -> bool;
    pub fn pxl_input_add_binding(action: *const u8, action_len: usize, keycode: i32);
    pub fn pxl_input_get_vector(
        neg_x: *const u8, neg_x_len: usize,
        pos_x: *const u8, pos_x_len: usize,
        neg_y: *const u8, neg_y_len: usize,
        pos_y: *const u8, pos_y_len: usize,
        diagonal: i32,
    ) -> PxlVec2;

    // Window
    pub fn pxl_window_width() -> i32;
    pub fn pxl_window_height() -> i32;
    pub fn pxl_window_widthf() -> f32;
    pub fn pxl_window_heightf() -> f32;
    pub fn pxl_window_dpi_scale() -> f32;
    pub fn pxl_window_is_fullscreen() -> bool;
    pub fn pxl_window_toggle_fullscreen();
    pub fn pxl_window_show_mouse(show: bool);
    pub fn pxl_window_mouse_shown() -> bool;
    pub fn pxl_window_lock_mouse(lock: bool);
    pub fn pxl_window_mouse_locked() -> bool;
    pub fn pxl_window_request_quit();
    pub fn pxl_window_cancel_quit();
    pub fn pxl_window_quit();
    pub fn pxl_window_set_title(title: *const c_char);
    pub fn pxl_window_set_clipboard(str: *const c_char);
    pub fn pxl_window_get_clipboard() -> *const c_char;

    pub fn pxl_window_is_pixel_perfect() -> bool;
    pub fn pxl_window_render_width() -> i32;
    pub fn pxl_window_render_height() -> i32;
    pub fn pxl_window_render_widthf() -> f32;
    pub fn pxl_window_render_heightf() -> f32;

    // Audio
    pub fn pxl_audio_load(path: *const c_char, streamed: bool) -> u64;
    pub fn pxl_audio_unload(sound_handle: u64);

    pub fn pxl_audio_play(sound_handle: u64, volume: f32, pan: f32, pitch: f32, loop_: bool)
        -> u64;
    pub fn pxl_audio_play_one_shot(sound_handle: u64, volume: f32, pan: f32, pitch: f32);
    pub fn pxl_audio_sfx(preset: i32, volume: f32, pan: f32, pitch: f32) -> u64;
    pub fn pxl_audio_stop(playback_handle: u64);
    pub fn pxl_audio_is_playing(playback_handle: u64) -> bool;
    pub fn pxl_audio_playback_position(playback_handle: u64) -> f64;
    pub fn pxl_audio_playback_duration(playback_handle: u64) -> f64;
    pub fn pxl_audio_sound_duration(sound_handle: u64) -> f64;

    // Assets
    pub fn pxl_assets_load_texture(id: u32) -> *mut PxlTexture;
    pub fn pxl_assets_load_font(id: u32) -> *mut PxlFont;
    pub fn pxl_assets_load_tilemap(id: u32) -> *mut PxlTilemap;
    pub fn pxl_assets_load_audio(id: u32, streamed: bool) -> u64;

    pub fn pxl_assets_destroy_texture(tex: *mut PxlTexture);
    pub fn pxl_assets_destroy_font(font: *mut PxlFont);
    pub fn pxl_assets_destroy_tilemap(map: *mut PxlTilemap);
    pub fn pxl_assets_destroy_audio(handle: u64);

    pub fn pxl_assets_load_texture_path(path: *const u8, path_len: usize) -> *mut PxlTexture;
    pub fn pxl_assets_load_font_path(path: *const u8, path_len: usize) -> *mut PxlFont;
    pub fn pxl_assets_load_tilemap_path(path: *const u8, path_len: usize) -> *mut PxlTilemap;

    // Animation
    pub fn pxl_anim_add(
        name: *const c_char,
        tex: *const PxlTexture,
        cell_w: f32,
        cell_h: f32,
        cells: *const PxlAnimCell,
        cell_count: usize,
        fps: f32,
        loop_mode: PxlLoopMode,
    ) -> u32;

    pub fn pxl_anim_player_create() -> *mut PxlAnimPlayer;
    pub fn pxl_anim_player_destroy(player: *mut PxlAnimPlayer);
    pub fn pxl_anim_player_play(player: *mut PxlAnimPlayer, anim_id: u32);
    pub fn pxl_anim_player_update(player: *mut PxlAnimPlayer, dt: f32);
    pub fn pxl_anim_player_pause(player: *mut PxlAnimPlayer);
    pub fn pxl_anim_player_resume(player: *mut PxlAnimPlayer);
    pub fn pxl_anim_player_stop(player: *mut PxlAnimPlayer);
    pub fn pxl_anim_player_finished(player: *mut PxlAnimPlayer) -> bool;
    pub fn pxl_anim_player_set_speed(player: *mut PxlAnimPlayer, speed: f32);

    pub fn pxl_anim_player_current_frame(
        player: *mut PxlAnimPlayer,
        tex: *mut *const PxlTexture,
        src_x: *mut f32,
        src_y: *mut f32,
        src_w: *mut f32,
        src_h: *mut f32,
        color: *mut PxlColor,
        flip_x: *mut bool,
        flip_y: *mut bool,
    ) -> bool;

    pub fn pxl_anim_player_reset(player: *mut PxlAnimPlayer);

    // Aseprite
    pub fn pxl_aseprite_load(aseprite_id: u32) -> *mut PxlTexture;
    pub fn pxl_aseprite_tag_anim(tag_id: u32) -> u32;
    pub fn pxl_aseprite_anim_by_name(aseprite_id: u32, name: *const u8, name_len: usize) -> u32;
    pub fn pxl_aseprite_tag_count(aseprite_id: u32) -> u32;
    pub fn pxl_aseprite_tag_name(tag_id: u32) -> *const c_char;
    pub fn pxl_aseprite_frame_count(aseprite_id: u32) -> u32;
    pub fn pxl_aseprite_load_path(path: *const u8, path_len: usize) -> *mut PxlTexture;
    /// Returns UINT32_MAX if the path is not a known aseprite atlas.
    pub fn pxl_aseprite_find_id(path: *const u8, path_len: usize) -> u32;
}
