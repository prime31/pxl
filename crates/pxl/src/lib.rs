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

pub mod app;
pub mod input;

pub mod painter;

pub mod ldtk;
pub mod math;
pub mod time;
pub mod window;

pub mod prelude;

use glam::{Mat4, Vec2, vec2};

use crate::{math::Color, painter::MiniquadPainter};

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

pub struct Context {
    // audio_context: audio::AudioContext,
    screen_width: f32,
    screen_height: f32,
    pub painter: MiniquadPainter,

    keys_down: HashSet<KeyCode>,
    keys_pressed: HashSet<KeyCode>,
    keys_released: HashSet<KeyCode>,
    mouse_down: HashSet<MouseButton>,
    mouse_pressed: HashSet<MouseButton>,
    mouse_released: HashSet<MouseButton>,
    chars_pressed_queue: VecDeque<char>,
    chars_pressed_ui_queue: VecDeque<char>,
    mouse_position: Vec2,
    last_mouse_position: Option<Vec2>,
    mouse_wheel: Vec2,

    prevent_quit_event: bool,
    quit_requested: bool,

    cursor_grabbed: bool,
    input_events: Vec<Vec<MiniquadInputEvent>>,

    // gl: QuadGl,
    camera_matrix: Option<Mat4>,

    // ui_context: UiContext,
    // coroutines_context: experimental::coroutines::CoroutinesContext,
    // fonts_storage: text::FontsStorage,
    pc_assets_folder: Option<String>,
    start_time: f64,
    last_frame_time: f64,
    frame_time: f64,

    // #[cfg(one_screenshot)]
    // counter: usize,

    // texture_batcher: texture::Batcher,
    // camera_stack: Vec<camera::CameraState>,
    pub quad_context: Box<dyn miniquad::RenderingBackend>,
    default_filter_mode: crate::FilterMode,
    // textures: crate::texture::TexturesContext,
    // dropped_files: Vec<DroppedFile>,
}

#[derive(Clone)]
enum MiniquadInputEvent {
    MouseMotion {
        x: f32,
        y: f32,
    },
    MouseWheel {
        x: f32,
        y: f32,
    },
    MouseButtonDown {
        x: f32,
        y: f32,
        btn: MouseButton,
    },
    MouseButtonUp {
        x: f32,
        y: f32,
        btn: MouseButton,
    },
    Char {
        character: char,
        modifiers: KeyMods,
        repeat: bool,
    },
    KeyDown {
        keycode: KeyCode,
        modifiers: KeyMods,
        repeat: bool,
    },
    KeyUp {
        keycode: KeyCode,
        modifiers: KeyMods,
    },
    Touch {
        phase: TouchPhase,
        id: u64,
        x: f32,
        y: f32,
    },
    WindowMinimized,
    WindowRestored,
}

impl MiniquadInputEvent {
    fn repeat<T: miniquad::EventHandler>(&self, t: &mut T) {
        use crate::MiniquadInputEvent::*;
        match self {
            MouseMotion { x, y } => t.mouse_motion_event(*x, *y),
            MouseWheel { x, y } => t.mouse_wheel_event(*x, *y),
            MouseButtonDown { x, y, btn } => t.mouse_button_down_event(*btn, *x, *y),
            MouseButtonUp { x, y, btn } => t.mouse_button_up_event(*btn, *x, *y),
            Char {
                character,
                modifiers,
                repeat,
            } => t.char_event(*character, *modifiers, *repeat),
            KeyDown {
                keycode,
                modifiers,
                repeat,
            } => t.key_down_event(*keycode, *modifiers, *repeat),
            KeyUp { keycode, modifiers } => t.key_up_event(*keycode, *modifiers),
            Touch { phase, id, x, y } => t.touch_event(*phase, *id, *x, *y),
            WindowMinimized => t.window_minimized_event(),
            WindowRestored => t.window_restored_event(),
        }
    }
}

impl Context {
    const DEFAULT_BG_COLOR: Color = math::BLACK;

    fn new(
        default_filter_mode: crate::FilterMode,
        draw_call_vertex_capacity: usize,
        draw_call_index_capacity: usize,
    ) -> Context {
        let mut ctx: Box<dyn miniquad::RenderingBackend> =
            miniquad::window::new_rendering_backend();
        let (screen_width, screen_height) = miniquad::window::screen_size();
        let painter = MiniquadPainter::new(&mut *ctx, 2048);

        Context {
            screen_width,
            screen_height,
            painter,

            keys_down: HashSet::new(),
            keys_pressed: HashSet::new(),
            keys_released: HashSet::new(),
            chars_pressed_queue: VecDeque::new(),
            chars_pressed_ui_queue: VecDeque::new(),
            mouse_down: HashSet::new(),
            mouse_pressed: HashSet::new(),
            mouse_released: HashSet::new(),
            mouse_position: vec2(0., 0.),
            last_mouse_position: None,
            mouse_wheel: vec2(0., 0.),

            prevent_quit_event: false,
            quit_requested: false,

            cursor_grabbed: false,

            input_events: Vec::new(),

            camera_matrix: None,
            // gl: QuadGl::new(
            //     &mut *ctx,
            //     draw_call_vertex_capacity,
            //     draw_call_index_capacity,
            // ),
            // ui_context: UiContext::new(&mut *ctx, screen_width, screen_height),
            // fonts_storage: text::FontsStorage::new(&mut *ctx),
            // texture_batcher: texture::Batcher::new(&mut *ctx),
            // camera_stack: vec![],

            // audio_context: audio::AudioContext::new(),
            // coroutines_context: experimental::coroutines::CoroutinesContext::new(),
            pc_assets_folder: None,

            start_time: miniquad::date::now(),
            last_frame_time: miniquad::date::now(),
            frame_time: 1. / 60.,

            #[cfg(one_screenshot)]
            counter: 0,

            quad_context: ctx,

            default_filter_mode,
            // textures: crate::texture::TexturesContext::new(),
            // dropped_files: Vec::new(),
        }
    }

    // /// Returns the handle for this texture.
    // pub fn raw_miniquad_id(&self, handle: &TextureHandle) -> miniquad::TextureId {
    //     match handle {
    //         TextureHandle::Unmanaged(texture) => *texture,
    //         TextureHandle::Managed(texture) => self
    //             .textures
    //             .texture(texture.0)
    //             .unwrap_or(self.gl.white_texture),
    //         TextureHandle::ManagedWeak(texture) => self
    //             .textures
    //             .texture(*texture)
    //             .unwrap_or(self.gl.white_texture),
    //     }
    // }

    fn begin_frame(&mut self) {
        // telemetry::begin_gpu_query("GPU");

        // self.ui_context.process_input();

        let color = Self::DEFAULT_BG_COLOR;
        get_quad_context().clear(Some((color.r, color.g, color.b, color.a)), None, None);
        // self.gl.reset();
    }

    fn end_frame(&mut self) {
        self.perform_render_passes();

        // self.ui_context.draw(get_quad_context(), &mut self.gl);
        let screen_mat = self.pixel_perfect_projection_matrix();
        // self.gl.draw(get_quad_context(), screen_mat);

        get_quad_context().commit_frame();

        #[cfg(one_screenshot)]
        {
            get_context().counter += 1;
            if get_context().counter == 3 {
                crate::prelude::get_screen_data().export_png("screenshot.png");
                panic!("screenshot successfully saved to `screenshot.png`");
            }
        }

        // telemetry::end_gpu_query();

        self.mouse_wheel = Vec2::new(0., 0.);
        self.keys_pressed.clear();
        self.keys_released.clear();
        self.mouse_pressed.clear();
        self.mouse_released.clear();
        self.last_mouse_position = Some(crate::prelude::mouse_position_local());

        self.quit_requested = false;

        // self.textures.garbage_collect(get_quad_context());

        // self.dropped_files.clear();
    }

    pub(crate) fn pixel_perfect_projection_matrix(&self) -> glam::Mat4 {
        let (width, height) = miniquad::window::screen_size();
        let dpi = miniquad::window::dpi_scale();
        glam::camera::rh::proj::opengl::orthographic(0., width / dpi, height / dpi, 0., -1., 1.)
    }

    pub(crate) fn projection_matrix(&self) -> glam::Mat4 {
        if let Some(matrix) = self.camera_matrix {
            matrix
        } else {
            self.pixel_perfect_projection_matrix()
        }
    }

    pub(crate) fn perform_render_passes(&mut self) {
        let matrix = self.projection_matrix();
        // self.gl.draw(get_quad_context(), matrix);
    }
}

#[unsafe(no_mangle)]
#[allow(static_mut_refs)]
static mut CONTEXT: Option<Context> = None;

#[allow(static_mut_refs)]
pub fn get_context() -> &'static mut Context {
    // thread_assert::same_thread();
    unsafe { CONTEXT.as_mut().unwrap_or_else(|| panic!()) }
}

#[allow(static_mut_refs)]
fn get_quad_context() -> &'static mut dyn miniquad::RenderingBackend {
    // thread_assert::same_thread();

    unsafe { assert!(CONTEXT.is_some()) }
    unsafe { &mut *CONTEXT.as_mut().unwrap().quad_context }
}
