use miniquad::*;
use png;
use std::{fs::File, io::BufReader};

pub use miniquad;
pub mod painter;

pub struct Engine {
    ctx: Box<dyn RenderingBackend>,
}

impl Engine {
    pub fn new() -> Self {
        Self {
            ctx: window::new_rendering_backend(),
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
