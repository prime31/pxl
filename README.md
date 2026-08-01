# Shit TODO
- steal PolygonBuilder: https://github.com/wick3dr0se/egor/blob/f474834ad059a87866347d630d2c99375f88f588/crates/egor_glue/src/primitives.rs#L239
- steal Particles: https://github.com/darthdeus/comfy/blob/31aa6efce135ec3d8feeb8b1b2483f2c0e915d12/comfy/src/particles.rs#L17
- should Batcher Mesh just have a ?Pipeline and pushMesh takes in the uniforms to keep it as one api?
- zig-frm parallax_tilemap.zig has decent player starter

zig build --release=small -Dtarget=wasm32-emscripten base

## Bloom (WIP)

The renderer now supports a startup bloom toggle in `pxl.Config.gfx`.

```zig
try pxl.run(init, .{
	.setup = setup,
	.render = render,
	.gfx = .{
		.design_width = 320,
		.design_height = 180,
		.resolution_policy = .show_all_pixel_perfect,
		.bloom_enabled = true,
		.bloom_downsample = 2,
		.bloom_threshold = 0.7,
		.bloom_intensity = 1.2,
		.bloom_blur_radius = 1.0,
	},
});
```

Current implementation is RGBA8-first and uses a minimal post stack:
- bright-pass extraction
- half-res separable blur
- final composite onto the swapchain

MicroUI/imgui remain unbloomed because UI is rendered after scene composite.


### Bust Shadc Cache

In `shdc.createModule`:
```zig
.genver = b.fmt("{b}", .{std.Io.Clock.now(.awake, b.graph.io).toNanoseconds()})
```
