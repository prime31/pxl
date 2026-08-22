//! ferrismark — a bunnymark clone using ferris_smol sprites. Press Space to
//! spawn 1000 bouncing ferris at a time. Displays the count and FPS.

use glam::Vec2;
use pxl::*;
use rand::{rngs::StdRng, Rng, SeedableRng};

pxl_game!(Game, setup, update, render, shutdown);

const SPAWN_COUNT: usize = 1000;
const SPRITE_SIZE: f32 = 32.0;
const MAX_FERRIS: usize = 1_000_000;

struct Ferris {
    pos: Vec2,
    vel: Vec2,
}

struct Game {
    ferris: Vec<Ferris>,
    tex: Option<Texture>,
    rng: StdRng,
}

impl Default for Game {
    fn default() -> Self {
        Self {
            ferris: Vec::new(),
            tex: None,
            rng: StdRng::from_entropy(),
        }
    }
}

fn setup(state: &mut Game) {
    state.ferris = Vec::with_capacity(MAX_FERRIS);
    state.rng = StdRng::from_entropy();
    state.tex = Some(assets::load_texture(3).unwrap_or_else(|| {
        eprintln!("ferrismark: failed to load ferris_smol (id 3). Run from project root.");
        std::process::exit(1);
    }));
    eprintln!("ferrismark: ready — press Space to spawn");
}

fn shutdown(state: &mut Game) {
    state.tex = None;
    state.ferris.clear();
}

fn spawn_batch(state: &mut Game, w: f32, h: f32, count: usize) {
    let n = count.min(MAX_FERRIS - state.ferris.len());
    if n == 0 {
        return;
    }
    state.ferris.reserve(n);
    for _ in 0..n {
        let angle = state.rng.gen::<f32>() * std::f32::consts::TAU;
        state.ferris.push(Ferris {
            pos: Vec2::new(state.rng.gen::<f32>() * w, state.rng.gen::<f32>() * h),
            vel: Vec2::new(angle.cos(), angle.sin()) * 500.0,
        });
    }
}

fn update(state: &mut Game) {
    let w = 1024.0;
    let h = 768.0;
    let dt = time::dt();

    for f in state.ferris.iter_mut() {
        f.pos += f.vel * dt;
        if f.pos.x < 0.0 || f.pos.x > w - SPRITE_SIZE {
            f.vel.x = -f.vel.x;
            f.pos.x = f.pos.x.clamp(0.0, w - SPRITE_SIZE);
        }
        if f.pos.y < 0.0 || f.pos.y > h - SPRITE_SIZE {
            f.vel.y = -f.vel.y;
            f.pos.y = f.pos.y.clamp(0.0, h - SPRITE_SIZE);
        }
    }

    if input::key_pressed(Keycode::Space) {
        spawn_batch(state, w, h, SPAWN_COUNT);
        eprintln!("ferrismark: {} ferris", state.ferris.len());
    }
}

fn render(state: &Game) {
    pass::begin(pass::Pass {
        clear_color: Some(Color::rgb(20, 20, 28)),
        ..Default::default()
    });

    if let Some(tex) = &state.tex {
        for f in state.ferris.iter() {
            draw::texture(tex, f.pos);
        }
    }

    draw::text(
        &format!("ferris: {}    {:.0} FPS", state.ferris.len(), time::fps()),
        Vec2::new(8.0, 8.0),
        Color::WHITE,
    );

    pass::end();
}
