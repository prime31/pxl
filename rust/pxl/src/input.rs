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
    let c = std::ffi::CString::new(action).unwrap();
    unsafe { pxl_sys::pxl_input_is_action_pressed(c.as_ptr()) }
}

pub fn is_action_just_pressed(action: &str) -> bool {
    let c = std::ffi::CString::new(action).unwrap();
    unsafe { pxl_sys::pxl_input_is_action_just_pressed(c.as_ptr()) }
}

pub fn add_binding(action: &str, keycode: Keycode) {
    let c = std::ffi::CString::new(action).unwrap();
    unsafe { pxl_sys::pxl_input_add_binding(c.as_ptr(), keycode as i32) };
}

/// Analog 2D input vector from four action bindings (like Godot's `get_vector`).
pub fn get_vector(
    neg_x: &str,
    pos_x: &str,
    neg_y: &str,
    pos_y: &str,
    diagonal: crate::AxisDiagonal,
) -> Vec2 {
    let neg_x_c = std::ffi::CString::new(neg_x).unwrap();
    let pos_x_c = std::ffi::CString::new(pos_x).unwrap();
    let neg_y_c = std::ffi::CString::new(neg_y).unwrap();
    let pos_y_c = std::ffi::CString::new(pos_y).unwrap();
    let v = unsafe {
        pxl_sys::pxl_input_get_vector(
            neg_x_c.as_ptr(),
            pos_x_c.as_ptr(),
            neg_y_c.as_ptr(),
            pos_y_c.as_ptr(),
            diagonal as i32,
        )
    };
    Vec2::new(v.x, v.y)
}