const std = @import("std");

const pxl = @import("pxl");
const mu = pxl.mu;

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .update = update,
        .render = render,
    });
}

fn update() !void {
    if (mu.beginWindowEx("Poop Window", .{ .x = 200, .y = 50, .w = 200, .h = 250 }, .{ .no_close = true, .align_center = false })) {
        mu.text("wtf man, text");

        if (mu.headerEx("Header", .{ .expanded = true })) {
            mu.layoutRow(2, &[_]c_int{ 75, -1 }, 0);
            mu.label("label here");
            mu.label("value");

            mu.label("fucking wtf");
            mu.label("shit");
        }

        if (mu.button("Click Me", .none)) std.debug.print("clicked\n", .{});
        const c = struct {
            var checked: bool = false;
            var buffer: [256]u8 = undefined;
            var buffer2: [128]u8 = undefined;
            var floaty: f32 = 6;
        };
        _ = mu.checkbox("Checked", &c.checked);
        _ = mu.textbox(&c.buffer, c.buffer.len);

        mu.layoutRow(3, &[_]c_int{ 30, -90, -1 }, 0);
        _ = mu.button("X", .none);
        _ = mu.textbox(&c.buffer2, c.buffer2.len);
        _ = mu.button("Submit", .none);

        mu.layoutRow(0, &[_]c_int{}, 0);
        _ = mu.slider(&c.floaty, 0, 50, 1);

        if (mu.button("Open Popup", .none))
            mu.openPopup("Popup");

        if (mu.beginPopup("Popup")) {
            _ = mu.button("Fook", .none);
            _ = mu.button("You", .none);
            mu.endPopup();
        }

        if (mu.beginTreenodeEx("The Tree", .{})) {
            _ = mu.button("In Tree", .none);
            mu.endTreenode();
        }

        mu.layoutRow(1, &[_]c_int{-1}, -1);
        mu.beginPanelEx("My Panel", .{ .align_center = false });
        mu.label("label here dude what the fuck");
        mu.label("label also here dudette");
        mu.endPanel();

        mu.endWindow();
    }
}

fn render() !void {
    pxl.beginPass(.{ .clear_color = pxl.math.Color.aya });
    pxl.endPass();
}
