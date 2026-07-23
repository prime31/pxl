const std = @import("std");

const pxl = @import("pxl");
const sgp = pxl.sgp;
const ig = pxl.ig;

const Vec2 = pxl.math.Vec2;
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
    sgp.reset_project();
    sgp.setBlendMode(.blend);
    sgp.set_image(0, font.texture.img);

    var pos = Vec2.zero;
    var i: usize = 1;
    while (i < font.chars_count) : (i += 1) {
        const glyph = font.getChar(i);

        sgp.draw_textured_rect(
            0,
            .{ .x = pos.x, .y = pos.y, .w = glyph.width, .h = glyph.height },
            .{ .x = glyph.x, .y = glyph.y, .w = glyph.width, .h = glyph.height },
        );

        pos.x += glyph.xadvance;
        pos.y += glyph.yoffset;
    }

    shit(2.5);
    sgp.translate(pxl.sapp.widthf() * 0.5 - 100, pxl.sapp.heightf() * 0.5 - 100);
    sgp.set_color(0, 0, 0, 1);
    font.drawString("fucking a-right ass\nmother FOOKER____!!!!!!@#$%^&*():;,./?{}", .{ .x = 10, .y = 100 });
    const bounds = font.measureString("fucking a-right ass\nmother FOOKER____!!!!!!@#$%^&*():;,./?{}");

    sgp.set_color(1, 0.6, 0.2, 1);
    font.drawString("well shit, let's see if ThIS wORkZ?", .{ .x = 10, .y = 100 + bounds.y });

    sgp.reset_color();
    sgp.set_image(0, kiwi_font.texture.img);
    kiwi_font.drawString("tHIz foOnT loOkz WacKy!", .{ .x = 10, .y = 150 });

    sgp.reset_image(0);
    sgp.reset_project();
    pxl.api.drawFilledCircle(25, 25, 35, 10);

    pxl.endPass();
}

fn shit(zoom: f32) void {
    const w = pxl.sapp.widthf();
    const h = pxl.sapp.heightf();

    const cx = w * 0.5;
    const cy = h * 0.5;
    const half_w = w * 0.5 / zoom;
    const half_h = h * 0.5 / zoom;

    sgp.project(cx - half_w, cx + half_w, cy - half_h, cy + half_h);
}
