const std = @import("std");
const gamepad = @import("gamepad");

pub const GamepadState = gamepad.GamepadState;
pub const AnalogStickState = gamepad.AnalogStickState;
pub const DigitalInputs = gamepad.DigitalInputs;

// TODO: left/right_shoulder
pub const GamepadButton = enum {
    south, // Bottom face button (e.g. Xbox A button)
    east, // Right face button (e.g. Xbox B button)
    west, // Left face button (e.g. Xbox X button)
    north, // Top face button (e.g. Xbox Y button)
    dpad_up,
    dpad_down,
    dpad_left,
    dpad_right,
    start,
    back,
    left_stick,
    right_stick,
};

pub const GamepadAxis = enum {
    left_x,
    left_y,
    right_x,
    right_y,
    left_trigger,
    right_trigger,
};

var current_pad: GamepadState = .{};
var previous_pad: GamepadState = .{};

pub fn newFrame() void {
    gamepad.recordState();

    previous_pad = current_pad;
    current_pad = if (getGamepadState(0)) |state| state else .{};
}

pub fn getMaxSupportedGamepads() usize {
    return gamepad.getMaxSupportedGamepads();
}

pub fn isGamepadConnected(index: usize) bool {
    return gamepad.isConnected(index);
}

pub fn getGamepadState(index: usize) ?GamepadState {
    var state: gamepad.GamepadState = undefined;
    if (gamepad.getGamepadState(@intCast(index), &state)) return state;
    return null;
}

pub fn isButtonDown(btn: GamepadButton) bool {
    return getDigital(current_pad.digital_inputs, btn);
}

pub fn isButtonJustPressed(btn: GamepadButton) bool {
    return getDigital(current_pad.digital_inputs, btn) and !getDigital(previous_pad.digital_inputs, btn);
}

pub fn isButtonJustReleased(btn: GamepadButton) bool {
    return !getDigital(current_pad.digital_inputs, btn) and
        getDigital(previous_pad.digital_inputs, btn);
}

pub fn getAxis(axis: GamepadAxis) f32 {
    return std.math.clamp(getAxisUnclamped(axis), -1, 1);
}

pub fn getAxisUnclamped(axis: GamepadAxis) f32 {
    if (!current_pad.connected) return 0;

    return switch (axis) {
        .left_x => current_pad.left_stick.direction_x,
        .right_x => current_pad.right_stick.direction_x,
        .left_y => current_pad.left_stick.direction_y,
        .right_y => current_pad.right_stick.direction_y,
        .left_trigger => current_pad.left_trigger,
        .right_trigger => current_pad.right_trigger,
    };
}

fn getDigital(digital: DigitalInputs, btn: GamepadButton) bool {
    return switch (btn) {
        .south => digital.a,
        .east => digital.b,
        .west => digital.x,
        .north => digital.y,
        .dpad_up => digital.dpad_up,
        .dpad_down => digital.dpad_down,
        .dpad_left => digital.dpad_left,
        .dpad_right => digital.dpad_right,
        .start => digital.start,
        .back => digital.back,
        .left_stick => digital.left_thumb,
        .right_stick => digital.right_thumb,
    };
}
