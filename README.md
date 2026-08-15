# Shit TODO
- steal PolygonBuilder: https://github.com/wick3dr0se/egor/blob/f474834ad059a87866347d630d2c99375f88f588/crates/egor_glue/src/primitives.rs#L239
- steal Particles: https://github.com/darthdeus/comfy/blob/31aa6efce135ec3d8feeb8b1b2483f2c0e915d12/comfy/src/particles.rs#L17
- should Batcher Mesh just have a ?Pipeline and pushMesh takes in the uniforms to keep it as one api?
- zig-frm parallax_tilemap.zig has decent player starter
- when making an LDtk map that starts in negative x (just drag left map border to make map expand into it) collision and/or rendering get fucked up


### Build all with summary
`zig build --summary all`


### App
All callback are optional

```zig
pub fn config() pxl.Config {}
pub fn setup() !void {}
pub fn update() !void {}
pub fn render() !void {}
pub fn shutdown() !void {}
```


### Bloom (WIP)
The renderer now supports a startup bloom toggle in `pxl.Config.gfx`.

```zig
try pxl.run(init, .{
	.setup = setup,
	.render = render,
	.gfx = .{
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


### Bust Shadc Cache
In `shdc.createModule`:
```zig
.genver = b.fmt("{b}", .{std.Io.Clock.now(.awake, b.graph.io).toNanoseconds()})
```


### Android
Install Android SDK and setup ANDROID_HOME and install Build Tools and NDK
`sdkmanager "build-tools;35.0.1"`
`sdkmanager "ndk;30.0.15729638"`
`sdkmanager "platforms;android-35"`
`android install "platform-tools"`

Add Java/Android jank to PATH (.zshrc)
```
export JAVA_HOME=$(/usr/libexec/java_home)
export ANDROID_HOME=/opt/homebrew/share/android-commandlinetools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:/opt/homebrew/share/android-commandlinetools/platform-tools
```

Build all Android targets:
`zig build -Dandroid=true run-EXAMPLE`

Build just arm:
`zig build -Dtarget=aarch64-linux-android run-EXAMPLE`

Logging is redirected to logcat if `std.log.*` methods are used and can be viewed with `adb logcat -s pxl`


### Web
`zig build -Dtarget=wasm32-emscripten base`
