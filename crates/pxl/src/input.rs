use std::collections::HashSet;

pub use miniquad::{KeyCode, MouseButton};

use crate::Vec2;
use crate::get_context;
use crate::window::screen_height;
use crate::window::screen_width;

/// Constrain mouse to window
pub fn set_cursor_grab(grab: bool) {
    let context = get_context();
    context.cursor_grabbed = grab;
    miniquad::window::set_cursor_grab(grab);
}

/// Set mouse cursor visibility
pub fn show_mouse(shown: bool) {
    miniquad::window::show_mouse(shown);
}

/// Return mouse position in pixels.
pub fn mouse_position() -> (f32, f32) {
    let context = get_context();
    (
        context.mouse_position.x / miniquad::window::dpi_scale(),
        context.mouse_position.y / miniquad::window::dpi_scale(),
    )
}

/// Return mouse position in range [-1; 1].
pub fn mouse_position_local() -> Vec2 {
    let (pixels_x, pixels_y) = mouse_position();

    convert_to_local(Vec2::new(pixels_x, pixels_y))
}

/// Returns the difference between the current mouse position and the mouse position on the previous frame.
pub fn mouse_delta_position() -> Vec2 {
    let context = get_context();

    let current_position = mouse_position_local();
    let last_position = context.last_mouse_position.unwrap_or(current_position);

    // Calculate the delta
    last_position - current_position
}

pub fn mouse_wheel() -> (f32, f32) {
    let context = get_context();
    (context.mouse_wheel.x, context.mouse_wheel.y)
}

/// Detect if the key has been pressed once
pub fn is_key_pressed(key_code: KeyCode) -> bool {
    let context = get_context();
    context.keys_pressed.contains(&key_code)
}

/// Detect if the key is being pressed
pub fn is_key_down(key_code: KeyCode) -> bool {
    let context = get_context();
    context.keys_down.contains(&key_code)
}

/// Detect if the key has been released this frame
pub fn is_key_released(key_code: KeyCode) -> bool {
    let context = get_context();
    context.keys_released.contains(&key_code)
}

/// Detect if any key is being pressed
pub fn is_any_key_down() -> bool {
    let context = get_context();
    context.keys_down.len() > 0
}

/// Return the last pressed char.
/// Each "get_char_pressed" call will consume a character from the input queue.
pub fn get_char_pressed() -> Option<char> {
    let context = get_context();
    context.chars_pressed_queue.pop_front()
}

pub(crate) fn get_char_pressed_ui() -> Option<char> {
    let context = get_context();
    context.chars_pressed_ui_queue.pop_front()
}

/// Return the last pressed key.
pub fn get_last_key_pressed() -> Option<KeyCode> {
    let context = get_context();
    // TODO: this will return a random key from keys_pressed HashMap instead of the last one, fix me later
    context.keys_pressed.iter().next().cloned()
}

pub fn get_keys_pressed() -> HashSet<KeyCode> {
    let context = get_context();
    context.keys_pressed.clone()
}

pub fn get_keys_down() -> HashSet<KeyCode> {
    let context = get_context();
    context.keys_down.clone()
}

pub fn get_keys_released() -> HashSet<KeyCode> {
    let context = get_context();
    context.keys_released.clone()
}

/// Clears input queue
pub fn clear_input_queue() {
    let context = get_context();
    context.chars_pressed_queue.clear();
    context.chars_pressed_ui_queue.clear();
    context.mouse_pressed.clear();
    context.keys_pressed.clear();
}

/// Detect if the button is being pressed
pub fn is_mouse_button_down(btn: MouseButton) -> bool {
    let context = get_context();
    context.mouse_down.contains(&btn)
}

/// Detect if the button has been pressed once
pub fn is_mouse_button_pressed(btn: MouseButton) -> bool {
    let context = get_context();
    context.mouse_pressed.contains(&btn)
}

/// Detect if the button has been released this frame
pub fn is_mouse_button_released(btn: MouseButton) -> bool {
    let context = get_context();
    context.mouse_released.contains(&btn)
}

/// Convert a position in pixels to a position in the range [-1; 1].
fn convert_to_local(pixel_pos: Vec2) -> Vec2 {
    Vec2::new(pixel_pos.x / screen_width(), pixel_pos.y / screen_height()) * 2.0
        - Vec2::new(1.0, 1.0)
}

/// Prevents quit
pub fn prevent_quit() {
    get_context().prevent_quit_event = true;
}

/// Detect if quit has been requested
pub fn is_quit_requested() -> bool {
    get_context().quit_requested
}

// Gets the files which have been dropped on the window.
// pub fn get_dropped_files() -> Vec<DroppedFile> {
//     get_context().dropped_files()
// }
