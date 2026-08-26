package main

import pxl ".."
import "core:fmt"

ATLAS :: "assets/atlases/character_robot.png"
Game :: struct {
	tex:               ^pxl.Texture,
	player:            ^pxl.Anim_Player,
	pos:               pxl.Vec2,
	walk, run, attack: u32,
}
game: Game
fps_buf: [32]u8
setup :: proc() {
	game.pos = pxl.Vec2{10, 10}
	game.tex = pxl.load_aseprite(ATLAS); game.player = pxl.anim_player_create()
	id := pxl.find_aseprite(ATLAS)
	game.walk = pxl.aseprite_anim_by_name(id, "walk")
	game.run = pxl.aseprite_anim_by_name(id, "run")
	game.attack = pxl.aseprite_anim_by_name(id, "attack")
	pxl.anim_play(game.player, game.walk)
}

update :: proc() {move := pxl.scale(
		pxl.get_vector("left", "right", "up", "down", .RAW),
		200.0 * pxl.dt(),
	)
	game.pos.x += move.x
	game.pos.y += move.y

	if pxl.key_pressed(.W) {pxl.anim_play(game.player, game.walk)}
	if pxl.key_pressed(.R) {pxl.anim_play(game.player, game.run)}
	if pxl.key_pressed(.SPACE) {pxl.anim_play(game.player, game.attack)}

	pxl.anim_update(game.player, pxl.dt())
	if pxl.anim_finished(game.player) {
		pxl.anim_play(game.player, game.walk)
	}
}

render :: proc() {
	pxl.begin_pass(pxl.color_rgb(20, 20, 30))
	texture: ^pxl.Texture
	src: pxl.Rect
	color: pxl.Color

	if pxl.anim_current_frame(game.player, &texture, &src, &color) {
		pxl.textured_rect(texture, pxl.Rect{game.pos.x, game.pos.y, src.w, src.h}, src, color)
	}

	fps_text := fmt.bprintf(fps_buf[:], "FPS: %d", pxl.fps())
	pxl.text(fps_text, pxl.Vec2{8, 8}, pxl.color_rgb(255, 255, 255))
	pxl.end_pass()
}

shutdown :: proc() {
	pxl.anim_player_destroy(game.player)
	pxl.destroy_texture(game.tex)
	game.player = nil
	game.tex = nil
}

main :: proc() {pxl.run(
		pxl.Config {
			window_title = "Pxl",
			width = 1280,
			height = 640,
			debug_render_enabled = true,
			clear_color = pxl.color_rgb(30, 30, 40),
			bloom_downsample = 2,
			bloom_threshold = 0.7,
			bloom_intensity = 1.2,
			bloom_blur_radius = 1,
			design_width = 640,
			design_height = 320,
			resolution_policy = i32(pxl.Resolution_Policy.SHOW_ALL_PIXEL_PERFECT),
		},
		pxl.Callbacks{setup, update, render, shutdown},
	)}
