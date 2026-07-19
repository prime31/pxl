use crate::FilterMode::Nearest;

use super::*;

#[repr(C)]
#[derive(Copy, Clone, Debug)]
pub struct Vertex {
    pub pos: [f32; 2],
    pub uv: [f32; 2],
    pub color: [f32; 4],
}

pub struct MiniquadPainter {
    pipeline: Pipeline,
    vertex_buffer: BufferId,
    index_buffer: BufferId,
    white_texture: TextureId,

    // CPU staging vectors mimicking sokol_gp state storage arrays
    vertices: Vec<Vertex>,
    indices: Vec<u16>,

    // State management trackers
    current_texture: TextureId,
    current_color: [f32; 4],
    max_elements: usize,
}

impl MiniquadPainter {
    pub fn new(ctx: &mut Context, max_quads: usize) -> Self {
        let max_vertices = max_quads * 4;
        let max_indices = max_quads * 6;

        // 1. Create a 1x1 solid white fallback texture for shape/line rendering
        let white_pixels = [255u8, 255u8, 255u8, 255u8];
        let white_texture = ctx.new_texture(
            TextureAccess::Static,
            TextureSource::Bytes(&white_pixels),
            TextureParams {
                width: 1,
                height: 1,
                min_filter: Nearest,
                mag_filter: Nearest,
                ..Default::default()
            },
        );

        // 2. Setup GPU Dynamic streaming buffers
        let vertex_buffer = ctx.new_buffer(
            BufferType::VertexBuffer,
            BufferUsage::Stream,
            BufferSource::empty::<Vertex>(max_vertices),
        );
        let index_buffer = ctx.new_buffer(
            BufferType::IndexBuffer,
            BufferUsage::Stream,
            BufferSource::empty::<u16>(max_indices),
        );

        // 3. Setup Shaders targeting explicit low-level WebGL 100/GLSL 130 environments
        let shader = ctx
            .new_shader(
                ShaderSource::Glsl {
                    vertex: vertex_shader(),
                    fragment: fragment_shader(),
                },
                meta(),
            )
            .unwrap();

        // 4. Bind complete uniform layouts, blending, and pipeline states
        let pipeline = ctx.new_pipeline(
            &[BufferLayout::default()],
            &[
                VertexAttribute::with_buffer("pos", VertexFormat::Float2, 0),
                VertexAttribute::with_buffer("uv", VertexFormat::Float2, 0),
                VertexAttribute::with_buffer("color", VertexFormat::Float4, 0),
            ],
            shader,
            PipelineParams {
                color_blend: Some(BlendState::new(
                    Equation::Add,
                    BlendFactor::Value(BlendValue::SourceAlpha),
                    BlendFactor::OneMinusValue(BlendValue::SourceAlpha),
                )),
                ..Default::default()
            },
        );

        Self {
            pipeline,
            vertex_buffer,
            index_buffer,
            white_texture,
            vertices: Vec::with_capacity(max_vertices),
            indices: Vec::with_capacity(max_indices),
            current_texture: white_texture,
            current_color: [1.0, 1.0, 1.0, 1.0],
            max_elements: max_quads,
        }
    }

    /// Sets the color tint modifier for lines/rectangles (behaves like sgp_set_color)
    pub fn set_color(&mut self, r: f32, g: f32, b: f32, a: f32) {
        self.current_color = [r, g, b, a];
    }

    /// Dispatches all remaining stored commands over to the GPU and flushes cache state
    pub fn flush(&mut self, ctx: &mut Context) {
        if self.indices.is_empty() {
            return;
        }

        // Upload local data buffers into streaming buffer arrays
        ctx.buffer_update(self.vertex_buffer, BufferSource::slice(&self.vertices));
        ctx.buffer_update(self.index_buffer, BufferSource::slice(&self.indices));

        let bindings = Bindings {
            vertex_buffers: vec![self.vertex_buffer],
            index_buffer: self.index_buffer,
            images: vec![self.current_texture],
        };

        ctx.apply_pipeline(&self.pipeline);
        ctx.apply_bindings(&bindings);
        ctx.draw(0, self.indices.len() as i32, 1);

        // Clear CPU arrays without losing pre-allocated capacity
        self.vertices.clear();
        self.indices.clear();
    }

    /// State checking boundary validation. Flushes automatically if resources shift
    fn pre_draw(&mut self, ctx: &mut Context, needed_vertices: usize, texture: TextureId) {
        if self.current_texture != texture
            || (self.vertices.len() + needed_vertices) > (self.max_elements * 4)
        {
            self.flush(ctx);
            self.current_texture = texture;
        }
    }

    /// Draw a line using dynamic hardware-accelerated rectangle expansion
    pub fn draw_line(
        &mut self,
        ctx: &mut Context,
        x1: f32,
        y1: f32,
        x2: f32,
        y2: f32,
        thickness: f32,
    ) {
        self.pre_draw(ctx, 4, self.white_texture);

        let dx = x2 - x1;
        let dy = y2 - y1;
        let len = (dx * dx + dy * dy).sqrt();
        if len == 0.0 {
            return;
        }

        let nx = -dy / len * (thickness * 0.5);
        let ny = dx / len * (thickness * 0.5);

        let base_idx = self.vertices.len() as u16;
        let c = self.current_color;

        self.vertices.push(Vertex {
            pos: [x1 - nx, y1 - ny],
            uv: [0.0, 0.0],
            color: c,
        });
        self.vertices.push(Vertex {
            pos: [x1 + nx, y1 + ny],
            uv: [1.0, 0.0],
            color: c,
        });
        self.vertices.push(Vertex {
            pos: [x2 + nx, y2 + ny],
            uv: [1.0, 1.0],
            color: c,
        });
        self.vertices.push(Vertex {
            pos: [x2 - nx, y2 - ny],
            uv: [0.0, 1.0],
            color: c,
        });

        self.push_quad_indices(base_idx);
    }

    /// Draw an untextured rectangle shape
    pub fn draw_rect(&mut self, ctx: &mut Context, x: f32, y: f32, w: f32, h: f32) {
        self.pre_draw(ctx, 4, self.white_texture);

        let base_idx = self.vertices.len() as u16;
        let c = self.current_color;

        self.vertices.push(Vertex {
            pos: [x, y],
            uv: [0.0, 0.0],
            color: c,
        });
        self.vertices.push(Vertex {
            pos: [x + w, y],
            uv: [1.0, 0.0],
            color: c,
        });
        self.vertices.push(Vertex {
            pos: [x + w, y + h],
            uv: [1.0, 1.0],
            color: c,
        });
        self.vertices.push(Vertex {
            pos: [x, y + h],
            uv: [0.0, 1.0],
            color: c,
        });

        self.push_quad_indices(base_idx);
    }

    /// Draw a quad using user provided textures
    pub fn draw_texture(
        &mut self,
        ctx: &mut Context,
        texture: TextureId,
        x: f32,
        y: f32,
        w: f32,
        h: f32,
    ) {
        self.pre_draw(ctx, 4, texture);

        let base_idx = self.vertices.len() as u16;
        let c = self.current_color;

        self.vertices.push(Vertex {
            pos: [x, y],
            uv: [0.0, 0.0],
            color: c,
        });
        self.vertices.push(Vertex {
            pos: [x + w, y],
            uv: [1.0, 0.0],
            color: c,
        });
        self.vertices.push(Vertex {
            pos: [x + w, y + h],
            uv: [1.0, 1.0],
            color: c,
        });
        self.vertices.push(Vertex {
            pos: [x, y + h],
            uv: [0.0, 1.0],
            color: c,
        });

        self.push_quad_indices(base_idx);
    }

    fn push_quad_indices(&mut self, base: u16) {
        self.indices.push(base);
        self.indices.push(base + 1);
        self.indices.push(base + 2);
        self.indices.push(base);
        self.indices.push(base + 2);
        self.indices.push(base + 3);
    }
}

fn meta() -> ShaderMeta {
    ShaderMeta {
        images: vec!["tex".to_string()],
        uniforms: UniformBlockLayout { uniforms: vec![] },
    }
}

fn vertex_shader() -> &'static str {
    r#"#version 100
    attribute vec2 pos;
    attribute vec2 uv;
    attribute vec4 color;
    varying vec2 tex_coord;
    varying vec4 frag_color;
    void main() {
        gl_Position = vec4(pos, 0.0, 1.0);
        tex_coord = uv;
        frag_color = color;
    }"#
}

fn fragment_shader() -> &'static str {
    r#"#version 100
    precision mediump float;
    varying vec2 tex_coord;
    varying vec4 frag_color;
    uniform sampler2D tex;
    void main() {
        gl_FragColor = texture2D(tex, tex_coord) * frag_color;
    }"#
}
