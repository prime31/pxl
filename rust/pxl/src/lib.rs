//! Safe Rust bindings for the pxl game framework.
//!
//! # Architecture
//! - `pxl::time`, `pxl::draw`, etc. mirror `pxl.time`, `pxl.api` in Zig.
//! - Math types use `glam` (`Vec2`, `Vec4` for colors); conversion to pxl's C
//!   types happens at the FFI boundary.
//! - Opaque handles (`Texture`, `Font`, `Tilemap`, `AnimPlayer`) wrap raw
//!   pointers with (optional) RAII guards.
//!
//! # Example
//! ```no_run
//! pxl::run(pxl::Config::default(), pxl::Callbacks {
//!     setup: Some(|| { /* load assets */ }),
//!     update: Some(|| { /* game logic */ }),
//!     render: Some(|| {
//!         pxl::pass::begin(pxl::Pass::default());
//!         pxl::draw::rect(glam::Vec2::ZERO, glam::Vec2::new(100., 100.), pxl::Color::RED);
//!         pxl::pass::end();
//!     }),
//!     ..Default::default()
//! });
//! ```

pub mod assets;
pub mod audio;
pub mod draw;
pub mod input;
pub mod pass;
pub mod time;

mod color;
mod math;

pub use color::Color;
pub use math::{Anchor, AnimCell, BlendMode, Keycode, LoopMode, MouseButton, SfxPreset};

// ── Config & entrypoint ──────────────────────────────────────────────────────

use std::ffi::CString;

/// Window and engine configuration.
#[derive(Clone)]
pub struct Config {
    pub window_title: String,
    pub width: i32,
    pub height: i32,
    pub sample_count: i32,
    pub swap_interval: i32,
    pub high_dpi: bool,
    pub fullscreen: bool,
    pub debug_render_enabled: bool,
    pub clear_color: Color,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            window_title: "Pxl".into(),
            width: 1024,
            height: 768,
            sample_count: 0,
            swap_interval: 0,
            high_dpi: false,
            fullscreen: false,
            debug_render_enabled: true,
            clear_color: Color::AYA,
        }
    }
}

/// Application callbacks. All fields are optional; `None` means no-op.
/// Regular Rust `fn()` pointers — the wrapper converts them to the C ABI.
#[derive(Default)]
pub struct Callbacks {
    pub setup: Option<fn()>,
    pub update: Option<fn()>,
    pub render: Option<fn()>,
    pub shutdown: Option<fn()>,
}

// Thread-local storage so the C↔Rust bridge functions can call back.
static mut CB_SETUP: Option<fn()> = None;
static mut CB_UPDATE: Option<fn()> = None;
static mut CB_RENDER: Option<fn()> = None;
static mut CB_SHUTDOWN: Option<fn()> = None;

extern "C" fn bridge_setup() { call_user(unsafe { CB_SETUP }); }
extern "C" fn bridge_update() { call_user(unsafe { CB_UPDATE }); }
extern "C" fn bridge_render() { call_user(unsafe { CB_RENDER }); }
extern "C" fn bridge_shutdown() { call_user(unsafe { CB_SHUTDOWN }); }

/// Call a user fn, catching panics so they don't unwind across the C ABI
/// boundary (which causes `panic_cannot_unwind` → abort).
fn call_user(cb: Option<fn()>) {
    if let Some(f) = cb {
        let _ = std::panic::catch_unwind(std::panic::AssertUnwindSafe(f));
    }
}

/// Start the engine. Blocks the calling thread until the window closes.
pub fn run(config: Config, callbacks: Callbacks) {
    unsafe {
        CB_SETUP = callbacks.setup;
        CB_UPDATE = callbacks.update;
        CB_RENDER = callbacks.render;
        CB_SHUTDOWN = callbacks.shutdown;
    }

    let title = CString::new(config.window_title).unwrap();
    let c_cfg = pxl_sys::PxlConfig {
        window_title: title.as_ptr(),
        width: config.width,
        height: config.height,
        sample_count: config.sample_count,
        swap_interval: config.swap_interval,
        high_dpi: config.high_dpi,
        fullscreen: config.fullscreen,
        debug_render_enabled: config.debug_render_enabled,
        clear_color: config.clear_color.0,
    };
    let c_cbs = pxl_sys::PxlCallbacks {
        setup: if callbacks.setup.is_some() { Some(bridge_setup) } else { None },
        update: if callbacks.update.is_some() { Some(bridge_update) } else { None },
        render: if callbacks.render.is_some() { Some(bridge_render) } else { None },
        shutdown: if callbacks.shutdown.is_some() { Some(bridge_shutdown) } else { None },
    };
    unsafe { pxl_sys::pxl_run(c_cfg, c_cbs) };
}

// ── Handles ──────────────────────────────────────────────────────────────────

/// Loaded texture. Dropping calls `pxl.assets.destroy(texture)`.
pub struct Texture {
    pub(crate) raw: *mut pxl_sys::PxlTexture,
}

impl Drop for Texture {
    fn drop(&mut self) {
        unsafe { pxl_sys::pxl_assets_destroy_texture(self.raw) };
    }
}

/// Loaded font.
pub struct Font {
    pub(crate) raw: *mut pxl_sys::PxlFont,
}

impl Drop for Font {
    fn drop(&mut self) {
        unsafe { pxl_sys::pxl_assets_destroy_font(self.raw) };
    }
}

/// Loaded tilemap.
pub struct Tilemap {
    pub(crate) raw: *mut pxl_sys::PxlTilemap,
}

impl Drop for Tilemap {
    fn drop(&mut self) {
        unsafe { pxl_sys::pxl_assets_destroy_tilemap(self.raw) };
    }
}

/// Animation player. Dropping calls `anim_player_destroy`.
pub struct AnimPlayer {
    pub(crate) raw: *mut pxl_sys::PxlAnimPlayer,
}

impl AnimPlayer {
    pub fn new() -> Self {
        let raw = unsafe { pxl_sys::pxl_anim_player_create() };
        assert!(!raw.is_null(), "pxl_anim_player_create returned null");
        Self { raw }
    }

    pub fn play(&mut self, anim_id: u32) {
        unsafe { pxl_sys::pxl_anim_player_play(self.raw, anim_id) };
    }

    pub fn update(&mut self, dt: f32) {
        unsafe { pxl_sys::pxl_anim_player_update(self.raw, dt) };
    }

    pub fn pause(&mut self) {
        unsafe { pxl_sys::pxl_anim_player_pause(self.raw) };
    }

    pub fn resume(&mut self) {
        unsafe { pxl_sys::pxl_anim_player_resume(self.raw) };
    }

    pub fn stop(&mut self) {
        unsafe { pxl_sys::pxl_anim_player_stop(self.raw) };
    }

    pub fn finished(&self) -> bool {
        unsafe { pxl_sys::pxl_anim_player_finished(self.raw) }
    }

    pub fn set_speed(&mut self, speed: f32) {
        unsafe { pxl_sys::pxl_anim_player_set_speed(self.raw, speed) };
    }

    /// Returns the current frame sprite data, or `None` if the animation has no
    /// frames or is not playing.
    pub fn current_frame(&self) -> Option<Frame> {
        let mut tex: *const pxl_sys::PxlTexture = std::ptr::null();
        let mut src_x: f32 = 0.0;
        let mut src_y: f32 = 0.0;
        let mut src_w: f32 = 0.0;
        let mut src_h: f32 = 0.0;
        let mut color: pxl_sys::PxlColor = 0;
        let mut flip_x: bool = false;
        let mut flip_y: bool = false;
        let ok = unsafe {
            pxl_sys::pxl_anim_player_current_frame(
                self.raw,
                &mut tex,
                &mut src_x,
                &mut src_y,
                &mut src_w,
                &mut src_h,
                &mut color,
                &mut flip_x,
                &mut flip_y,
            )
        };
        if !ok {
            return None;
        }
        Some(Frame {
            src_x,
            src_y,
            src_w,
            src_h,
            flip_x,
            flip_y,
        })
    }

    pub fn reset(&mut self) {
        unsafe { pxl_sys::pxl_anim_player_reset(self.raw) };
    }
}

impl Drop for AnimPlayer {
    fn drop(&mut self) {
        unsafe { pxl_sys::pxl_anim_player_destroy(self.raw) };
    }
}

/// A frame returned by `AnimPlayer::current_frame`.
#[derive(Debug, Clone, Copy)]
pub struct Frame {
    pub src_x: f32,
    pub src_y: f32,
    pub src_w: f32,
    pub src_h: f32,
    pub flip_x: bool,
    pub flip_y: bool,
}