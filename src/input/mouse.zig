const std = @import("std");
const pxl = @import("../pxl.zig");

const MouseButtons = @import("pressable_input.zig").MouseButtons;

pub const MouseButton = enum(u8) {
    left = 0,
    middle = 1,
    right = 2,

    pub const max = MouseButton.right;
};

// state
pub var buttons: MouseButtons = .{};
pub var wheel_x: f32 = 0;
pub var wheel_y: f32 = 0;
pub var pos: pxl.math.Vec2 = .{};
pub var mouse_rel_x: f32 = 0;
pub var mouse_rel_y: f32 = 0;

pub fn newFrame() void {
    buttons.clear();
}

pub fn justPressed(btn: MouseButton) bool {
    return buttons.justPressed(btn);
}

pub fn pressed(btn: MouseButton) bool {
    return buttons.pressed(btn);
}

pub fn justReleased(btn: MouseButton) bool {
    return buttons.justReleased(btn);
}
