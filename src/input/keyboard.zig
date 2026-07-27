const std = @import("std");
const pxl = @import("../pxl.zig");

pub const Keycode = @import("keycode.zig").Keycode;
const Keys = @import("pressable_input.zig").Keys;

pub var keys: Keys = .{};

pub fn newFrame() void {
    keys.clear();
}

pub fn justPressed(btn: Keycode) bool {
    return keys.justPressed(btn);
}

pub fn pressed(btn: Keycode) bool {
    return keys.pressed(btn);
}

pub fn justReleased(btn: Keycode) bool {
    return keys.justReleased(btn);
}

// groups
pub fn anyPressed(input: []const Keycode) bool {
    return keys.anyPressed(input);
}

pub fn anyJustPressed(input: []const Keycode) bool {
    return keys.anyJustPressed(input);
}

pub fn anyJustReleased(input: []const Keycode) bool {
    return keys.anyJustReleased(input);
}

// iterators
pub fn nextPressed() ?Keycode {
    return keys.getNextPressed();
}

pub fn nextJustPressed() ?Keycode {
    return keys.getNextJustPressed();
}

pub fn nextJustReleased() ?Keycode {
    return keys.getNextJustReleased();
}
