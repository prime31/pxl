const std = @import("std");

const pxl = @import("pxl");
const api = pxl.api;
const mu = pxl.mu;
const pad = pxl.gamepad;

const Color = pxl.math.Color;

pub fn update() !void {
    pad.recordState();

    var state: pad.GamepadState = undefined;
    const has_state = pad.getGamepadState(0, &state);
    _ = has_state;

    if (mu.beginWindowEx("Poop Window", .{ .x = 200, .y = 50, .w = 200, .h = 250 }, .{ .no_close = true, .align_center = false })) {
        mu.endWindow();
    }
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = pxl.math.Color.aya });
    api.drawText(null, .init(10, 10), "here we go dude", Color.black);
    pxl.endPass();
}
