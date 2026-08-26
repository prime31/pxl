package main

import "core:fmt"
import pxl ".."

Bouncer :: struct {pos, vel: pxl.Vec2, size: f32, color: pxl.Color}
game: [5]Bouncer
fps_buf: [32]u8

setup :: proc() {for &b in game {b.pos = pxl.Vec2{pxl.window_width() * 0.5, pxl.window_height() * 0.5}; b.vel = pxl.Vec2{120, 90}; b.size = 20; b.color = pxl.color_rgb(253, 249, 0)}}

update :: proc() {for &b in game {b.pos.x += b.vel.x * pxl.dt(); b.pos.y += b.vel.y * pxl.dt(); if b.pos.x < b.size || b.pos.x + b.size > pxl.window_width() {b.vel.x = -b.vel.x}; if b.pos.y < b.size || b.pos.y + b.size > pxl.window_height() {b.vel.y = -b.vel.y}}}

render :: proc() {pxl.begin_pass(pxl.color_rgb(15, 15, 25)); for &b in game {pxl.rect(b.pos, pxl.Vec2{b.size, b.size}, b.color)}; for i in 0..<len(game) {for j in (i+1)..<len(game) {pxl.line(game[i].pos, game[j].pos, 0.5, pxl.color_rgba(100, 100, 140, 60))}}; fps_text := fmt.bprintf(fps_buf[:], "FPS: %d", pxl.fps()); pxl.text(fps_text, pxl.Vec2{8, 8}, pxl.color_rgb(255, 255, 255)); pxl.end_pass()}

main :: proc() {pxl.run(pxl.Config{window_title = "Pxl", width = 1024, height = 768, debug_render_enabled = true, clear_color = pxl.color_rgb(30, 30, 40), bloom_enabled = true, bloom_downsample = 2, bloom_blur_radius = 2, bloom_intensity = 1.2, bloom_threshold = 0.2}, pxl.Callbacks{setup, update, render, nil})}
