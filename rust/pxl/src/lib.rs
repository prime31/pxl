//! Safe Rust bindings for the pxl game framework.
//!
//! # Architecture
//! - `pxl::time`, `pxl::draw`, etc. mirror `pxl.time`, `pxl.api` in Zig.
//! - Math types use `glam` (`Vec2`, `Vec4` for colors); conversion to pxl's C
//!   types happens at the FFI boundary.
//! - Opaque handles (`Texture`, `Font`, `Tilemap`, `AnimPlayer`) wrap raw
//!   pointers with (optional) RAII guards.
//!
//! # Quick start with `simple_game!`
//!
//! ```ignore
//! use pxl::*;
//! simple_game!(setup, update, render);
//!
//! fn setup() { }
//! fn update() { }
//! fn render() {
//!     pass::begin(Pass::default());
//!     draw::rect(glam::Vec2::ZERO, glam::Vec2::new(100., 100.), Color::RED);
//!     pass::end();
//! }
//! ```
//!
//! # With state
//!
//! ```ignore
//! use pxl::*;
//!
//! struct MyGame { x: f32 }
//!
//! pxl_game!(MyGame, setup, update, render);
//!
//! fn setup(s: &mut MyGame) { s.x = 100.0; }
//! fn update(s: &mut MyGame) { s.x += time::dt() * 50.0; }
//! fn render(s: &MyGame) {
//!     pass::begin(Pass::default());
//!     draw::text(&format!("x: {:.1}", s.x), glam::Vec2::new(10., 10.), Color::WHITE);
//!     pass::end();
//! }
//! ```

pub mod assets;
pub mod audio;
pub mod draw;
pub mod input;
pub mod pass;
pub mod time;
pub mod window;

mod color;
mod math;

pub use color::Color;
pub use math::{
    Anchor, AnimCell, AxisDiagonal, BlendMode, Keycode, LoopMode, MouseButton, ResolutionPolicy,
    SfxPreset,
};

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
    pub disable_vsync: bool,
    pub enable_clipboard: bool,
    pub enable_dragndrop: bool,
    pub srgb: bool,
    pub hdr: bool,
    /// Fixed design resolution. 0 = use window size.
    pub design_width: i32,
    pub design_height: i32,
    /// How the render texture scales to the window.
    pub resolution_policy: ResolutionPolicy,
    pub bloom_enabled: bool,
    pub bloom_downsample: i32,
    pub bloom_threshold: f32,
    pub bloom_intensity: f32,
    pub bloom_blur_radius: f32,
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
            disable_vsync: false,
            enable_clipboard: false,
            enable_dragndrop: false,
            srgb: false,
            hdr: false,
            design_width: 0,
            design_height: 0,
            resolution_policy: ResolutionPolicy::Default,
            bloom_enabled: false,
            bloom_downsample: 2,
            bloom_threshold: 0.7,
            bloom_intensity: 1.2,
            bloom_blur_radius: 1.0,
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

extern "C" fn bridge_setup() {
    call_user(unsafe { CB_SETUP });
}
extern "C" fn bridge_update() {
    call_user(unsafe { CB_UPDATE });
}
extern "C" fn bridge_render() {
    call_user(unsafe { CB_RENDER });
}
extern "C" fn bridge_shutdown() {
    call_user(unsafe { CB_SHUTDOWN });
}

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
        disable_vsync: config.disable_vsync,
        enable_clipboard: config.enable_clipboard,
        enable_dragndrop: config.enable_dragndrop,
        srgb: config.srgb,
        hdr: config.hdr,
        design_width: config.design_width,
        design_height: config.design_height,
        resolution_policy: config.resolution_policy as i32,
        bloom_enabled: config.bloom_enabled,
        bloom_downsample: config.bloom_downsample,
        bloom_threshold: config.bloom_threshold,
        bloom_intensity: config.bloom_intensity,
        bloom_blur_radius: config.bloom_blur_radius,
    };
    let c_cbs = pxl_sys::PxlCallbacks {
        setup: if callbacks.setup.is_some() {
            Some(bridge_setup)
        } else {
            None
        },
        update: if callbacks.update.is_some() {
            Some(bridge_update)
        } else {
            None
        },
        render: if callbacks.render.is_some() {
            Some(bridge_render)
        } else {
            None
        },
        shutdown: if callbacks.shutdown.is_some() {
            Some(bridge_shutdown)
        } else {
            None
        },
    };
    unsafe { pxl_sys::pxl_run(c_cfg, c_cbs) };
}

// ── pxl_game! / simple_game! macros ──────────────────────────────────────────

/// Access the game state struct immutably from anywhere. Only available when
/// your game was defined with `pxl_game!`.
pub fn state<T>() -> &'static T {
    unsafe { &*(STATE_PTR as *const T) }
}

/// Access the game state struct mutably from anywhere. Only available when
/// your game was defined with `pxl_game!`.
pub fn state_mut<T>() -> &'static mut T {
    unsafe { &mut *(STATE_PTR as *mut T) }
}

/// Opaque pointer to the game state. Set by `pxl_game!`-generated code.
#[doc(hidden)]
pub static mut STATE_PTR: *mut () = std::ptr::null_mut();

/// Call at the top of `main()` so relative asset paths resolve regardless
/// of where `cargo run` is invoked from.
#[doc(hidden)]
pub fn set_project_root() {
    std::env::set_current_dir(env!("PXL_PROJECT_ROOT")).ok();
}

// ─────────────────────────────────────────────────────────────────────────────
// pxl_game! — games with a state struct.
// pxl_game!(MyState, my_config_fn, setup, update, render, shutdown);
// pxl_game!(MyState, setup, update, render, shutdown);
// pxl_game!(MyState, setup, update, render);
//
// User callbacks receive &mut MyState (setup/update/shutdown) or &MyState (render).
//
// ─────────────────────────────────────────────────────────────────────────────

#[macro_export]
macro_rules! pxl_game {
    // 4 args: state + setup/update/render (default config)
    ($state:ident, $setup:ident, $update:ident, $render:ident) => {
        static mut __PX_GAME_STATE: std::mem::MaybeUninit<$state> = std::mem::MaybeUninit::uninit();
        fn __px_setup() {
            $setup(unsafe { $crate::state_mut::<$state>() });
        }
        fn __px_update() {
            $update(unsafe { $crate::state_mut::<$state>() });
        }
        fn __px_render() {
            $render(unsafe { $crate::state::<$state>() });
        }

        fn main() {
            $crate::set_project_root();
            unsafe {
                $crate::STATE_PTR = __PX_GAME_STATE.as_mut_ptr() as *mut ();
            }

            let game = unsafe { __PX_GAME_STATE.write(<$state>::default()) };
            $crate::run(
                $crate::Config::default(),
                $crate::Callbacks {
                    setup: Some(__px_setup),
                    update: Some(__px_update),
                    render: Some(__px_render),
                    shutdown: None,
                },
            );
            let _ = game;
        }
    };

    // 5 args: state + setup/update/render/shutdown (default config)
    ($state:ident, $setup:ident, $update:ident, $render:ident, $shutdown:ident) => {
        static mut __PX_GAME_STATE: std::mem::MaybeUninit<$state> = std::mem::MaybeUninit::uninit();
        fn __px_setup() {
            $setup(unsafe { $crate::state_mut::<$state>() });
        }
        fn __px_update() {
            $update(unsafe { $crate::state_mut::<$state>() });
        }
        fn __px_render() {
            $render(unsafe { $crate::state::<$state>() });
        }
        fn __px_shutdown() {
            $shutdown(unsafe { $crate::state_mut::<$state>() });
        }
        fn main() {
            $crate::set_project_root();
            unsafe {
                $crate::STATE_PTR = __PX_GAME_STATE.as_mut_ptr() as *mut ();
            }
            let game = unsafe { __PX_GAME_STATE.write(<$state>::default()) };
            $crate::run(
                $crate::Config::default(),
                $crate::Callbacks {
                    setup: Some(__px_setup),
                    update: Some(__px_update),
                    render: Some(__px_render),
                    shutdown: Some(__px_shutdown),
                },
            );
            let _ = game;
        }
    };

    // 6 args: state + config_fn + setup/update/render/shutdown
    ($state:ident, $config_fn:ident, $setup:ident, $update:ident, $render:ident, $shutdown:ident) => {
        static mut __PX_GAME_STATE: std::mem::MaybeUninit<$state> = std::mem::MaybeUninit::uninit();
        fn __px_setup() {
            $setup(unsafe { $crate::state_mut::<$state>() });
        }
        fn __px_update() {
            $update(unsafe { $crate::state_mut::<$state>() });
        }
        fn __px_render() {
            $render(unsafe { $crate::state::<$state>() });
        }
        fn __px_shutdown() {
            $shutdown(unsafe { $crate::state_mut::<$state>() });
        }
        fn main() {
            $crate::set_project_root();
            unsafe {
                $crate::STATE_PTR = __PX_GAME_STATE.as_mut_ptr() as *mut ();
            }
            let game = unsafe { __PX_GAME_STATE.write(<$state>::default()) };
            $crate::run(
                $config_fn(),
                $crate::Callbacks {
                    setup: Some(__px_setup),
                    update: Some(__px_update),
                    render: Some(__px_render),
                    shutdown: Some(__px_shutdown),
                },
            );
            let _ = game;
        }
    }; // 5 args: state + config_fn + setup/update/render (no shutdown)

       //   NOTE: this arm is unreachable — 5 idents collides with the no-config
       //   5-ident arm above. config_fn is only supported with all 4 callbacks (6 args).
       //   ($state:ident, $config_fn:ident, $setup:ident, $update:ident, $render:ident) => { ... }
}

// ─────────────────────────────────────────────────────────────────────────────
// simple_game! — stateless games (plain fn() callbacks; use globals if needed).
//
//   simple_game!(my_config_fn, setup, update, render, shutdown);  // 5 idents
//   simple_game!(setup, update, render, shutdown);                  // 4 idents
//   simple_game!(setup, update, render);                            // 3 idents
//   simple_game!(update, render);                                   // 2 idents
//   simple_game!(update);                                           // 1 ident
// ─────────────────────────────────────────────────────────────────────────────

#[macro_export]
macro_rules! simple_game {
    // 5 idents: config_fn + setup/update/render/shutdown
    ($config_fn:ident, $setup:ident, $update:ident, $render:ident, $shutdown:ident) => {
        fn main() {
            $crate::set_project_root();
            $crate::run(
                $config_fn(),
                $crate::Callbacks {
                    setup: Some($setup),
                    update: Some($update),
                    render: Some($render),
                    shutdown: Some($shutdown),
                },
            );
        }
    };

    // 4 idents: setup/update/render/shutdown (default config)
    ($setup:ident, $update:ident, $render:ident, $shutdown:ident) => {
        fn main() {
            $crate::set_project_root();
            $crate::run(
                $crate::Config::default(),
                $crate::Callbacks {
                    setup: Some($setup),
                    update: Some($update),
                    render: Some($render),
                    shutdown: Some($shutdown),
                },
            );
        }
    };

    // 3 idents: setup/update/render (default config, no shutdown)
    ($setup:ident, $update:ident, $render:ident) => {
        fn main() {
            $crate::set_project_root();
            $crate::run(
                $crate::Config::default(),
                $crate::Callbacks {
                    setup: Some($setup),
                    update: Some($update),
                    render: Some($render),
                    ..Default::default()
                },
            );
        }
    };

    // 2 idents: update/render (default config, no setup/shutdown)
    ($update:ident, $render:ident) => {
        fn main() {
            $crate::set_project_root();
            $crate::run(
                $crate::Config::default(),
                $crate::Callbacks {
                    update: Some($update),
                    render: Some($render),
                    ..Default::default()
                },
            );
        }
    };

    // 1 ident: update only (default config, no setup/render/shutdown)
    ($update:ident) => {
        fn main() {
            $crate::set_project_root();
            $crate::run(
                $crate::Config::default(),
                $crate::Callbacks {
                    update: Some($update),
                    ..Default::default()
                },
            );
        }
    };
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
