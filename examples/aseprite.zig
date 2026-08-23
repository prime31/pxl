const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;

const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const Rect = pxl.math.Rect;

var atlas: *pxl.gpu.Texture = undefined;
var meta: *const pxl.assets.AsepriteMeta = undefined;

var player: pxl.AnimationPlayer = .{};
var current_name: []const u8 = "";

// Bound tag ids: `*_loop` tags loop, everything else plays once.
var walk_anim: pxl.AnimationId = .none;
var run_anim: pxl.AnimationId = .none;
var attack_anim: pxl.AnimationId = .none;

pub fn config() pxl.Config {
    return .{
        .win = .{
            .width = 640 * 2,
            .height = 400 * 2,
        },
        .gfx = .{
            .design_width = 640,
            .design_height = 400,
            .resolution_policy = .show_all_pixel_perfect,
        },
    };
}

pub fn setup() !void {
    atlas = try pxl.assets.loadAseprite(.character_robot);
    meta = pxl.assets.asepriteMeta(.character_robot);

    walk_anim = pxl.assets.animation(.character_robot_walk);
    run_anim = pxl.assets.animation(.character_robot_run);
    attack_anim = pxl.assets.animation(.character_robot_attack);

    player.playId(walk_anim);
    current_name = "walk (loop)";
}

pub fn update() !void {
    if (pxl.input.keyPressed(.w)) {
        player.playId(walk_anim);
        current_name = "walk (loop)";
    } else if (pxl.input.keyPressed(.r)) {
        player.playId(run_anim);
        current_name = "run (loop)";
    } else if (pxl.input.keyPressed(.space)) {
        player.playId(attack_anim);
        current_name = "attack (once)";
    }

    player.update();
    if (player.finished()) {
        player.playId(walk_anim);
        current_name = "walk (loop)";
    }
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = Color.fromBytes(11, 15, 22, 255) });

    const frame = player.frame();
    const scale: f32 = 0.6;
    const frame_x = pxl.window.renderWidthf() * 0.5 - frame.source.w * scale * 0.5;
    const frame_y: f32 = 40;
    api.drawTexturedRect(frame.texture, .{
        .x = frame_x,
        .y = frame_y,
        .w = frame.source.w * scale,
        .h = frame.source.h * scale,
    }, frame.source, Color.white);

    // Slice bounds are in sprite-canvas space, so scale them onto the drawn frame.
    for (meta.slices) |slice| {
        for (slice.keys) |key| {
            const pos = Vec2.init(
                frame_x + @as(f32, @floatFromInt(key.x)) * scale,
                frame_y + @as(f32, @floatFromInt(key.y)) * scale,
            );
            const size = Vec2.init(
                @as(f32, @floatFromInt(key.w)) * scale,
                @as(f32, @floatFromInt(key.h)) * scale,
            );
            api.drawRectOutline(pos, size, 2, Color.red);
            if (key.has_pivot) {
                const pivot = Vec2.init(
                    frame_x + key.pivot_x * scale,
                    frame_y + key.pivot_y * scale,
                );
                api.drawRect(Vec2.init(pivot.x - 3, pivot.y - 3), Vec2.init(6, 6), Color.yellow);
            }
        }
    }

    // Full exported sheet, thumbnailed in the corner.
    api.drawTexturedRect(atlas.*, .{
        .x = 8,
        .y = 8,
        .w = @as(f32, @floatFromInt(meta.size_w)) / 8,
        .h = @as(f32, @floatFromInt(meta.size_h)) / 8,
    }, Rect.init(0, 0, @floatFromInt(atlas.width), @floatFromInt(atlas.height)), Color.white);

    var y: f32 = 8;
    var buf: [256]u8 = undefined;

    const info = std.fmt.bufPrint(&buf, "playing: {s}   tags: {d}   frames: {d}   layers: {d}   slices: {d}", .{
        current_name, meta.tags.len, meta.frames.len, meta.layers.len, meta.slices.len,
    }) catch unreachable;
    api.drawText(null, Vec2.init(pxl.window.renderWidthf() * 0.5 + 40, y), info, Color.white);
    y += 16;
    api.drawText(null, Vec2.init(pxl.window.renderWidthf() * 0.5 + 40, y), "W walk, R run, SPACE attack", Color.white);

    pxl.endPass();
}
