const std = @import("std");

const pxl = @import("pxl");
const api = pxl.api;

const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const BMFont = pxl.text.BMFont;
const TextLayoutIterator = pxl.text.TextLayoutIterator;

var font: pxl.text.BMFont = undefined;
var kiwi_font: pxl.text.BMFont = undefined;

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        .update = update,
        .render = render,
        .shutdown = shutdown,
    });
}

fn setup() !void {
    font = try BMFont.init("examples/assets/minecraftia.fnt");
    kiwi_font = try BMFont.init("examples/assets/kiwisoda.fnt");
}

fn shutdown() !void {
    font.deinit();
    kiwi_font.deinit();
}

fn update() !void {}

fn render() !void {
    pxl.beginPass(.{ .clear_color = pxl.math.Color.aya });

    var pos = Vec2.zero;
    var i: usize = 1;
    while (i < font.chars_count) : (i += 1) {
        const glyph = font.getChar(i);

        api.drawTexturedRect(
            font.texture,
            .{ .x = pos.x, .y = pos.y, .w = glyph.width, .h = glyph.height },
            .{ .x = glyph.x, .y = glyph.y, .w = glyph.width, .h = glyph.height },
            Color.white,
        );

        pos.x += glyph.xadvance;
        pos.y += glyph.yoffset;
    }

    const text_pos = Vec2.init(pxl.sapp.widthf() * 0.5 - 100, pxl.sapp.heightf() * 0.5 - 100);
    font.drawString("fucking a-right ass\nmother FOOKER____!!!!!!@#$%^&*():;,./?{}", text_pos, Color.white);
    const bounds = font.measureString("fucking a-right ass\nmother FOOKER____!!!!!!@#$%^&*():;,./?{}");
    api.drawRectOutline(text_pos, bounds, 1, pxl.math.Color.green);

    font.drawString("well shit, let's see if ThIS wORkZ?", .{ .x = 10, .y = 100 + bounds.y }, Color.white);

    kiwi_font.drawString("tHIz foOnT loOkz WacKy!", .{ .x = 10, .y = 150 }, Color.white);

    pxl.endPass();
}
