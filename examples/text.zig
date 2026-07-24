const std = @import("std");

const pxl = @import("pxl");

const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const BMFontParser = pxl.text.BMFontParser;
const TextLayoutIterator = pxl.text.TextLayoutIterator;

var font: pxl.text.BMFontParser = undefined;
var kiwi_font: pxl.text.BMFontParser = undefined;

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        .update = update,
        .render = render,
        .shutdown = shutdown,
    });
}

fn setup() !void {
    font = try BMFontParser.init("examples/assets/minecraftia.fnt");
    kiwi_font = try BMFontParser.init("examples/assets/kiwisoda.fnt");
}

fn shutdown() !void {
    font.deinit();
    kiwi_font.deinit();
}

fn update() !void {}

fn render() !void {
    pxl.beginPass(.{ .action = .clear });

    var pos = Vec2.zero;
    var i: usize = 1;
    while (i < font.chars_count) : (i += 1) {
        const glyph = font.getChar(i);

        pxl.batcher.drawTexturedRect(
            font.texture,
            .{ .x = pos.x, .y = pos.y, .w = glyph.width, .h = glyph.height },
            .{ .x = glyph.x, .y = glyph.y, .w = glyph.width, .h = glyph.height },
            Color.white,
        );
        // sgp.draw_textured_rect(
        //     0,
        //     .{ .x = pos.x, .y = pos.y, .w = glyph.width, .h = glyph.height },
        //     .{ .x = glyph.x, .y = glyph.y, .w = glyph.width, .h = glyph.height },
        // );

        pos.x += glyph.xadvance;
        pos.y += glyph.yoffset;
    }

    font.drawString(
        "fucking a-right ass\nmother FOOKER____!!!!!!@#$%^&*():;,./?{}",
        .{
            .x = pxl.sapp.widthf() * 0.5 - 100,
            .y = pxl.sapp.heightf() * 0.5 - 100,
        },
    );
    const bounds = font.measureString("fucking a-right ass\nmother FOOKER____!!!!!!@#$%^&*():;,./?{}");

    // sgp.set_color(1, 0.6, 0.2, 1);
    font.drawString("well shit, let's see if ThIS wORkZ?", .{ .x = 10, .y = 100 + bounds.y });

    kiwi_font.drawString("tHIz foOnT loOkz WacKy!", .{ .x = 10, .y = 150 });

    pxl.endPass();
}
