//! Window query and control functions — mirrors `pxl.window.*` in Zig.

use std::ffi::CStr;
use pxl_sys;

pub fn width() -> i32 {
    unsafe { pxl_sys::pxl_window_width() }
}
pub fn height() -> i32 {
    unsafe { pxl_sys::pxl_window_height() }
}
pub fn widthf() -> f32 {
    unsafe { pxl_sys::pxl_window_widthf() }
}
pub fn heightf() -> f32 {
    unsafe { pxl_sys::pxl_window_heightf() }
}
pub fn dpi_scale() -> f32 {
    unsafe { pxl_sys::pxl_window_dpi_scale() }
}
pub fn is_fullscreen() -> bool {
    unsafe { pxl_sys::pxl_window_is_fullscreen() }
}
pub fn toggle_fullscreen() {
    unsafe { pxl_sys::pxl_window_toggle_fullscreen() }
}
pub fn show_mouse(show: bool) {
    unsafe { pxl_sys::pxl_window_show_mouse(show) }
}
pub fn mouse_shown() -> bool {
    unsafe { pxl_sys::pxl_window_mouse_shown() }
}
pub fn lock_mouse(lock: bool) {
    unsafe { pxl_sys::pxl_window_lock_mouse(lock) }
}
pub fn mouse_locked() -> bool {
    unsafe { pxl_sys::pxl_window_mouse_locked() }
}
pub fn request_quit() {
    unsafe { pxl_sys::pxl_window_request_quit() }
}
pub fn cancel_quit() {
    unsafe { pxl_sys::pxl_window_cancel_quit() }
}
pub fn quit() {
    unsafe { pxl_sys::pxl_window_quit() }
}
pub fn set_title(title: &str) {
    let c_str = std::ffi::CString::new(title).unwrap();
    unsafe { pxl_sys::pxl_window_set_title(c_str.as_ptr()) }
}
pub fn set_clipboard(text: &str) {
    let c_str = std::ffi::CString::new(text).unwrap();
    unsafe { pxl_sys::pxl_window_set_clipboard(c_str.as_ptr()) }
}
pub fn get_clipboard() -> &'static str {
    unsafe {
        let ptr = pxl_sys::pxl_window_get_clipboard();
        if ptr.is_null() {
            return "";
        }
        CStr::from_ptr(ptr).to_str().unwrap_or("")
    }
}