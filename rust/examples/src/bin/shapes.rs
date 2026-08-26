//! shapes — a few bouncing primitives built from dt-based movement. Demonstrates
//! rects, circles, lines, text, and frame-rate-independent physics.

use glam::Vec2;
use pxl::prelude::*;
use rand::Rng;

pxl_game!(Game, config, setup, update, render);

#[derive(Default)]
struct Bouncer {
    pos: Vec2,
    vel: Vec2,
    size: f32,
    color: Color,
}

#[derive(Default)]
struct Game {
    bouncers: [Bouncer; 5],
}

fn config() -> Config {
    Config {
        bloom_enabled: true,
        bloom_blur_radius: 2.,
        bloom_intensity: 1.2,
        bloom_downsample: 2,
        bloom_threshold: 0.2,
        ..Default::default()
    }
}

fn setup(state: &mut Game) {
    for b in state.bouncers.iter_mut() {
        b.pos = Vec2 {
            x: rand::random(),
            y: rand::random(),
        } * f32::min(window::widthf(), pxl::window::heightf());
        b.vel = Vec2 {
            x: rand::thread_rng().gen_range(-200.0..200.),
            y: rand::thread_rng().gen_range(-200.0..200.),
        };
        b.size = rand::thread_rng().gen_range(20.0..60.);
        b.color = Color(rand::random::<u32>() | 0xFF000000);
    }
}

fn update(state: &mut Game) {
    let dt = time::dt();

    for b in state.bouncers.iter_mut() {
        b.pos += b.vel * dt;

        if b.pos.x - b.size < 0.0 {
            b.pos.x = b.size;
            b.vel.x = -b.vel.x;
        }
        if b.pos.x + b.size > 1024.0 {
            b.pos.x = 1024.0 - b.size;
            b.vel.x = -b.vel.x;
        }
        if b.pos.y - b.size < 0.0 {
            b.pos.y = b.size;
            b.vel.y = -b.vel.y;
        }
        if b.pos.y + b.size > 768.0 {
            b.pos.y = 768.0 - b.size;
            b.vel.y = -b.vel.y;
        }
    }
}

fn render(state: &Game) {
    pass::begin(pass::Pass {
        clear_color: Some(Color::rgb(15, 15, 25)),
        ..Default::default()
    });

    for b in state.bouncers.iter() {
        let half = Vec2::new(b.size, b.size);
        draw::rect(b.pos - half, half * 2.0, b.color);
    }

    for i in 0..state.bouncers.len() {
        for j in (i + 1)..state.bouncers.len() {
            draw::line(
                state.bouncers[i].pos,
                state.bouncers[j].pos,
                0.5,
                Color::rgba(100, 100, 140, 60),
            );
        }
    }

    draw::text(
        &format!("{:.0} FPS", time::fps()),
        Vec2::new(8.0, 8.0),
        Color::WHITE,
    );
    pass::end();
}
