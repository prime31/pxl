use glam::Vec2;
use pxl::*;

pxl_game!(Game, config, setup, update, render, shutdown);

#[derive(Default)]
struct Game {
    pos: Vec2,
}

fn config() -> pxl::Config {
    pxl::Config {
        design_width: 640,
        design_height: 320,
        resolution_policy: ResolutionPolicy::ShowAllPixelPerfect,
        ..Default::default()
    }
}

fn setup(state: &mut Game) {
    state.pos = Vec2 { x: 10., y: 10. };

    input::add_binding("left", Keycode::Left);
    input::add_binding("right", Keycode::Right);
    input::add_binding("up", Keycode::Up);
    input::add_binding("down", Keycode::Down);
}

fn shutdown(_state: &mut Game) {}

fn update(state: &mut Game) {
    let move_amt =
        input::get_vector("left", "right", "up", "down", AxisDiagonal::Raw) * 200. * time::dt();
    state.pos += move_amt;
    // println!(
    //     "wtf: {}",
    //     input::get_vector("left", "right", "up", "down", AxisDiagonal::Raw)
    // )
}

fn render(state: &Game) {
    pass::begin(pass::Pass {
        clear_color: Some(Color::rgb(20, 20, 30)),
        ..Default::default()
    });

    // Circle that tracks the mouse.
    let mouse = input::mouse_pos();
    draw::circle(mouse, 32.0, 32, Color::YELLOW);

    draw::circle(state.pos, 32.0, 32, Color::AYA);

    // FPS readout.
    let fps_text = format!("{:.0} FPS", time::fps());
    draw::text(&fps_text, glam::Vec2::new(8.0, 8.0), Color::WHITE);

    pass::end();
}
