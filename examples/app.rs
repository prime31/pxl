use pxl::prelude::*;

fn main() {
    pxl::app::App::run(setup, update);
}

fn setup() {
    println!("setup called")
}

fn update() {}
