use miniquad::*;
use png;
use std::{
    collections::{HashSet, VecDeque},
    fs::File,
    io::BufReader,
};

// reexports
pub use miniquad;
pub use serde_json;

pub mod input;

pub mod painter;

pub mod ldtk;
pub mod math;
pub mod time;
pub mod window;

pub mod prelude;

use glam::Vec2;

pub struct Engine {
    ctx: Box<dyn RenderingBackend>,
}

impl Engine {
    pub fn new() -> Self {
        Self {
            ctx: miniquad::window::new_rendering_backend(),
        }
    }
}

/// Fully loads a local PNG file and registers it as a GPU texture handle via Miniquad.
/// Returns a valid `TextureId` ready to be passed directly into your painter batcher.
pub fn load_texture_from_png(ctx: &mut dyn RenderingBackend, file_path: &str) -> TextureId {
    let file = File::open(file_path).expect("Failed to open PNG file!");
    let buffered_file = BufReader::new(file);

    // 1. Initialize the decoder
    let mut decoder = png::Decoder::new(buffered_file);

    // 2. FORCE the decoder to expand RGB, grayscale, or paletted images into standard 8-bit RGBA
    decoder.set_transformations(png::Transformations::EXPAND | png::Transformations::ALPHA);

    let mut reader = decoder
        .read_info()
        .expect("Failed to read PNG metadata info!");

    // 3. Allocate the buffer using the transformed, expanded layout requirements
    let buffer_size = reader
        .output_buffer_size()
        .expect("Invalid buffer size calculations!");
    let mut pixel_buffer = vec![0; buffer_size];

    let frame_info = reader
        .next_frame(&mut pixel_buffer)
        .expect("Failed to decode PNG bytes!");
    pixel_buffer.truncate(frame_info.buffer_size());

    // 4. Send the fully expanded 4-byte-per-pixel buffer to Miniquad
    ctx.new_texture_from_data_and_format(
        &pixel_buffer,
        TextureParams {
            kind: TextureKind::Texture2D,
            width: frame_info.width,
            height: frame_info.height,
            format: TextureFormat::RGBA8,
            wrap: TextureWrap::Clamp,
            min_filter: FilterMode::Nearest,
            mag_filter: FilterMode::Nearest,
            ..Default::default()
        },
    )
}

struct Context {
    // audio_context: audio::AudioContext,
    screen_width: f32,
    screen_height: f32,

    // simulate_mouse_with_touch: bool,
    keys_down: HashSet<KeyCode>,
    keys_pressed: HashSet<KeyCode>,
    keys_released: HashSet<KeyCode>,
    mouse_down: HashSet<MouseButton>,
    mouse_pressed: HashSet<MouseButton>,
    mouse_released: HashSet<MouseButton>,
    // touches: HashMap<u64, input::Touch>,
    chars_pressed_queue: VecDeque<char>,
    chars_pressed_ui_queue: VecDeque<char>,
    mouse_position: Vec2,
    last_mouse_position: Option<Vec2>,
    mouse_wheel: Vec2,

    prevent_quit_event: bool,
    quit_requested: bool,

    cursor_grabbed: bool,
    // input_events: Vec<Vec<MiniquadInputEvent>>,

    // gl: QuadGl,
    // camera_matrix: Option<Mat4>,

    // ui_context: UiContext,
    // coroutines_context: experimental::coroutines::CoroutinesContext,
    // fonts_storage: text::FontsStorage,

    // pc_assets_folder: Option<String>,
    start_time: f64,
    last_frame_time: f64,
    frame_time: f64,

    // #[cfg(one_screenshot)]
    // counter: usize,

    // camera_stack: Vec<camera::CameraState>,
    // texture_batcher: texture::Batcher,
    // unwind: bool,
    // recovery_future: Option<Pin<Box<dyn Future<Output = ()>>>>,
    quad_context: Box<dyn miniquad::RenderingBackend>,
    // default_filter_mode: crate::quad_gl::FilterMode,
    // textures: crate::texture::TexturesContext,

    // update_on: conf::UpdateTrigger,

    // dropped_files: Vec<DroppedFile>,
}

// TODO: impl Context

#[unsafe(no_mangle)]
static mut CONTEXT: Option<Context> = None;

#[allow(static_mut_refs)]
fn get_context() -> &'static mut Context {
    // thread_assert::same_thread();
    unsafe { CONTEXT.as_mut().unwrap_or_else(|| panic!()) }
}

#[allow(static_mut_refs)]
fn get_quad_context() -> &'static mut dyn miniquad::RenderingBackend {
    // thread_assert::same_thread();

    unsafe { assert!(CONTEXT.is_some()) }
    unsafe { &mut *CONTEXT.as_mut().unwrap().quad_context }
}
