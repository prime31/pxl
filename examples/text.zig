const std = @import("std");

const pxl = @import("pxl");
const api = pxl.api;

const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const BMFont = pxl.text.BMFont;
const TextLayoutIterator = pxl.text.TextLayoutIterator;

var kiwi_font: *pxl.text.BMFont = undefined;

pub fn setup() !void {
    kiwi_font = try pxl.assets.loadFont(.kiwisoda);
}

pub fn shutdown() !void {
    pxl.assets.destroy(kiwi_font);
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = pxl.math.Color.aya });

    var pos = Vec2.zero;
    var i: usize = 1;
    while (i < kiwi_font.chars_count) : (i += 1) {
        const glyph = kiwi_font.getChar(i);

        api.drawTexturedRect(
            kiwi_font.texture,
            .{ .x = pos.x, .y = pos.y, .w = glyph.width, .h = glyph.height },
            .{ .x = glyph.x, .y = glyph.y, .w = glyph.width, .h = glyph.height },
            Color.white,
        );

        pos.x += glyph.xadvance;
        pos.y += glyph.yoffset;
    }

    const text_pos = Vec2.init(pxl.sapp.widthf() * 0.5 - 100, pxl.sapp.heightf() * 0.5 - 100);
    api.drawText(null, text_pos, "fucking a-right ass\nmother FOOKER____!!!!!!@#$%^&*():;,./?{}", Color.white);
    const bounds = pxl.font.measureString("fucking a-right ass\nmother FOOKER____!!!!!!@#$%^&*():;,./?{}");
    api.drawRectOutline(text_pos, bounds, 1, pxl.math.Color.green);

    pxl.font.drawString("well shit, let's see if ThIS wORkZ?", .{ .x = 10, .y = 100 + bounds.y }, Color.white);

    kiwi_font.drawString("tHIz foOnT loOkz WacKy!", .{ .x = 10, .y = 150 }, Color.white);

    pxl.endPass();
}
