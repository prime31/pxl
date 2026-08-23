//! C ABI wrappers for pxl. Every public symbol follows `pxl_SUBSYSTEM_METHOD` in
//! snake_case. Math types (Vec2, Color, Rect) are already extern struct/union
//! and pass by value across the FFI boundary. Opaque handles (Texture, Sound,
//! AnimationPlayer) are passed by pointer or packed u64.

const std = @import("std");
const pxl = @import("pxl");

const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const Rect = pxl.math.Rect;
const Texture = pxl.gpu.Texture;
const Sprite = pxl.gpu.Sprite;
const Transform = pxl.gpu.Transform;
const Anchor = pxl.gpu.Anchor;
const Camera = pxl.gpu.Camera;
const AnimationId = pxl.animation.AnimationId;
const AnimationPlayer = pxl.animation.AnimationPlayer;
const Animation = pxl.animation.Animation;
const LoopMode = pxl.animation.LoopMode;
const SoundId = pxl.audio.SoundId;
const PlaybackId = pxl.audio.PlaybackId;
const BMFont = pxl.text.BMFont;
const Map = pxl.tilemap.Map;
const InputBinding = pxl.input.InputBinding;

// ── Types ────────────────────────────────────────────────────────────────────

pub const BlendMode = pxl.gpu.BlendMode;

pub const PxlConfig = extern struct {
    window_title: [*c]const u8 = "Pxl",
    width: i32 = 1024,
    height: i32 = 768,
    sample_count: i32 = 0,
    swap_interval: i32 = 0,
    high_dpi: bool = false,
    fullscreen: bool = false,
    debug_render_enabled: bool = true,
    clear_color: Color = Color.aya,
    disable_vsync: bool = false,
    enable_clipboard: bool = false,
    enable_dragndrop: bool = false,
    srgb: bool = false,
    hdr: bool = false,
    design_width: i32 = 0,
    design_height: i32 = 0,
    resolution_policy: i32 = 0,
    bloom_enabled: bool = false,
    bloom_downsample: i32 = 2,
    bloom_threshold: f32 = 0.7,
    bloom_intensity: f32 = 1.2,
    bloom_blur_radius: f32 = 1.0,
};

pub const PxlCallbacks = extern struct {
    setup: ?*const fn () callconv(.c) void = null,
    update: ?*const fn () callconv(.c) void = null,
    render: ?*const fn () callconv(.c) void = null,
    shutdown: ?*const fn () callconv(.c) void = null,
};

pub const PxlPass = extern struct {
    clear_color_value: u32 = 0,
    has_clear_color: bool = false,
    has_camera: bool = false,
    cam_offset_x: f32 = 0,
    cam_offset_y: f32 = 0,
    cam_zoom: f32 = 1,
    cam_rotation: f32 = 0,
    pixel_snap: bool = true,
};

pub const PxlAnchor = enum(i32) {
    center = 0,
    top_left = 1,
    top_center = 2,
    top_right = 3,
    center_left = 4,
    center_right = 5,
    bottom_left = 6,
    bottom_center = 7,
    bottom_right = 8,
};

fn toAnchor(a: PxlAnchor) Anchor {
    return switch (a) {
        .center => .center,
        .top_left => .top_left,
        .top_center => .top_center,
        .top_right => .top_right,
        .center_left => .center_left,
        .center_right => .center_right,
        .bottom_left => .bottom_left,
        .bottom_center => .bottom_center,
        .bottom_right => .bottom_right,
    };
}

fn packSoundId(sid: SoundId) u64 {
    return (@as(u64, @intCast(@intFromEnum(sid.generation))) << 32) | @as(u64, @intCast(sid.index));
}

fn unpackSoundId(v: u64) SoundId {
    return .{ .index = @as(u32, @truncate(v)), .generation = @enumFromInt(@as(u32, @truncate(v >> 32))) };
}

fn packPlaybackId(pid: PlaybackId) u64 {
    return (@as(u64, @intCast(@intFromEnum(pid.generation))) << 32) | @as(u64, @intCast(pid.index));
}

fn unpackPlaybackId(v: u64) PlaybackId {
    return .{ .index = @as(u32, @truncate(v)), .generation = @enumFromInt(@as(u32, @truncate(v >> 32))) };
}

fn packAnimId(id: AnimationId) u32 {
    return @intFromEnum(id);
}

fn unpackAnimId(v: u32) AnimationId {
    return @enumFromInt(v);
}

// ── Entrypoint ───────────────────────────────────────────────────────────────

// Thread-local storage for C callbacks so wrapper functions can call them.
threadlocal var c_setup: ?*const fn () callconv(.c) void = null;
threadlocal var c_update: ?*const fn () callconv(.c) void = null;
threadlocal var c_render: ?*const fn () callconv(.c) void = null;
threadlocal var c_shutdown: ?*const fn () callconv(.c) void = null;

fn wrapSetup() anyerror!void {
    if (c_setup) |cb| cb();
}
fn wrapUpdate() anyerror!void {
    if (c_update) |cb| cb();
}
fn wrapRender() anyerror!void {
    if (c_render) |cb| cb();
}
fn wrapShutdown() anyerror!void {
    if (c_shutdown) |cb| cb();
}

export fn pxl_run(config: PxlConfig, callbacks: PxlCallbacks) void {
    c_setup = callbacks.setup;
    c_update = callbacks.update;
    c_render = callbacks.render;
    c_shutdown = callbacks.shutdown;

    const cfg = pxl.Config{
        .win = .{
            .sample_count = config.sample_count,
            .swap_interval = config.swap_interval,
            .high_dpi = config.high_dpi,
            .fullscreen = config.fullscreen,
            .width = config.width,
            .height = config.height,
            .window_title = config.window_title,
            .disable_vsync = config.disable_vsync,
            .enable_clipboard = config.enable_clipboard,
            .enable_dragndrop = config.enable_dragndrop,
            .srgb = config.srgb,
            .hdr = config.hdr,
        },
        .gfx = .{
            .clear_color = config.clear_color,
            .design_width = config.design_width,
            .design_height = config.design_height,
            .resolution_policy = @enumFromInt(config.resolution_policy),
            .bloom_enabled = config.bloom_enabled,
            .bloom_downsample = config.bloom_downsample,
            .bloom_threshold = config.bloom_threshold,
            .bloom_intensity = config.bloom_intensity,
            .bloom_blur_radius = config.bloom_blur_radius,
        },
        .debug_render_enabled = config.debug_render_enabled,
    };

    const cbs = pxl.Callbacks{
        .setup = if (callbacks.setup != null) wrapSetup else null,
        .update = if (callbacks.update != null) wrapUpdate else null,
        .render = if (callbacks.render != null) wrapRender else null,
        .shutdown = if (callbacks.shutdown != null) wrapShutdown else null,
    };

    _ = pxl.run(std.Io.Threaded.global_single_threaded.io(), cfg, cbs);
}

// ── Pass ─────────────────────────────────────────────────────────────────────

export fn pxl_pass_begin(pass: PxlPass) void {
    const clear_color: ?Color = if (pass.has_clear_color) Color{ .value = pass.clear_color_value } else null;
    const camera: ?Camera = if (pass.has_camera) Camera{
        .offset = .init(pass.cam_offset_x, pass.cam_offset_y),
        .zoom = pass.cam_zoom,
        .rotation = pass.cam_rotation,
    } else null;
    pxl.beginPass(.{
        .clear_color = clear_color,
        .camera = camera,
        .pixel_snap = pass.pixel_snap,
    });
}

export fn pxl_pass_end() void {
    pxl.endPass();
}

// ── Drawing ──────────────────────────────────────────────────────────────────

export fn pxl_draw_rect(x: f32, y: f32, w: f32, h: f32, color: Color) void {
    pxl.api.drawRect(.init(x, y), .init(w, h), color);
}

export fn pxl_draw_line(x1: f32, y1: f32, x2: f32, y2: f32, thickness: f32, color: Color) void {
    pxl.api.drawLine(.init(x1, y1), .init(x2, y2), thickness, color);
}

export fn pxl_draw_circle(center_x: f32, center_y: f32, radius: f32, segments: u32, color: Color) void {
    pxl.api.drawCircle(.init(center_x, center_y), radius, segments, color);
}

export fn pxl_draw_circle_outline(center_x: f32, center_y: f32, radius: f32, thickness: f32, segments: u32, color: Color) void {
    pxl.api.drawCircleOutline(.init(center_x, center_y), radius, thickness, segments, color);
}

export fn pxl_draw_point(center_x: f32, center_y: f32, size: f32, color: Color) void {
    pxl.api.drawPoint(.init(center_x, center_y), size, color);
}

export fn pxl_draw_sprite(
    texture: *Texture,
    src_x: f32,
    src_y: f32,
    src_w: f32,
    src_h: f32,
    pos_x: f32,
    pos_y: f32,
    rotation: f32,
    scale_x: f32,
    scale_y: f32,
    color: Color,
    flip_x: bool,
    flip_y: bool,
    origin: PxlAnchor,
) void {
    const source = if (src_w <= 0 or src_h <= 0) null else Rect.init(src_x, src_y, src_w, src_h);
    pxl.api.drawSprite(
        .{ .texture = texture.*, .source = source, .color = color, .flip_x = flip_x, .flip_y = flip_y },
        .{ .pos = .init(pos_x, pos_y), .rotation = rotation, .scale = .init(scale_x, scale_y), .origin = toAnchor(origin) },
    );
}

export fn pxl_draw_texture(texture: *Texture, x: f32, y: f32) void {
    pxl.api.drawTexture(texture.*, .init(x, y));
}

export fn pxl_draw_textured_rect(
    texture: *Texture,
    dst_x: f32,
    dst_y: f32,
    dst_w: f32,
    dst_h: f32,
    src_x: f32,
    src_y: f32,
    src_w: f32,
    src_h: f32,
    color: Color,
) void {
    pxl.api.drawTexturedRect(
        texture.*,
        Rect.init(dst_x, dst_y, dst_w, dst_h),
        Rect.init(src_x, src_y, src_w, src_h),
        color,
    );
}

export fn pxl_draw_text(text: [*c]const u8, x: f32, y: f32, color: Color) void {
    const slice = std.mem.sliceTo(text, 0);
    pxl.api.drawText(null, .init(x, y), slice, color);
}

export fn pxl_draw_set_blend_mode(mode: i32) void {
    pxl.api.setBlendMode(@enumFromInt(mode));
}

export fn pxl_draw_reset_blend_mode() void {
    pxl.api.resetPipeline();
}

// ── Time ─────────────────────────────────────────────────────────────────────

export fn pxl_time_dt() f32 {
    return pxl.time.dt();
}

export fn pxl_time_fps() u32 {
    return pxl.time.fps();
}

export fn pxl_time_time() f32 {
    return pxl.time.time();
}

export fn pxl_time_frame_count() u32 {
    return pxl.time.frameCount();
}

// ── Input ────────────────────────────────────────────────────────────────────

export fn pxl_input_key_down(keycode: i32) bool {
    return pxl.input.keyDown(@enumFromInt(keycode));
}

export fn pxl_input_key_pressed(keycode: i32) bool {
    return pxl.input.keyPressed(@enumFromInt(keycode));
}

export fn pxl_input_key_up(keycode: i32) bool {
    return pxl.input.keyUp(@enumFromInt(keycode));
}

export fn pxl_input_mouse_down(button: i32) bool {
    return pxl.input.mouseDown(@enumFromInt(button));
}

export fn pxl_input_mouse_pressed(button: i32) bool {
    return pxl.input.mousePressed(@enumFromInt(button));
}

export fn pxl_input_mouse_pos(x: *f32, y: *f32) void {
    const pos = pxl.input.mousePos();
    x.* = pos.x;
    y.* = pos.y;
}

export fn pxl_input_is_action_pressed(action: [*c]const u8, action_len: usize) bool {
    return pxl.input.isActionPressed(action[0..action_len]);
}

export fn pxl_input_is_action_just_pressed(action: [*c]const u8, action_len: usize) bool {
    return pxl.input.isActionJustPressed(action[0..action_len]);
}

export fn pxl_input_add_binding(action: [*c]const u8, action_len: usize, keycode: i32) void {
    pxl.input.addBinding(action[0..action_len], pxl.input.InputBinding.key(@enumFromInt(keycode)));
}

export fn pxl_input_get_vector(
    neg_x: [*c]const u8, neg_x_len: usize,
    pos_x: [*c]const u8, pos_x_len: usize,
    neg_y: [*c]const u8, neg_y_len: usize,
    pos_y: [*c]const u8, pos_y_len: usize,
    diagonal: i32,
) Vec2 {
    return pxl.input.getVector(
        neg_x[0..neg_x_len],
        pos_x[0..pos_x_len],
        neg_y[0..neg_y_len],
        pos_y[0..pos_y_len],
        @enumFromInt(diagonal),
    );
}

// ── Window ───────────────────────────────────────────────────────────────────

export fn pxl_window_width() i32 {
    return pxl.window.width();
}
export fn pxl_window_height() i32 {
    return pxl.window.height();
}
export fn pxl_window_widthf() f32 {
    return pxl.window.widthf();
}
export fn pxl_window_heightf() f32 {
    return pxl.window.heightf();
}
export fn pxl_window_dpi_scale() f32 {
    return pxl.window.dpiScale();
}
export fn pxl_window_is_fullscreen() bool {
    return pxl.window.isFullscreen();
}
export fn pxl_window_toggle_fullscreen() void {
    pxl.window.toggleFullscreen();
}
export fn pxl_window_show_mouse(show: bool) void {
    pxl.window.showMouse(show);
}
export fn pxl_window_mouse_shown() bool {
    return pxl.window.mouseShown();
}
export fn pxl_window_lock_mouse(lock: bool) void {
    pxl.window.lockMouse(lock);
}
export fn pxl_window_mouse_locked() bool {
    return pxl.window.mouseLocked();
}
export fn pxl_window_request_quit() void {
    pxl.window.requestQuit();
}
export fn pxl_window_cancel_quit() void {
    pxl.window.cancelQuit();
}
export fn pxl_window_quit() void {
    pxl.window.quit();
}
export fn pxl_window_set_title(title: [*c]const u8) void {
    pxl.window.setWindowTitle(std.mem.sliceTo(title, 0));
}
export fn pxl_window_set_clipboard(str: [*c]const u8) void {
    pxl.window.setClipboardString(std.mem.sliceTo(str, 0));
}
export fn pxl_window_get_clipboard() [*c]const u8 {
    return pxl.window.getClipboardString().ptr;
}

export fn pxl_window_is_pixel_perfect() bool {
    return pxl.window.isPixelPerfect();
}
export fn pxl_window_render_width() i32 {
    return pxl.window.renderWidth();
}
export fn pxl_window_render_height() i32 {
    return pxl.window.renderHeight();
}
export fn pxl_window_render_widthf() f32 {
    return pxl.window.renderWidthf();
}
export fn pxl_window_render_heightf() f32 {
    return pxl.window.renderHeightf();
}

// ── Audio ────────────────────────────────────────────────────────────────────

export fn pxl_audio_load(path: [*c]const u8, streamed: bool) u64 {
    const sid = pxl.audio.load(std.mem.sliceTo(path, 0), .{ .streamed = streamed }) catch return 0;
    return packSoundId(sid);
}

export fn pxl_audio_unload(handle: u64) void {
    pxl.audio.unload(unpackSoundId(handle));
}

export fn pxl_audio_play(sound_handle: u64, volume: f32, pan: f32, pitch: f32, loop: bool) u64 {
    const pid = pxl.audio.play(unpackSoundId(sound_handle), .{
        .volume = volume,
        .pan = pan,
        .pitch = pitch,
        .loop = loop,
    }) orelse return 0;
    return packPlaybackId(pid);
}

export fn pxl_audio_play_one_shot(sound_handle: u64, volume: f32, pan: f32, pitch: f32) void {
    pxl.audio.playOneShot(unpackSoundId(sound_handle), .{ .volume = volume, .pan = pan, .pitch = pitch });
}

export fn pxl_audio_sfx(preset: i32, volume: f32, pan: f32, pitch: f32) u64 {
    const pid = pxl.audio.sfx(@enumFromInt(preset), .{ .volume = volume, .pan = pan, .pitch = pitch }) orelse return 0;
    return packPlaybackId(pid);
}

export fn pxl_audio_stop(playback_handle: u64) void {
    pxl.audio.stop(unpackPlaybackId(playback_handle));
}

export fn pxl_audio_is_playing(playback_handle: u64) bool {
    return pxl.audio.isPlaying(unpackPlaybackId(playback_handle));
}

export fn pxl_audio_playback_position(playback_handle: u64) f64 {
    return pxl.audio.position(unpackPlaybackId(playback_handle));
}

export fn pxl_audio_playback_duration(playback_handle: u64) f64 {
    return pxl.audio.duration(unpackPlaybackId(playback_handle));
}

export fn pxl_audio_sound_duration(sound_handle: u64) f64 {
    return pxl.audio.soundDuration(unpackSoundId(sound_handle));
}

// ── Assets ───────────────────────────────────────────────────────────────────

export fn pxl_assets_load_texture(id: u32) ?*Texture {
    return pxl.assets.loadTexture(@enumFromInt(id)) catch return null;
}

export fn pxl_assets_load_font(id: u32) ?*BMFont {
    return pxl.assets.loadFont(@enumFromInt(id)) catch return null;
}

export fn pxl_assets_load_tilemap(id: u32) ?*Map {
    return pxl.assets.loadTilemap(@enumFromInt(id)) catch return null;
}

export fn pxl_assets_load_audio(id: u32, streamed: bool) u64 {
    const sid = pxl.assets.loadAudio(@enumFromInt(id), .{ .streamed = streamed }) catch return 0;
    return packSoundId(sid);
}

export fn pxl_assets_destroy_texture(tex: *Texture) void {
    pxl.assets.destroy(tex);
}

export fn pxl_assets_destroy_font(font: *BMFont) void {
    pxl.assets.destroy(font);
}

export fn pxl_assets_destroy_tilemap(map: *Map) void {
    pxl.assets.destroy(map);
}

export fn pxl_assets_destroy_audio(handle: u64) void {
    pxl.assets.destroy(unpackSoundId(handle));
}

// Path-based loaders. Resolve manifest assets by their path; other paths load
// from disk at runtime (desktop/Android only — fails on web).

export fn pxl_assets_load_texture_path(path: [*c]const u8, path_len: usize) ?*Texture {
    return pxl.assets.loadTexturePath(path[0..path_len]) catch return null;
}

export fn pxl_assets_load_font_path(path: [*c]const u8, path_len: usize) ?*BMFont {
    return pxl.assets.loadFontPath(path[0..path_len]) catch return null;
}

export fn pxl_assets_load_tilemap_path(path: [*c]const u8, path_len: usize) ?*Map {
    return pxl.assets.loadTilemapPath(path[0..path_len]) catch return null;
}

// ── Animation ────────────────────────────────────────────────────────────────

export fn pxl_anim_add(
    name: [*c]const u8,
    texture: *Texture,
    cell_w: f32,
    cell_h: f32,
    cells: [*c]const struct { x: u16, y: u16 },
    cell_count: usize,
    fps: f32,
    loop_mode: i32,
) u32 {
    const n = std.mem.sliceTo(name, 0);
    const name_dupe = pxl.mem.dupe(u8, n, .persistent);
    const cells_slice = @as([*]const pxl.animation.Cell, @ptrCast(cells))[0..cell_count];
    const mode: LoopMode = @enumFromInt(loop_mode);
    const id = pxl.animation.addCells(name_dupe, texture.*, cell_w, cell_h, cells_slice, fps, mode);
    return packAnimId(id);
}

export fn pxl_anim_player_create() *AnimationPlayer {
    const player = pxl.mem.create(AnimationPlayer, .persistent);
    player.* = .{};
    return player;
}

export fn pxl_anim_player_destroy(player: *AnimationPlayer) void {
    pxl.mem.destroy(player);
}

export fn pxl_anim_player_play(player: *AnimationPlayer, anim_id: u32) void {
    player.playId(unpackAnimId(anim_id));
}

export fn pxl_anim_player_update(player: *AnimationPlayer, dt: f32) void {
    player.updateWith(dt);
}

export fn pxl_anim_player_pause(player: *AnimationPlayer) void {
    player.pause();
}

export fn pxl_anim_player_resume(player: *AnimationPlayer) void {
    player.resumePlaying();
}

export fn pxl_anim_player_stop(player: *AnimationPlayer) void {
    player.stop();
}

export fn pxl_anim_player_finished(player: *AnimationPlayer) bool {
    return player.finished();
}

export fn pxl_anim_player_set_speed(player: *AnimationPlayer, speed: f32) void {
    player.speed = speed;
}

/// Fills `tex`, `src`, `color`, `flip_x`, `flip_y` out-params for the current
/// frame. Returns false when there is no animation / no frames.
export fn pxl_anim_player_current_frame(
    player: *AnimationPlayer,
    tex: **Texture,
    src_x: *f32,
    src_y: *f32,
    src_w: *f32,
    src_h: *f32,
    color: *Color,
    flip_x: *bool,
    flip_y: *bool,
) bool {
    const anim = player.animation orelse return false;
    if (anim.frames.len == 0) return false;
    const frame = player.frame();
    tex.* = @constCast(&frame.texture);
    src_x.* = frame.source.x;
    src_y.* = frame.source.y;
    src_w.* = frame.source.w;
    src_h.* = frame.source.h;
    color.* = Color.white;
    flip_x.* = false;
    flip_y.* = false;
    return true;
}

export fn pxl_anim_player_reset(player: *AnimationPlayer) void {
    player.stop();
}

// ── Aseprite ─────────────────────────────────────────────────────────────────

export fn pxl_aseprite_load(aseprite_id: u32) ?*Texture {
    return pxl.assets.loadAseprite(@enumFromInt(aseprite_id)) catch null;
}

export fn pxl_aseprite_tag_anim(tag_id: u32) u32 {
    return packAnimId(pxl.assets.animation(@enumFromInt(tag_id)));
}

export fn pxl_aseprite_tag_count(aseprite_id: u32) u32 {
    const meta = pxl.assets.asepriteMeta(@enumFromInt(aseprite_id));
    return @intCast(meta.tags.len);
}

export fn pxl_aseprite_tag_name(tag_id: u32) [*c]const u8 {
    return pxl.assets.tagName(@enumFromInt(tag_id)).ptr;
}

export fn pxl_aseprite_frame_count(aseprite_id: u32) u32 {
    const meta = pxl.assets.asepriteMeta(@enumFromInt(aseprite_id));
    return @intCast(meta.frames.len);
}

export fn pxl_aseprite_load_path(path: [*c]const u8, path_len: usize) ?*Texture {
    return pxl.assets.loadAsepritePath(path[0..path_len]) catch return null;
}

export fn pxl_aseprite_find_id(path: [*c]const u8, path_len: usize) u32 {
    const id = pxl.assets.findAsepriteId(path[0..path_len]) orelse return std.math.maxInt(u32);
    return @intFromEnum(id);
}
