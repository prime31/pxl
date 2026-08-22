//! Asset loading — mirrors `pxl.assets.*` in Zig.
//! Asset IDs are defined in the generated `pxl_assets.h` header. To use them in
//! Rust, either:
//! - Manually transcribe the constants (they're stable integers), or
//! - Generate them with a build script that parses the C header.
//!
//! For now, pass the id integers directly from the C enum values.

use pxl_sys;

use crate::{Font, Texture, Tilemap, audio::Sound};

pub fn load_texture(id: u32) -> Option<Texture> {
    let raw = unsafe { pxl_sys::pxl_assets_load_texture(id) };
    if raw.is_null() { None } else { Some(Texture { raw }) }
}

pub fn load_font(id: u32) -> Option<Font> {
    let raw = unsafe { pxl_sys::pxl_assets_load_font(id) };
    if raw.is_null() { None } else { Some(Font { raw }) }
}

pub fn load_tilemap(id: u32) -> Option<Tilemap> {
    let raw = unsafe { pxl_sys::pxl_assets_load_tilemap(id) };
    if raw.is_null() { None } else { Some(Tilemap { raw }) }
}

pub fn load_audio(id: u32, streamed: bool) -> Option<Sound> {
    let handle = unsafe { pxl_sys::pxl_assets_load_audio(id, streamed) };
    if handle == 0 { None } else { Some(Sound(handle)) }
}