const std = @import("std");
const builtin = @import("builtin");
const pxl = @import("../pxl.zig");
const sapp = pxl.sapp;
const math = pxl.math;

const gamepad = @import("gamepad.zig");
const kb = @import("keyboard.zig");
const mouse = @import("mouse.zig");

pub const GamepadButton = gamepad.GamepadButton;
pub const GamepadAxis = gamepad.GamepadAxis;
pub const GamepadState = gamepad.GamepadState;
pub const AnalogStickState = gamepad.AnalogStickState;
pub const DigitalInputs = gamepad.DigitalInputs;

pub const MouseButton = mouse.MouseButton;
pub const Keycode = @import("keycode.zig").Keycode;

pub fn newFrame() void {
    mouse.newFrame();
    kb.newFrame();
    gamepad.newFrame();
}

pub fn handleEvent(evt: *const sapp.Event) void {
    switch (evt.type) {
        .KEY_DOWN, .KEY_UP => {
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
pub const InputSource = union(enum) {
    keycode: Keycode,
    mouse_button: MouseButton,
    gamepad_button: GamepadButton,
    gamepad_axis: GamepadAxis,

    pub fn key(k: Keycode) InputSource {
        return .{ .keycode = k };
    }

    pub fn mouse(button: MouseButton) InputSource {
        return .{ .mouse_button = button };
    }

    pub fn gamepadButton(button: GamepadButton) InputSource {
        return .{ .gamepad_button = button };
    }

    pub fn gamepadAxis(axis: GamepadAxis) InputSource {
        return .{ .gamepad_axis = axis };
    }
};

pub const InputBinding = struct {
    source: InputSource,
    /// Multiplier (e.g., -1.0 for 'A' key, +1.0 for 'D' key, -1.0 to invert stick Y)
    scale: f32 = 1.0,
    deadzone: f32 = 0.0,
    gamepad_index: usize = 0,

    pub fn init(src: InputSource) InputBinding {
        return .{ .source = src };
    }

    pub fn key(k: Keycode) InputBinding {
        return .{ .source = .key(k) };
    }

    pub fn mouse(button: MouseButton) InputBinding {
        return .{ .source = .mouse(button) };
    }

    pub fn gamepadButton(button: GamepadButton) InputBinding {
        return .{ .source = .gamepadButton(button) };
    }

    pub fn gamepadAxis(axis: GamepadAxis) InputBinding {
        return .{ .source = .gamepadAxis(axis), .deadzone = 0.15 };
    }
};

pub const InputAction = struct {
    bindings: []const InputBinding, // FIXME: busted, we need to switch to a Vec()

    pub fn init(bindings: []const InputBinding) InputAction {
        return .{ .bindings = bindings };
    }

    /// order of bindings must be: neg_x, pos_x, neg_y, pos_y
    pub fn initVec(bindings: []const InputBinding) InputAction {
        std.debug.assert(bindings.len == 4);
        return .{ .bindings = bindings };
    }

    /// Checks if action is currently active (Godot's is_action_pressed)
    pub fn isActionPressed(self: InputAction) bool {
        for (self.bindings) |b| {
            if (evaluateBindingDown(b)) return true;
        }
        return false;
    }

    /// Checks frame 0 press (Godot's is_action_just_pressed)
    pub fn isActionJustPressed(self: *const InputAction) bool {
        for (self.bindings) |b| {
            if (evaluateBindingJustPressed(b)) return true;
        }
        return false;
    }

    /// Checks frame 0 press (Godot's is_action_just_pressed)
    pub fn isActionJustReleased(self: *const InputAction) bool {
        for (self.bindings) |b| {
            if (evaluateBindingJustReleased(b)) return true;
        }
        return false;
    }

    /// Gets a 1D float value (-1.0 to 1.0) for things like triggers or paired keys
    pub fn getActionAxis1D(self: InputAction) f32 {
        var total: f32 = 0.0;
        for (self.bindings) |b| {
            total += evaluateBindingValue(b) * b.scale;
        }
        return std.math.clamp(total, -1.0, 1.0);
    }

    // TODO: this is broken, each direction should be multiple InputBindings (.left + .gamepad_left + dpad_left)
    // currently it only allows one InputBinding which is dumb. it should send many to getActionAxis1D() for reach direction.
    /// Composite 2D Vector Helper (Godot's get_vector)
    pub fn getVector(self: InputAction, diagonal: enum { raw, normalized }) math.Vec2 {
        std.debug.assert(self.bindings.len == 4);
        var vec = math.Vec2{
            .x = evaluateBindingValue(self.bindings[1]) - evaluateBindingValue(self.bindings[0]),
            .y = evaluateBindingValue(self.bindings[3]) - evaluateBindingValue(self.bindings[2]),
        };

        if (diagonal == .raw) return vec;

        // Radial Normalization (Prevents diagonal movement boost)
        const len_sq = vec.x * vec.x + vec.y * vec.y;
        if (len_sq > 1.0) {
            const len = @sqrt(len_sq);
            vec.x /= len;
            vec.y /= len;
        }
        return vec;
    }

    fn evaluateBindingDown(b: InputBinding) bool {
        return switch (b.source) {
            .keycode => |k| keyDown(k),
            .mouse_button => |m| mouseDown(m),
            .gamepad_button => |gb| gamepad.isButtonDown(gb),
            .gamepad_axis => evaluateBindingValue(b) > b.deadzone,
        };
    }

    fn evaluateBindingJustPressed(b: InputBinding) bool {
        return switch (b.source) {
            .keycode => |k| keyPressed(k),
            .mouse_button => |m| mousePressed(m),
            .gamepad_button => |gb| gamepad.isButtonJustPressed(gb),
            .gamepad_axis => false, // Axis triggering is handled via thresholds
        };
    }

    fn evaluateBindingJustReleased(b: InputBinding) bool {
        return switch (b.source) {
            .keycode => |k| keyUp(k),
            .mouse_button => |m| mouseUp(m),
            .gamepad_button => |gb| gamepad.isButtonJustReleased(gb),
            .gamepad_axis => false, // Axis triggering is handled via thresholds
        };
    }

    fn evaluateBindingValue(b: InputBinding) f32 {
        return switch (b.source) {
            .keycode => |k| if (keyDown(k)) 1.0 else 0.0,
            .mouse_button => |m| if (mouseDown(m)) 1.0 else 0.0,
            .gamepad_button => |gb| if (gamepad.isButtonDown(gb)) 1.0 else 0.0,
            .gamepad_axis => |ga| readGamepadAxis(ga, b.deadzone),
        };
    }

    fn readGamepadAxis(axis: GamepadAxis, deadzone: f32) f32 {
        const val = gamepad.getAxis(axis);
        if (@abs(val) < deadzone) return 0.0;
        return val;
    }
};

/// can manage all InputBindings instead of having separate InputActions
/// this would make it more like Godots input system. Still needs the get* methods added
pub const InputManager = struct {
    actions: std.StringHashMap(pxl.util.Vec(InputBinding)),

    pub fn init() InputManager {
        return .{
            .actions = std.StringHashMap(pxl.util.Vec(InputBinding)).init(pxl.mem.allocator),
        };
    }

    pub fn deinit(self: *InputManager) void {
        var it = self.actions.valueIterator();
        while (it.next()) |*vec| vec.*.deinit();
        self.actions.deinit();
    }

    pub fn addBinding(self: *InputManager, action_name: []const u8, binding: InputBinding) void {
        const res = self.actions.getOrPut(action_name) catch unreachable;
        if (!res.found_existing) {
            res.value_ptr.* = pxl.util.Vec(InputBinding).empty;
        }
        res.value_ptr.append(binding);
    }

    /// Checks if action is currently active (Godot's is_action_pressed)
    pub fn isActionPressed(self: *const InputManager, action_name: []const u8) bool {
        const bindings = self.actions.get(action_name) orelse return false;
        for (bindings.items) |b| {
            if (self.evaluateBindingDown(b)) return true;
        }
        return false;
    }

    /// Checks frame 0 press (Godot's is_action_just_pressed)
    pub fn isActionJustPressed(self: *const InputManager, action_name: []const u8) bool {
        const bindings = self.actions.get(action_name) orelse return false;
        for (bindings.items) |b| {
            if (self.evaluateBindingJustPressed(b)) return true;
        }
        return false;
    }

    /// Checks frame 0 release
    pub fn isActionJustReleased(self: *const InputManager, action_name: []const u8) bool {
        const bindings = self.actions.get(action_name) orelse return false;
        for (bindings.items) |b| {
            if (self.evaluateBindingJustReleased(b)) return true;
        }
        return false;
    }

    /// Gets a 1D float value (-1.0 to 1.0) for things like triggers or paired keys
    pub fn getActionAxis1D(self: *const InputManager, action_name: []const u8) f32 {
        const bindings = self.actions.get(action_name) orelse return 0.0;
        var total: f32 = 0.0;
        for (bindings.items) |b| {
            total += evaluateBindingValue(b) * b.scale;
        }
        return std.math.clamp(total, -1.0, 1.0);
    }

    /// Composite 2D Vector Helper (Godot's get_vector)
    pub fn getVector(
        self: *const InputManager,
        neg_x_action: []const u8,
        pos_x_action: []const u8,
        neg_y_action: []const u8,
        pos_y_action: []const u8,
        diagonal: enum { raw, normalized, square, digital },
    ) pxl.math.Vec2 {
        var vec = pxl.math.Vec2{
            .x = self.getActionAxis1D(pos_x_action) - self.getActionAxis1D(neg_x_action),
            .y = self.getActionAxis1D(pos_y_action) - self.getActionAxis1D(neg_y_action),
        };

        if (diagonal == .raw) return vec;

        // --- Digital Snap Mode (Ideal for Pixel Art Platformers) ---
        if (diagonal == .digital) {
            // Any stick movement past the deadzone snaps immediately to full 1.0 / -1.0
            if (vec.x > 0.0) vec.x = 1.0 else if (vec.x < 0.0) vec.x = -1.0;
            if (vec.y > 0.0) vec.y = 1.0 else if (vec.y < 0.0) vec.y = -1.0;

            return vec;
        }

        if (diagonal == .square) {
            // Stretch the circular joystick bounds into a square box
            const abs_x = @abs(vec.x);
            const abs_y = @abs(vec.y);
            const max_axis = @max(abs_x, abs_y);

            // best for top-down, this stretches circuler stick to a square so diagonals can be 1,1
            if (max_axis > 0.0) {
                // If max_axis is 0.77 on a diagonal, this divides by 0.77, scaling both X and Y up to 1.0!
                const stretch_factor = 1.0 / max_axis;

                // We multiply by length to retain analog walking sensitivity
                const len = @sqrt(vec.x * vec.x + vec.y * vec.y);
                const applied_stretch = @min(stretch_factor * len, stretch_factor);

                vec.x *= applied_stretch;
                vec.y *= applied_stretch;
            }
            return vec;
        }

        // Radial Normalization (Prevents diagonal movement speed boost)
        const len_sq = vec.x * vec.x + vec.y * vec.y;
        if (len_sq > 1.0) {
            const len = @sqrt(len_sq);
            vec.x /= len;
            vec.y /= len;
        }
        return vec;
    }

    // --- Internal Helpers ---
    fn evaluateBindingDown(b: InputBinding) bool {
        return switch (b.source) {
            .keycode => |k| keyDown(k),
            .mouse_button => |m| mouseDown(m),
            .gamepad_button => |gb| gamepad.isButtonDown(gb),
            .gamepad_axis => evaluateBindingValue(b),
        };
    }

    fn evaluateBindingJustPressed(b: InputBinding) bool {
        return switch (b.source) {
            .keycode => |k| keyPressed(k),
            .mouse_button => |m| mousePressed(m),
            .gamepad_button => |gb| gamepad.isButtonJustPressed(gb),
            .gamepad_axis => false,
        };
    }

    fn evaluateBindingJustReleased(b: InputBinding) bool {
        return switch (b.source) {
            .keycode => |k| keyUp(k),
            .mouse_button => |m| mouseUp(m),
            .gamepad_button => |gb| gamepad.isButtonJustReleased(gb),
            .gamepad_axis => false,
        };
    }

    fn evaluateBindingValue(b: InputBinding) f32 {
        return switch (b.source) {
            .keycode => |k| if (keyDown(k)) 1.0 else 0.0,
            .mouse_button => |m| if (mouseDown(m)) 1.0 else 0.0,
            .gamepad_button => |gb| if (gamepad.isButtonDown(gb)) 1.0 else 0.0,
            .gamepad_axis => |ga| readGamepadAxis(ga, b.deadzone),
        };
    }

    fn readGamepadAxis(axis: GamepadAxis, deadzone: f32) f32 {
        const raw_val = gamepad.getAxis(axis);

        // Deadzone check
        const abs_val = @abs(raw_val);
        if (abs_val < deadzone) return 0.0;

        // Remap remaining range (deadzone..1.0) smoothly to (0.0..1.0)
        const sign: f32 = if (raw_val > 0.0) 1.0 else -1.0;
        return sign * ((abs_val - deadzone) / (1.0 - deadzone));
    }
};
