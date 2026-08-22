//! Drawing functions — mirrors `pxl.api.*` in Zig.

use glam::Vec2;
use pxl_sys;

use crate::math::to_color;
use crate::{Anchor, BlendMode, Color, Frame, LoopMode, Texture};

/// A destination rectangle in world space.
#[derive(Debug, Clone, Copy)]
pub struct Rect {
    pub x: f32,
    pub y: f32,
    pub w: f32,
    pub h: f32,
}

impl Rect {
    pub fn new(x: f32, y: f32, w: f32, h: f32) -> Self {
        Self { x, y, w, h }
    }
}

/// A source rectangle in texture pixels.
pub type SrcRect = Rect;

pub fn rect(pos: Vec2, size: Vec2, color: Color) {
    unsafe { pxl_sys::pxl_draw_rect(pos.x, pos.y, size.x, size.y, to_color(color)) };
}

pub fn line(a: Vec2, b: Vec2, thickness: f32, color: Color) {
    unsafe { pxl_sys::pxl_draw_line(a.x, a.y, b.x, b.y, thickness, to_color(color)) };
}

pub fn circle(center: Vec2, radius: f32, segments: u32, color: Color) {
    unsafe { pxl_sys::pxl_draw_circle(center.x, center.y, radius, segments, to_color(color)) };
}

pub fn circle_outline(center: Vec2, radius: f32, thickness: f32, segments: u32, color: Color) {
    unsafe {
        pxl_sys::pxl_draw_circle_outline(
            center.x, center.y, radius, thickness, segments, to_color(color),
        )
    };
}

pub fn point(center: Vec2, size: f32, color: Color) {
    unsafe { pxl_sys::pxl_draw_point(center.x, center.y, size, to_color(color)) };
}

pub fn texture(tex: &Texture, pos: Vec2) {
    unsafe { pxl_sys::pxl_draw_texture(tex.raw, pos.x, pos.y) };
}

pub fn textured_rect(tex: &Texture, dst: Rect, src: SrcRect, color: Color) {
    unsafe {
        pxl_sys::pxl_draw_textured_rect(
            tex.raw,
            dst.x,
            dst.y,
            dst.w,
            dst.h,
            src.x,
            src.y,
            src.w,
            src.h,
            to_color(color),
        )
    };
}

pub fn sprite(
    tex: &Texture,
    src: Option<SrcRect>,
    pos: Vec2,
    rotation: f32,
    scale: Vec2,
    color: Color,
    flip_x: bool,
    flip_y: bool,
    origin: Anchor,
) {
    let (src_x, src_y, src_w, src_h) = match src {
        Some(r) => (r.x, r.y, r.w, r.h),
        None => (0.0, 0.0, -1.0, -1.0),
    };
    unsafe {
        pxl_sys::pxl_draw_sprite(
            tex.raw,
            src_x,
            src_y,
            src_w,
            src_h,
            pos.x,
            pos.y,
            rotation,
            scale.x,
            scale.y,
            to_color(color),
            flip_x,
            flip_y,
            origin as i32,
        )
    };
}

pub fn sprite_frame(tex: &Texture, frame: Frame, pos: Vec2, rotation: f32, scale: Vec2, color: Color, origin: Anchor) {
    sprite(
        tex,
        Some(Rect::new(frame.src_x, frame.src_y, frame.src_w, frame.src_h)),
        pos,
        rotation,
        scale,
        color,
        frame.flip_x,
        frame.flip_y,
        origin,
    );
}

pub fn text(text: &str, pos: Vec2, color: Color) {
    let c_str = std::ffi::CString::new(text).unwrap();
    unsafe { pxl_sys::pxl_draw_text(c_str.as_ptr(), pos.x, pos.y, to_color(color)) };
}

pub fn set_blend_mode(mode: BlendMode) {
    unsafe { pxl_sys::pxl_draw_set_blend_mode(mode as i32) };
}

pub fn reset_blend_mode() {
    unsafe { pxl_sys::pxl_draw_reset_blend_mode() };
}

// ── Animation construction ───────────────────────────────────────────────────

/// Register a cell-based animation. Returns the animation id.
pub fn anim_add(
    name: &str,
    tex: &Texture,
    cell_w: f32,
    cell_h: f32,
    cells: &[crate::AnimCell],
    fps: f32,
    loop_mode: LoopMode,
) -> u32 {
    let c_name = std::ffi::CString::new(name).unwrap();
    unsafe {
        pxl_sys::pxl_anim_add(
            c_name.as_ptr(),
            tex.raw,
            cell_w,
            cell_h,
            cells.as_ptr(),
            cells.len(),
            fps,
            loop_mode as i32,
        )
    }
}