//! ferrismark — a bunnymark clone using ferris_smol sprites. Press Space to
//! spawn 1000 bouncing ferris at a time. Displays the count and FPS.

use glam::Vec2;
use pxl::{self, draw, input, pass, time, Color, Texture};

const SPAWN_COUNT: usize = 1000;
const SPRITE_SIZE: f32 = 32.0;
const MAX_FERRIS: usize = 1_000_000;

struct Ferris {
    pos: Vec2,
    vel: Vec2,
}

static mut FERRIS_LIST: Vec<Ferris> = Vec::new();
static mut FERRIS_TEX: Option<Texture> = None;
static mut RNG_STATE: u64 = 0x_dead_beef_cafe_babe;

/// Simple xorshift64*. Returns a u32 in [0, u32::MAX].
unsafe fn rand_u32() -> u32 {
    let x = &raw mut RNG_STATE;
    x.write(x.read() ^ (x.read() >> 12));
    x.write(x.read() ^ (x.read() << 25));
    x.write(x.read() ^ (x.read() >> 27));
    ((x.read().wrapping_mul(0x2545F4914F6CDD1D)) >> 32) as u32
}

unsafe fn rand_f32() -> f32 {
    rand_u32() as f32 / (u32::MAX as f32)
}

fn spawn_batch(w: f32, h: f32, count: usize) {
    let list = unsafe { &mut *(&raw mut FERRIS_LIST) };
    let remaining = MAX_FERRIS - list.len();
    let n = count.min(remaining);
    if n == 0 {
        return;
    }

    list.reserve(n);
    for _ in 0..n {
        let angle = unsafe { rand_f32() } * std::f32::consts::TAU;
        let x = unsafe { rand_f32() } * w;
        let y = unsafe { rand_f32() } * h;
        list.push(Ferris {
            pos: Vec2::new(x, y),
            vel: Vec2::new(angle.cos(), angle.sin()) * 500.0,
        });
    }
}

fn setup() {
    // ferris_smol = asset ID 3 (see pxl_assets.h).
    let tex = pxl::assets::load_texture(3).unwrap_or_else(|| {
        eprintln!("ferrismark: failed to load ferris_smol (id 3). Run from project root so assets/ is in CWD.");
        std::process::exit(1);
    });
    unsafe {
        (&raw mut FERRIS_TEX).write(Some(tex));
        (&raw mut FERRIS_LIST).write(Vec::with_capacity(MAX_FERRIS));
    }
    eprintln!("ferrismark: ready — press Space to spawn");
}

fn shutdown() {
    eprintln!("ferrismark: shutting down");
    unsafe {
        let _ = (&raw mut FERRIS_TEX).write(None);
        (&raw mut FERRIS_LIST).write(Vec::new());
    }
}

fn update() {
    let w = 1024.0;
    let h = 768.0;
    let dt = time::dt();

    let list = unsafe { &mut *(&raw mut FERRIS_LIST) };
    for f in list.iter_mut() {
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

    if input::key_pressed(pxl::Keycode::Space) {
        spawn_batch(w, h, SPAWN_COUNT);
        eprintln!("ferrismark: {} ferris", list.len());
    }
}

fn render() {
    pass::begin(pass::Pass {
        clear_color: Some(Color::rgb(20, 20, 28)),
        ..Default::default()
    });

    let tex = unsafe { (&*(&raw const FERRIS_TEX)).as_ref().unwrap() };
    let list = unsafe { &*(&raw const FERRIS_LIST) };

    for f in list.iter() {
        draw::texture(tex, f.pos);
    }

    let hud = format!("ferris: {}    {:.0} FPS", list.len(), time::fps());
    draw::text(&hud, Vec2::new(8.0, 8.0), Color::WHITE);

    pass::end();
}

fn main() {
    pxl::run(
        pxl::Config {
            window_title: "ferrismark".into(),
            ..Default::default()
        },
        pxl::Callbacks {
            setup: Some(setup),
            update: Some(update),
            render: Some(render),
            shutdown: Some(shutdown),
        },
    );
}
