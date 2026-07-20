use crate::{get_context, math::Color};

pub fn screen_width() -> f32 {
    let context = get_context();
    context.screen_width / miniquad::window::dpi_scale()
}

pub fn screen_height() -> f32 {
    let context = get_context();
    context.screen_height / miniquad::window::dpi_scale()
}

pub fn screen_dpi_scale() -> f32 {
    miniquad::window::dpi_scale()
}

/// Request the window size to be the given value. This takes DPI into account.
///
/// Note that the OS might decide to give a different size. Additionally, the size in macroquad won't be updated until the next `next_frame().await`.
pub fn request_new_screen_size(width: f32, height: f32) {
    miniquad::window::set_window_size(
        (width * miniquad::window::dpi_scale()) as u32,
        (height * miniquad::window::dpi_scale()) as u32,
    );
    // We do not set the context.screen_width and context.screen_height here.
    // After `set_window_size` is called, EventHandlerFree::resize will be invoked, setting the size correctly.
    // Because the OS might decide to give a different screen dimension, setting the context.screen_* here would be confusing.
}

/// Toggle whether the window is fullscreen.
pub fn set_fullscreen(fullscreen: bool) {
    miniquad::window::set_fullscreen(fullscreen);
}
