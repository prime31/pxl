use pxl::{get_context, prelude::*};

fn main() {
    pxl::app::App::run(setup, update);
}

fn setup() {
    println!("setup called")
}

fn update() {
    get_context().painter.set_color(1., 0., 0., 0.);
    get_context()
        .painter
        .draw_line(get_context().quad_context.as_mut(), 0., 0., 200., 200., 10.);

    get_context()
        .painter
        .flush(get_context().quad_context.as_mut());
}
