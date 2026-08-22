//! Timing — mirrors `pxl.time.*` in Zig.

use pxl_sys;

pub fn dt() -> f32 {
    unsafe { pxl_sys::pxl_time_dt() }
}

pub fn fps() -> u32 {
    unsafe { pxl_sys::pxl_time_fps() }
}

pub fn time() -> f32 {
    unsafe { pxl_sys::pxl_time_time() }
}

pub fn frame_count() -> u32 {
    unsafe { pxl_sys::pxl_time_frame_count() }
}