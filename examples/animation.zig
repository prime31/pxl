const std = @import("std");

const pxl = @import("pxl");
const api = pxl.api;

const Vec = pxl.util.Vec;
const Vec2 = pxl.math.Vec2;
const Rect = pxl.math.Rect;
const Color = pxl.math.Color;
const Texture = pxl.gpu.Texture;

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        .update = update,
        .render = render,
        .shutdown = shutdown,
    });
}

fn setup() !void {}

fn shutdown() !void {}

fn update() !void {}

fn render() !void {
    pxl.beginPass(.{ .clear_color = pxl.math.Color.aya });

    const text_pos = Vec2.init(pxl.sapp.widthf() * 0.5 - 100, pxl.sapp.heightf() * 0.5 - 100);
    api.drawText(null, text_pos, "fucking a-right ass\nmother FOOKER", Color.white);

    pxl.endPass();
}

const Sprite = struct {
    tex: Texture,
    uvs: Rect,
};

fn spritesFromAtlas(texture: Texture, cell_width: u32, cell_height: u32, cell_offset: u32, max_cells_to_include: u32) Vec(Sprite) {
    var sprites = Vec(Sprite).empty;

    const cols = texture.width / cell_width;
    const rows = texture.height / cell_height;
    var i: u32 = 0;

    for (0..rows) |y| {
        for (0..cols) |x| {
            i += 1;
            if (i < cell_offset) continue;

            sprites.append(.{
                .tex = texture,
                .uvs = .{
                    .x = x * cell_width,
                    .y = y * cell_height,
                    .w = cell_width,
                    .h = cell_height,
                },
            });

            if (sprites.items.len == max_cells_to_include)
                return sprites;
        }
    }

    return sprites;
}
