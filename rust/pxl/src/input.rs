//! Input — mirrors `pxl.input.*` in Zig.

use glam::Vec2;
use pxl_sys;

use crate::Keycode;

pub fn key_down(keycode: Keycode) -> bool {
    unsafe { pxl_sys::pxl_input_key_down(keycode as i32) }
}

pub fn key_pressed(keycode: Keycode) -> bool {
    unsafe { pxl_sys::pxl_input_key_pressed(keycode as i32) }
}

pub fn key_up(keycode: Keycode) -> bool {
    unsafe { pxl_sys::pxl_input_key_up(keycode as i32) }
}

pub fn mouse_down(button: crate::MouseButton) -> bool {
    unsafe { pxl_sys::pxl_input_mouse_down(button as i32) }
}

pub fn mouse_pressed(button: crate::MouseButton) -> bool {
    unsafe { pxl_sys::pxl_input_mouse_pressed(button as i32) }
}

pub fn mouse_pos() -> Vec2 {
    let mut x: f32 = 0.0;
    let mut y: f32 = 0.0;
    unsafe { pxl_sys::pxl_input_mouse_pos(&mut x, &mut y) };
    Vec2::new(x, y)
}

pub fn is_action_pressed(action: &str) -> bool {
    unsafe { pxl_sys::pxl_input_is_action_pressed(action.as_ptr(), action.len()) }
}

pub fn is_action_just_pressed(action: &str) -> bool {
    unsafe { pxl_sys::pxl_input_is_action_just_pressed(action.as_ptr(), action.len()) }
}

pub fn add_binding(action: &str, keycode: Keycode) {
    unsafe { pxl_sys::pxl_input_add_binding(action.as_ptr(), action.len(), keycode as i32) };
}

/// Analog 2D input vector from four action bindings (like Godot's `get_vector`).
/// Zero-allocation: passes raw ptr+len to the C API.
pub fn get_vector(
    neg_x: &str,
    pos_x: &str,
    neg_y: &str,
    pos_y: &str,
    diagonal: crate::AxisDiagonal,
) -> Vec2 {
    let v = unsafe {
        pxl_sys::pxl_input_get_vector(
            neg_x.as_ptr(), neg_x.len(),
            pos_x.as_ptr(), pos_x.len(),
            neg_y.as_ptr(), neg_y.len(),
            pos_y.as_ptr(), pos_y.len(),
            diagonal as i32,
        )
    };
    Vec2::new(v.x, v.y)
}
