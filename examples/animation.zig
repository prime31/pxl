const std = @import("std");

const pxl = @import("pxl");
const api = pxl.api;
const cast = pxl.util.cast;

const Vec = pxl.util.Vec;
const Vec2 = pxl.math.Vec2;
const Rect = pxl.math.Rect;
const RectU = pxl.math.RectU;
const Color = pxl.math.Color;
const Texture = pxl.gpu.Texture;

const cell_size = 34;
var sprites_tex: Texture = undefined;
var tiles_tex: Texture = undefined;
var parsed_sprites: []Sprite = undefined;

var sprite_animations: SpriteAnimations = .{};
var animator: AnimationPlayer = .{};

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        .update = update,
        .render = render,
        .shutdown = shutdown,
    });
}

fn setup() !void {
    sprites_tex = try Texture.initFromFile("examples/assets/sprites.png");
    tiles_tex = try Texture.initFromFile("examples/assets/blacknwhite.png");

    parsed_sprites = generateSprites(sprites_tex, cell_size, cell_size, 0, 0, 0, 1000);
    const parsed_tiles = generateSprites(tiles_tex, 12, 12, 1, 1, 21, 4);
    sprite_animations.sprites.appendSlice(parsed_tiles);
    pxl.mem.free(parsed_tiles);

    sprite_animations.animations.append(.{ .start = 0, .len = 4, .next = @enumFromInt(0) });

    animator.play(@enumFromInt(0));
}

fn shutdown() !void {
    sprites_tex.deinit();
    tiles_tex.deinit();
    pxl.mem.free(parsed_sprites);
    sprite_animations.animations.deinit();
    sprite_animations.sprites.deinit();
}

fn update() !void {}

fn render() !void {
    pxl.beginPass(.{ .clear_color = Color.fromBytes(11, 15, 22, 255) });

    const text_pos = Vec2.init(pxl.sapp.widthf() * 0.5 - 100, pxl.sapp.heightf() * 0.5 - 100);
    api.drawText(null, text_pos, "fucking a-right ass\nmother FOOKER", Color.white);

    var pos = Vec2.one;
    for (animations) |anim| {
        const elapsed: usize = @intFromFloat(@floor(pxl.time.time() / 0.1));
        const frame: usize = elapsed % anim.len;

        const sprite = parsed_sprites[anim.start + frame];
        api.drawTexturedRect(sprite.tex, .{
            .x = pos.x,
            .y = pos.y,
            .w = @floatFromInt(sprite.uvs.w),
            .h = @floatFromInt(sprite.uvs.h),
        }, sprite.uvs.asRect(), Color.white);

        pos.x += cell_size;
        if (pos.x > pxl.sapp.widthf()) {
            pos.x = 1;
            pos.y += cell_size;
        }
    }

    pos.x = 1;
    pos.y += 100;
    animator.update();
    const spr = animator.getSprite();
    api.drawTexturedRect(spr.tex, .{
        .x = pos.x + 50,
        .y = pos.y,
        .w = @floatFromInt(spr.uvs.w * 5),
        .h = @floatFromInt(spr.uvs.h * 5),
    }, spr.uvs.asRect(), Color.white);

    pxl.endPass();
}

const animations = [_]Animation{
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
    .{ .start = (10 * 35) + 12, .len = 12 }, //
    .{ .start = (11 * 35) + 12, .len = 12 }, //
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

pub const SpriteAnimations = struct {
    sprites: Vec(Sprite) = .empty,
    animations: Vec(Animation) = .empty,
};

const Sprite = struct {
    tex: Texture,
    uvs: RectU,
    frame_time: f32 = 0.1,
};

pub const Animation = struct {
    /// Index into sprites array
    start: u32,
    /// Number of Sprite elements used in this animation.
    len: u32,
    /// After finishing, will jump to this next animation (which may be itself, in which case it will loop).
    next: Index = .none,

    /// Index into animations array.
    pub const Index = enum(u32) {
        none = std.math.maxInt(u32),
        _,
    };
};

pub const AnimationState = enum(u8) { none, running, paused, completed };

pub const AnimationPlayer = struct {
    animation: Animation.Index = .none,
    state: AnimationState = .none,
    current_frame: usize = 0,
    elapsed_time: f32 = 0,
    frame_time_left: f32 = 0,

    pub fn play(self: *AnimationPlayer, anim: Animation.Index) void {
        self.animation = anim;
        self.elapsed_time = 0;
        self.setFrame(0);
        self.state = .running;
    }

    pub fn getSprite(self: AnimationPlayer) Sprite {
        const anim = sprite_animations.animations.items[@intFromEnum(self.animation)];
        return sprite_animations.sprites.items[anim.start + self.current_frame];
    }

    pub fn update(self: *AnimationPlayer) void {
        if (self.state != .running) return;

        self.elapsed_time += pxl.time.dt();
        self.frame_time_left -= pxl.time.dt();

        if (self.frame_time_left <= 0) {
            const anim = sprite_animations.animations.items[@intFromEnum(self.animation)];
            const new_frame = self.current_frame + 1;
            if (new_frame >= anim.len) {
                if (anim.next != .none) {
                    self.animation = anim.next;
                    self.setFrame(0);
                } else self.state = .completed;
            } else {
                self.setFrame(new_frame);
            }
        }
    }

    fn setFrame(self: *AnimationPlayer, index: usize) void {
        self.current_frame = index;
        self.frame_time_left = sprite_animations.sprites.items[self.current_frame].frame_time;
    }
};

pub fn generateSprites(
    texture: Texture,
    cell_width: u32,
    cell_height: u32,
    padding: u32,
    margin: u32,
    cell_offset: u32,
    max_cells_to_include: u32,
) []Sprite {
    var sprites = std.ArrayListUnmanaged(Sprite).empty;

    // Cast the texture dimensions to u32 immediately to ensure all math matches
    const tex_w: u32 = @intCast(texture.width);
    const tex_h: u32 = @intCast(texture.height);

    if (tex_w <= margin * 2 or tex_h <= margin * 2) {
        return sprites.toOwnedSlice(pxl.mem.allocator) catch unreachable;
    }

    const avail_w = tex_w - (margin * 2);
    const avail_h = tex_h - (margin * 2);

    const cols = (avail_w + padding) / (cell_width + padding);
    const rows = (avail_h + padding) / (cell_height + padding);

    var current_cell: u32 = 0;
    var included_count: u32 = 0;

    var r: u32 = 0;
    while (r < rows) : (r += 1) {
        var c: u32 = 0;
        while (c < cols) : (c += 1) {
            if (current_cell >= cell_offset) {
                if (included_count >= max_cells_to_include) {
                    return sprites.toOwnedSlice(pxl.mem.allocator) catch unreachable;
                }

                const x = margin + c * (cell_width + padding);
                const y = margin + r * (cell_height + padding);

                // Ensure we don't overflow texture bounds
                if (x + cell_width <= tex_w and y + cell_height <= tex_h) {
                    sprites.append(pxl.mem.allocator, .{
                        .tex = texture,
                        .uvs = .{
                            .x = x,
                            .y = y,
                            .w = cell_width,
                            .h = cell_height,
                        },
                    }) catch unreachable;
                    included_count += 1;
                }
            }
            current_cell += 1;
        }
    }

    return sprites.toOwnedSlice(pxl.mem.allocator) catch unreachable;
}
