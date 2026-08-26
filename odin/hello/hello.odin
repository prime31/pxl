package main

import pxl ".."

Game :: struct {
	pos: pxl.Vec2,
}
game: Game

setup :: proc() {
	game.pos = pxl.Vec2{10, 10};
	pxl.add_binding("left", .LEFT);
	pxl.add_binding(
		"right",
		.RIGHT,
	)
	pxl.add_binding("up", .UP)
	pxl.add_binding("down", .DOWN)
}

update :: proc() {
	move := pxl.scale(
		pxl.get_vector("left", "right", "up", "down", .RAW),
		200.0 * pxl.dt(),
	)
	game.pos.x += move.x
	game.pos.y += move.y
}

render :: proc() {
	pxl.begin_pass(pxl.color_rgb(20, 20, 30));
	pxl.circle(
		pxl.mouse_pos(),
		32,
		32,
		pxl.color_rgb(253, 249, 0),
	)
	pxl.circle(game.pos, 32, 32, pxl.color_rgb(200, 122, 255))
	pxl.text("FPS", pxl.Vec2{8, 8}, pxl.color_rgb(255, 255, 255))
	pxl.end_pass()
}

main :: proc() {
	pxl.run(
		pxl.Config {
			window_title = "Pxl",
			width = 1024,
			height = 768,
			debug_render_enabled = true,
			clear_color = pxl.color_rgb(30, 30, 40),
			bloom_downsample = 2,
			bloom_threshold = 0.7,
			bloom_intensity = 1.2,
			bloom_blur_radius = 1,
		},
		pxl.Callbacks{setup, update, render, nil},
	)
}
