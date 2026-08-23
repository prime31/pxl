//! `use pxl::prelude::*;` — imports the most commonly used types and functions
//! so game code can write `dt()`, `rect(...)`, `key_pressed(...)`, etc. without
//! module qualifiers.

// Types
pub use crate::audio::Sound;
pub use crate::{
    Anchor, AnimCell, AnimPlayer, AxisDiagonal, BlendMode, Color, Config, Font, Frame, Keycode,
    LoopMode, MouseButton, ResolutionPolicy, SfxPreset, Texture, Tilemap,
};

// macros
pub use crate::pxl_game;
pub use crate::simple_game;

// Modules re-exported as flat functions
pub use crate::assets;
pub use crate::draw;
pub use crate::input;
pub use crate::pass;
pub use crate::time;
pub use crate::window;

// The hits — re-export the functions game code calls every frame
pub use crate::time::{dt, fps, frame_count, time};

pub use crate::draw::{
    anim_add, circle, circle_outline, line, point, rect, reset_blend_mode, set_blend_mode, sprite,
    sprite_frame, text, texture, textured_rect,
};

pub use crate::input::{
    add_binding, get_vector, is_action_just_pressed, is_action_pressed, key_down, key_pressed,
    key_up, mouse_down, mouse_pos, mouse_pressed,
};

pub use crate::pass::{begin, end};

pub use crate::assets::{
    aseprite_anim_by_name, aseprite_find_tag, aseprite_frame_count, aseprite_tag_anim,
    aseprite_tag_count, aseprite_tag_name, load_aseprite, load_audio, load_font, load_texture,
    load_tilemap,
};

pub use crate::window::{
    dpi_scale, height, heightf, is_fullscreen, is_pixel_perfect, render_height, render_heightf,
    render_width, render_widthf, toggle_fullscreen, width, widthf,
};
