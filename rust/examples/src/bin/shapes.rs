//! shapes — a few bouncing primitives built from dt-based movement. Demonstrates
//! rects, circles, lines, text, and frame-rate-independent physics.

use pxl::{self, draw, pass, time, Color};
use glam::Vec2;

struct Bouncer {
    pos: Vec2,
    vel: Vec2,
    size: f32,
    color: Color,
}

const N_BOUNCERS: usize = 5;

// Global state — pxl callbacks are 'static fn, so we use statics.
static mut BOUNCER_LIST: [Bouncer; N_BOUNCERS] = [
    Bouncer {
        pos: Vec2::new(200., 200.),
        vel: Vec2::new(180., 140.),
        size: 40.,
        color: Color::RED,
    },
    Bouncer {
        pos: Vec2::new(400., 300.),
        vel: Vec2::new(-120., 200.),
        size: 60.,
        color: Color::BLUE,
    },
    Bouncer {
        pos: Vec2::new(600., 150.),
        vel: Vec2::new(160., -180.),
        size: 25.,
        color: Color::GREEN,
    },
    Bouncer {
        pos: Vec2::new(300., 500.),
        vel: Vec2::new(100., -90.),
        size: 50.,
        color: Color::ORANGE,
    },
    Bouncer {
        pos: Vec2::new(700., 400.),
        vel: Vec2::new(-200., 160.),
        size: 35.,
        color: Color::MAGENTA,
    },
];

fn setup() {
    println!("shapes: {} bouncers ready", N_BOUNCERS);
}

fn update() {
    let dt = time::dt();
    let bouncers = unsafe { &mut *std::ptr::addr_of_mut!(BOUNCER_LIST) };

    for b in bouncers.iter_mut() {
        b.pos += b.vel * dt;

        // Bounce off the edges of a 1024×768 window.
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

fn render() {
    pass::begin(pass::Pass {
        clear_color: Some(Color::rgb(15, 15, 25)),
        ..Default::default()
    });

    let bouncers = unsafe { &*std::ptr::addr_of!(BOUNCER_LIST) };

    // Draw every bouncer as a filled rect.
    for b in bouncers.iter() {
        let half = Vec2::new(b.size, b.size);
        draw::rect(b.pos - half, half * 2.0, b.color);
    }

    // Connect each pair with a faint line for a laser-grid look.
    for i in 0..N_BOUNCERS {
        for j in (i + 1)..N_BOUNCERS {
            draw::line(
                bouncers[i].pos,
                bouncers[j].pos,
                0.5,
                Color::rgba(100, 100, 140, 60),
            );
        }
    }

    // FPS in the corner.
    draw::text(
        &format!("{:.0} FPS", time::fps()),
        Vec2::new(8.0, 8.0),
        Color::WHITE,
    );

    pass::end();
}

fn main() {
    pxl::run(
        pxl::Config {
            window_title: "shapes".into(),
            ..Default::default()
        },
        pxl::Callbacks {
            setup: Some(setup),
            update: Some(update),
            render: Some(render),
            ..Default::default()
        },
    );
}