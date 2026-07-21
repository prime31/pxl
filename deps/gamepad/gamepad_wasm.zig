const std = @import("std");

pub const DigitalInputs = packed struct(u16) {
    dpad_up: bool = false,
    dpad_down: bool = false,
    dpad_left: bool = false,
    dpad_right: bool = false,
    start: bool = false,
    back: bool = false,
    a: bool = false,
    b: bool = false,
    x: bool = false,
    y: bool = false,
    left_thumb: bool = false,
    right_thumb: bool = false,
    _padding: u4 = 0, // padding to align to 16 bits
};

pub const AnalogStickState = extern struct {
    normalized_x: f32 = @import("std").mem.zeroes(f32),
    normalized_y: f32 = @import("std").mem.zeroes(f32),
    direction_x: f32 = @import("std").mem.zeroes(f32),
    direction_y: f32 = @import("std").mem.zeroes(f32),
    magnitude: f32 = @import("std").mem.zeroes(f32),
};

pub const GamepadState = extern struct {
    digital_inputs: DigitalInputs = @import("std").mem.zeroes(DigitalInputs),
    left_stick: AnalogStickState = @import("std").mem.zeroes(AnalogStickState),
    right_stick: AnalogStickState = @import("std").mem.zeroes(AnalogStickState),
    left_shoulder: f32 = @import("std").mem.zeroes(f32),
    right_shoulder: f32 = @import("std").mem.zeroes(f32),
    left_trigger: f32 = @import("std").mem.zeroes(f32),
    right_trigger: f32 = @import("std").mem.zeroes(f32),
    connected: bool = @import("std").mem.zeroes(bool),
};

// public API
pub fn getMaxSupportedGamepads() c_uint {
    return 0;
}

pub fn recordState() void {}

pub fn getGamepadState(_: c_uint, _: *GamepadState) bool {
    return false;
}

pub fn isConnected(_: c_uint) bool {
    return false;
}
