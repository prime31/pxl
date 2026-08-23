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

// ── Aseprite ─────────────────────────────────────────────────────────────────

/// Load an aseprite atlas texture and register one `Animation` per tag.
/// Returns the atlas texture; release with `pxl::assets::destroy_texture`.
pub fn load_aseprite(aseprite_id: u32) -> Option<Texture> {
    let raw = unsafe { pxl_sys::pxl_aseprite_load(aseprite_id) };
    if raw.is_null() { None } else { Some(Texture { raw }) }
}

/// Get the `AnimationId` for an aseprite tag (global tag index).
pub fn aseprite_tag_anim(tag_id: u32) -> u32 {
    unsafe { pxl_sys::pxl_aseprite_tag_anim(tag_id) }
}

/// Number of tags in an aseprite file.
pub fn aseprite_tag_count(aseprite_id: u32) -> u32 {
    unsafe { pxl_sys::pxl_aseprite_tag_count(aseprite_id) }
}

/// Get the name of a tag by its global index.
pub fn aseprite_tag_name(tag_id: u32) -> String {
    let ptr = unsafe { pxl_sys::pxl_aseprite_tag_name(tag_id) };
    if ptr.is_null() {
        String::new()
    } else {
        unsafe { std::ffi::CStr::from_ptr(ptr) }
            .to_string_lossy()
            .into_owned()
    }
}

/// Number of frames in an aseprite file.
pub fn aseprite_frame_count(aseprite_id: u32) -> u32 {
    unsafe { pxl_sys::pxl_aseprite_frame_count(aseprite_id) }
}

/// Find a tag by name within an aseprite file. Returns the global tag id
/// (usable with `aseprite_tag_anim`) or `None` if no tag matches.
/// Case-insensitive comparison. Zero-allocation: compares C strings directly.
pub fn aseprite_find_tag(aseprite_id: u32, name: &str) -> Option<u32> {
    let count = aseprite_tag_count(aseprite_id);
    for i in 0..count {
        let ptr = unsafe { pxl_sys::pxl_aseprite_tag_name(i) };
        if !ptr.is_null() {
            let tag_name = unsafe { std::ffi::CStr::from_ptr(ptr) };
            if tag_name.to_bytes().eq_ignore_ascii_case(name.as_bytes()) {
                return Some(i);
            }
        }
    }
    None
}

/// Find a tag by name and return its AnimationId. Returns `None` if not found.
pub fn aseprite_anim_by_name(aseprite_id: u32, name: &str) -> Option<u32> {
    aseprite_find_tag(aseprite_id, name).map(aseprite_tag_anim)
}
