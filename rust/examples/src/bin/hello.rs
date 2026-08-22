//! hello — the smallest possible pxl app. A colored circle follows the mouse,
//! and the frame rate is drawn in the top-left corner.

use pxl::*;

simple_game!(setup, update, render, shutdown);

fn setup() {
    println!("hello: started");
}

fn update() {}

fn render() {
    pass::begin(pass::Pass {
        clear_color: Some(Color::rgb(20, 20, 30)),
        ..Default::default()
    });

    // Circle that tracks the mouse.
    let mouse = input::mouse_pos();
    draw::circle(mouse, 32.0, 32, Color::YELLOW);

    // FPS readout.
    let fps_text = format!("{:.0} FPS", time::fps());
    draw::text(&fps_text, glam::Vec2::new(8.0, 8.0), Color::WHITE);

    pass::end();
}

fn shutdown() {
    println!("hello: shutting down");
}
