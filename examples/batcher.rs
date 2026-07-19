use pxl::{load_texture_from_png, miniquad::*, painter::MiniquadPainter};

struct Stage {
    // Keep rendering backend owned inside your state space structure
    mq_ctx: Box<dyn RenderingBackend>,
    painter: MiniquadPainter,
    texture: TextureId,
}

impl Stage {
    fn new() -> Self {
        // Instantiate the modern context-less rendering factory instance
        let mut mq_ctx = window::new_rendering_backend();
        let painter = MiniquadPainter::new(&mut *mq_ctx, 2048);
        let texture = load_texture_from_png(&mut *mq_ctx, "examples/assets/ferris_smol.png");

        Self {
            mq_ctx,
            painter,
            texture,
        }
    }
}

impl EventHandler for Stage {
    // Signature fixed to comply with modern zero-parameter specification
    fn update(&mut self) {}

    // Signature fixed to comply with modern zero-parameter specification
    fn draw(&mut self) {
        let ctx = &mut *self.mq_ctx;

        // Modern backend default render pass execution wrapper
        ctx.begin_default_pass(PassAction::clear_color(0.15, 0.15, 0.15, 1.0));

        // 1. Draw a red line
        self.painter.set_color(1.0, 0.0, 0.0, 1.0);
        self.painter.draw_line(ctx, -0.8, 0.8, 0.8, -0.8, 0.03);

        // 2. Draw a green box
        self.painter.set_color(0.0, 1.0, 0.0, 1.0);
        self.painter.draw_rect(ctx, -0.2, -0.2, 0.4, 0.4);

        self.painter.set_color(1., 1.0, 1.0, 1.0);
        self.painter
            .draw_texture(ctx, self.texture, -0.2, -0.2, 0.4, 0.4);

        // 3. Batch flush inside target default render bounds
        self.painter.flush(ctx);

        ctx.end_render_pass();
        ctx.commit_frame();
    }
}

fn main() {
    // miniquad::start(conf, move || Box::new(Stage::new()));
    pxl::miniquad::start(conf::Conf::default(), move || Box::new(Stage::new()));
}
