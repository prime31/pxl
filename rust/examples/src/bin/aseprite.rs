use glam::Vec2;
use pxl::*;

pxl_game!(Game, config, setup, update, render);

const ATLAS: &str = "assets/atlases/character_robot.png";

#[derive(Default)]
struct Game {
    tex: pxl::Texture,
    player: pxl::AnimPlayer,
    pos: Vec2,
    walk: u32,
    run: u32,
    attack: u32,
}

fn config() -> pxl::Config {
    pxl::Config {
        width: 640 * 2,
        height: 320 * 2,
        design_width: 640,
        design_height: 320,
        resolution_policy: ResolutionPolicy::ShowAllPixelPerfect,
        ..Default::default()
    }
}

fn setup(state: &mut Game) {
    state.pos = Vec2 { x: 10., y: 10. };

    let atlas_id = assets::aseprite_id_by_path(ATLAS).unwrap();
    state.tex = assets::load_aseprite_path(ATLAS).unwrap();
    state.player = AnimPlayer::new();

    state.walk = assets::aseprite_anim_by_name(atlas_id, "walk").unwrap();
    state.run = assets::aseprite_anim_by_name(atlas_id, "run").unwrap();
    state.attack = assets::aseprite_anim_by_name(atlas_id, "attack").unwrap();

    state.player.play(state.walk);

    input::add_binding("left", Keycode::Left);
    input::add_binding("right", Keycode::Right);
    input::add_binding("up", Keycode::Up);
    input::add_binding("down", Keycode::Down);
}

fn update(state: &mut Game) {
    let move_amt =
        input::get_vector("left", "right", "up", "down", AxisDiagonal::Raw) * 200. * time::dt();
    state.pos += move_amt;

    if input::key_pressed(Keycode::W) {
        state.player.play(state.walk);
    }

    if input::key_pressed(Keycode::R) {
        state.player.play(state.run);
    }

    if input::key_pressed(Keycode::Space) {
        state.player.play(state.attack);
    }

    state.player.update(pxl::time::dt());
    if state.player.finished() {
        state.player.play(state.walk);
    }
}

fn render(state: &Game) {
    pass::begin(pass::Pass {
        clear_color: Some(Color::rgb(20, 20, 30)),
        ..Default::default()
    });

    let frame = state.player.current_frame().unwrap();
    let mut dst_rect = frame.rect();
    dst_rect.x = state.pos.x;
    dst_rect.y = state.pos.y;
    draw::textured_rect(&state.tex, dst_rect, frame.rect(), Color::WHITE);

    // FPS readout.
    let fps_text = format!("{:.0} FPS", time::fps());
    draw::text(&fps_text, glam::Vec2::new(8.0, 8.0), Color::WHITE);

    pass::end();
}
