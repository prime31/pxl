const std = @import("std");
const builtin = @import("builtin");
const pxl = @import("../pxl.zig");
const sapp = pxl.sapp;
const math = pxl.math;

const gamepad = @import("gamepad.zig");
const kb = @import("keyboard.zig");
const mouse = @import("mouse.zig");

const InputMapper = @import("input_mapper.zig").InputMapper;
const InputBinding = @import("input_mapper.zig").InputBinding;
const AxisDiagonal = @import("input_mapper.zig").AxisDiagonal;

pub const GamepadButton = gamepad.GamepadButton;
pub const GamepadAxis = gamepad.GamepadAxis;
pub const GamepadState = gamepad.GamepadState;
pub const AnalogStickState = gamepad.AnalogStickState;
pub const DigitalInputs = gamepad.DigitalInputs;

pub const MouseButton = mouse.MouseButton;
pub const Keycode = @import("keycode.zig").Keycode;

var map: InputMapper = undefined;

pub fn init() void {
    map = .init();
}

pub fn deinit() void {
    map.deinit();
}

pub fn newFrame() void {
    mouse.newFrame();
    kb.newFrame();
    gamepad.newFrame();
}

pub fn handleEvent(evt: *const sapp.Event) void {
    switch (evt.type) {
        .KEY_DOWN, .KEY_UP => {
            // sokol forwards OS key-repeat as KEY_DOWN with key_repeat=true; ignoring them
            // keeps isActionJustPressed a true edge trigger (a held key must not re-fire).
            if (evt.type == .KEY_DOWN and evt.key_repeat) return;
            const scancode = @intFromEnum(evt.key_code);
            if (evt.type == .KEY_UP) {
                kb.keys.release(@enumFromInt(scancode));
            } else {
                kb.keys.press(@enumFromInt(scancode));
            }
        },
        .MOUSE_DOWN, .MOUSE_UP => {
            const button = @intFromEnum(evt.mouse_button);
            if (evt.type == .MOUSE_UP) {
                mouse.buttons.release(@enumFromInt(button));
            } else {
                mouse.buttons.press(@enumFromInt(button));
            }
        },
        .MOUSE_MOVE => {
            // TODO: why does sokol send two mouse events with the same data???
            // if (mouse_x == evt.mouse_x and mouse_y == evt.mouse_y) return;

            mouse.mouse_rel_x = evt.mouse_x - mouse.pos.x;
            mouse.mouse_rel_y = mouse.pos.y - evt.mouse_y;
            mouse.pos = .init(evt.mouse_x, evt.mouse_y);
        },
        .MOUSE_SCROLL => {
            mouse.wheel_x = evt.scroll_x;
            mouse.wheel_y = evt.scroll_y;
        },
        .TOUCHES_BEGAN, .TOUCHES_MOVED, .TOUCHES_ENDED, .TOUCHES_CANCELLED => {
            // On touch devices (Android/iOS/etc.) there's no physical mouse, so we
            // emulate one from the first touch: it moves the mouse cursor and acts
            // as the left button. This is hidden inside the input wrapper, so game
            // code just uses the normal mouse API.
            if (builtin.target.abi.isAndroid()) {
                const t = &evt.touches[0];

                mouse.mouse_rel_x = t.pos_x - mouse.pos.x;
                mouse.mouse_rel_y = mouse.pos.y - t.pos_y;
                mouse.pos = .init(t.pos_x, t.pos_y);

                switch (evt.type) {
                    .TOUCHES_BEGAN => mouse.buttons.press(.left),
                    .TOUCHES_ENDED, .TOUCHES_CANCELLED => mouse.buttons.release(.left),
                    else => {},
                }
            }
        },
        else => {},
    }
}

// keyboard
/// only true if down this frame and not down the previous frame
pub fn keyPressed(keycode: Keycode) bool {
    return kb.justPressed(keycode);
}

/// true the entire time the key is down
pub fn keyDown(keycode: Keycode) bool {
    return kb.pressed(keycode);
}

/// true only the frame the key is released
pub fn keyUp(keycode: Keycode) bool {
    return kb.justReleased(keycode);
}

pub fn anyKeyPressed(keycodes: []const Keycode) bool {
    return kb.anyJustPressed(keycodes);
}
pub fn anyKeyDown(keycodes: []const Keycode) bool {
    return kb.anyPressed(keycodes);
}
pub fn anyKeyReleased(keycodes: []const Keycode) bool {
    return kb.anyJustReleased(keycodes);
}

pub fn getNextKeyDown() ?Keycode {
    return kb.getNextPressed();
}
pub fn getNextKeyJustPressed() ?Keycode {
    return kb.getNextJustPressed();
}
pub fn getNextKeyReleased() ?Keycode {
    return kb.getNextJustReleased();
}

// mouse
/// only true if down this frame and not down the previous frame
pub fn mousePressed(button: MouseButton) bool {
    return mouse.justPressed(button);
}

/// true the entire time the button is down
pub fn mouseDown(button: MouseButton) bool {
    return mouse.pressed(button);
}

/// true only the frame the button is released
pub fn mouseUp(button: MouseButton) bool {
    return mouse.justReleased(button);
}

pub fn mouseWheel() i32 {
    return mouse.wheel_y;
}

pub fn mousePos() math.Vec2 {
    return mouse.pos;
}

/// Gets the scaled mouse position in design/render-target coordinates, taking into account
/// the currently active ResolutionPolicy scale and letterbox offset.
fn mousePosScaledInternal(x: *f32, y: *f32) void {
    const scaler = pxl.gpu.gfx_config.resolution_policy.getScaler(pxl.gpu.gfx_config.design_width, pxl.gpu.gfx_config.design_height);
    const scale_val = if (scaler.scale == 0) 1.0 else scaler.scale;
    x.* = (mouse.pos.x - @as(f32, @floatFromInt(scaler.x))) / scale_val;
    y.* = (mouse.pos.y - @as(f32, @floatFromInt(scaler.y))) / scale_val;
}

pub fn mousePosScaled() math.Vec2 {
    var x: f32 = 0;
    var y: f32 = 0;
    mousePosScaledInternal(&x, &y);
    return .{ .x = x, .y = y };
}

pub fn mouseRelMotion() math.Vec2 {
    return .{ .x = mouse.mouse_rel_x, .y = mouse.mouse_rel_y };
}

// Gamepads
pub fn getMaxSupportedGamepads() usize {
    return gamepad.getMaxSupportedGamepads();
}

pub fn isGamepadConnected(index: usize) bool {
    return gamepad.isConnected(index);
}

pub fn getGamepadState(index: usize) ?GamepadState {
    return gamepad.getGamepadState(index);
}

pub fn isButtonDown(btn: GamepadButton) bool {
    return gamepad.isButtonDown(btn);
}

pub fn isButtonJustPressed(btn: GamepadButton) bool {
    return gamepad.isButtonJustPressed(btn);
}

pub fn isButtonJustReleased(btn: GamepadButton) bool {
    return gamepad.isButtonJustReleased(btn);
}

pub fn getAxis(axis: GamepadAxis) f32 {
    return gamepad.getAxis(axis);
}

pub fn getAxisUnclamped(axis: GamepadAxis) f32 {
    return gamepad.getAxis(axis);
}

// Input Actions
pub fn addBinding(action_name: []const u8, binding: InputBinding) void {
    map.addBinding(action_name, binding);
}

/// Checks if action is currently active (Godot's is_action_pressed)
pub fn isActionPressed(action_name: []const u8) bool {
    return map.isActionPressed(action_name);
}

/// Checks frame 0 press (Godot's is_action_just_pressed)
pub fn isActionJustPressed(action_name: []const u8) bool {
    return map.isActionJustPressed(action_name);
}

/// Checks frame 0 release
pub fn isActionJustReleased(action_name: []const u8) bool {
    return map.isActionJustReleased(action_name);
}

/// Gets a 1D float value (-1.0 to 1.0) for things like triggers or paired keys
pub fn getActionAxis1D(action_name: []const u8) f32 {
    return map.getActionAxis1D(action_name);
}

/// Composite 2D Vector Helper (Godot's get_vector)
pub fn getVector(
    neg_x_action: []const u8,
    pos_x_action: []const u8,
    neg_y_action: []const u8,
    pos_y_action: []const u8,
    diagonal: AxisDiagonal,
) pxl.math.Vec2 {
    return map.getVector(neg_x_action, pos_x_action, neg_y_action, pos_y_action, diagonal);
}
