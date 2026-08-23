const std = @import("std");

const pxl = @import("pxl");
const api = pxl.api;

const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const Texture = pxl.gpu.Texture;
const Frame = pxl.animation.Frame;

const cell_size = 34;
var sprites_tex: *Texture = undefined;
var tiles_tex: *Texture = undefined;
var parsed_frames: []const Frame = &.{};

var tile_anim: pxl.AnimationId = .none;
var animator: pxl.AnimationPlayer = .{};

pub fn config() pxl.Config {
    return .{
        .gfx = .{
            .design_width = 640,
            .design_height = 320,
            .resolution_policy = .show_all_pixel_perfect,
        },
    };
}

pub fn setup() !void {
    sprites_tex = try pxl.assets.loadTexture(.sprites);
    tiles_tex = try pxl.assets.loadTexture(.blacknwhite);

    parsed_frames = pxl.animation.gridFrames(sprites_tex.*, cell_size, cell_size, 0, 0, 0, 1000, 0.1);
    tile_anim = pxl.animation.addGrid("tiles", tiles_tex.*, 12, 12, 1, 1, 21, 4, 0.1, .loop);

    animator.playId(tile_anim);
}

pub fn shutdown() !void {
    pxl.assets.destroy(sprites_tex);
    pxl.assets.destroy(tiles_tex);
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = Color.fromBytes(11, 15, 22, 255) });

    var pos = Vec2.one;
    for (ranges) |range| {
        const frames = parsed_frames[range.start..][0..range.len];
        const elapsed: usize = @intFromFloat(@floor(pxl.time.time() / 0.1));
        const frame = frames[elapsed % frames.len];
        api.drawTexturedRect(frame.texture, .{
            .x = pos.x,
            .y = pos.y,
            .w = frame.source.w,
            .h = frame.source.h,
        }, frame.source, Color.white);

        pos.x += cell_size;
        if (pos.x > pxl.window.renderWidthf()) {
            pos.x = 1;
            pos.y += cell_size;
        }
    }

    pos.x = 1;
    pos.y += 100;
    animator.update();
    const frame = animator.frame();
    api.drawTexturedRect(frame.texture, .{
        .x = pos.x + 50,
        .y = pos.y,
        .w = frame.source.w * 5,
        .h = frame.source.h * 5,
    }, frame.source, Color.white);

    const text_pos = Vec2.init(pxl.window.renderWidthf() * 0.5 - 100, pxl.window.renderHeightf() * 0.5);
    api.drawText(null, text_pos, "fucking a-right ass\nmother FOOKER", Color.white);

    pxl.endPass();
}

const Range = struct { start: usize, len: usize };

const ranges = [_]Range{
    // --- Pink Blob (Top-Left) ---
    .{ .start = (0 * 35) + 0, .len = 12 }, // 0: Idle
    .{ .start = (1 * 35) + 0, .len = 12 }, // 1: Move
    .{ .start = (2 * 35) + 0, .len = 12 }, // 2: Attack
    .{ .start = (3 * 35) + 0, .len = 12 }, // 3: Hit
    .{ .start = (4 * 35) + 0, .len = 12 }, // 4: Death
    .{ .start = (5 * 35) + 0, .len = 12 }, //

    // --- Red Bat (Top-Middle) ---
    .{ .start = (0 * 35) + 12, .len = 12 }, // 5: Idle
    .{ .start = (1 * 35) + 12, .len = 12 }, // 6: Move
    .{ .start = (2 * 35) + 12, .len = 12 }, // 7: Attack
    .{ .start = (3 * 35) + 12, .len = 12 }, // 8: Hit
    .{ .start = (4 * 35) + 12, .len = 12 }, // 9: Death
    .{ .start = (5 * 35) + 12, .len = 12 },

    // --- Flying Eyeball (Top-Right) ---
    .{ .start = (0 * 35) + 24, .len = 11 }, // 10: Idle
    .{ .start = (1 * 35) + 24, .len = 11 }, // 11: Move
    .{ .start = (2 * 35) + 24, .len = 11 }, // 12: Attack
    .{ .start = (3 * 35) + 24, .len = 11 }, // 13: Hit
    .{ .start = (4 * 35) + 24, .len = 11 }, // 14: Death
    .{ .start = (5 * 35) + 24, .len = 11 },

    // --- Blue Bat (Mid-Left) ---
    .{ .start = (5 * 35) + 0, .len = 12 }, // 15: Idle
    .{ .start = (6 * 35) + 0, .len = 12 }, // 16: Move
    .{ .start = (7 * 35) + 0, .len = 12 }, // 17: Attack
    .{ .start = (8 * 35) + 0, .len = 12 }, // 18: Hit
    .{ .start = (9 * 35) + 0, .len = 12 }, // 19: Death
    .{ .start = (10 * 35) + 0, .len = 12 },

    // --- Chest Mimic (Mid-Middle) ---
    .{ .start = (5 * 35) + 12, .len = 12 }, // 20: Idle (Closed)
    .{ .start = (6 * 35) + 12, .len = 12 }, // 21: Open / Move
    .{ .start = (7 * 35) + 12, .len = 12 }, // 22: Bite Attack
    .{ .start = (8 * 35) + 12, .len = 12 }, // 23: Hit
    .{ .start = (9 * 35) + 12, .len = 12 }, // 24: Death
    .{ .start = (10 * 35) + 12, .len = 12 },
    .{ .start = (11 * 35) + 12, .len = 12 },
    .{ .start = (12 * 35) + 12, .len = 12 },

    // --- Vampire / Cultist (Mid-Right) ---
    .{ .start = (5 * 35) + 24, .len = 11 }, // 25: Idle
    .{ .start = (6 * 35) + 24, .len = 11 }, // 26: Move
    .{ .start = (7 * 35) + 24, .len = 11 }, // 27: Whip Attack
    .{ .start = (8 * 35) + 24, .len = 11 }, // 28: Hit
    .{ .start = (9 * 35) + 24, .len = 11 }, // 29: Death
    .{ .start = (10 * 35) + 24, .len = 11 },

    // --- Green Slime (Bottom-Left) ---
    .{ .start = (10 * 35) + 0, .len = 12 }, // 30: Idle
    .{ .start = (11 * 35) + 0, .len = 12 }, // 31: Move
    .{ .start = (12 * 35) + 0, .len = 12 }, // 32: Attack
    .{ .start = (13 * 35) + 0, .len = 12 }, // 33: Hit
    .{ .start = (14 * 35) + 0, .len = 12 }, // 34: Death
    .{ .start = (15 * 35) + 0, .len = 12 },

    // --- Lizard Warrior (Bottom-Middle) ---
    .{ .start = (13 * 35) + 12, .len = 12 }, // 35: Idle
    .{ .start = (14 * 35) + 12, .len = 12 }, // 36: Run
    .{ .start = (15 * 35) + 12, .len = 12 }, // 37: Attack 1
    .{ .start = (16 * 35) + 12, .len = 12 }, // 38: Attack 2
    .{ .start = (17 * 35) + 12, .len = 12 }, // 39: Hit
    .{ .start = (18 * 35) + 12, .len = 12 }, // 40: Death

    // --- Tiny Maggot / Slime (Lowest-Left) ---
    .{ .start = (15 * 35) + 0, .len = 12 }, // 42: Idle
    .{ .start = (16 * 35) + 0, .len = 12 }, // 43: Move
    .{ .start = (17 * 35) + 0, .len = 12 }, // 44: Attack
    .{ .start = (18 * 35) + 0, .len = 12 }, // 45: Hit
    .{ .start = (19 * 35) + 0, .len = 12 }, // 46: Death

    // --- Projectiles / VFX (Bottom-Right, Next to Slime) ---
    .{ .start = (12 * 35) + 24, .len = 12 }, // 47: Projectile 1 (Blue)
    .{ .start = (13 * 35) + 24, .len = 12 }, // 48: Projectile 2 (Sparkles)
};
