const std = @import("std");

const pxl = @import("pxl");
const microui = pxl.microui;
const sgp = pxl.sgp;

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .update = update,
        .render = render,
        .shutdown = shutdown,
    });
}

fn shutdown() !void {}

fn update() !void {
    if (microui.beginWindowEx("Poop Window", .{ .x = 200, .y = 50, .w = 200, .h = 250 }, 0)) {
        microui.text("wtf man, text");

        if (microui.headerEx("Header", 0)) {
            microui.layoutRow(2, &[_]c_int{ 75, -1 }, 0);
            microui.label("label here");
            microui.label("value");

            microui.label("fucking wtf");
            microui.label("shit");
        }

        if (microui.buttonEx("Click Me", 0, 0)) std.debug.print("clicked\n", .{});
        const c = struct {
            var checked: c_int = 0;
        };
        _ = microui.checkbox("Checked", &c.checked);

        microui.endWindow();
    }
}

fn render() !void {
    pxl.beginPass(.{ .action = .clear });
    sgp.reset_project();
    sgp.setBlendMode(.blend);
    sgp.draw_filled_rect(10, 40, 200, 100);
    pxl.endPass();

    pxl.sdtx.color3b(0, 0, 0);
    pxl.sdtx.puts("fuck man");
}
