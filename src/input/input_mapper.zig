const std = @import("std");
const builtin = @import("builtin");
const pxl = @import("../pxl.zig");
const input = pxl.input;

const gamepad = @import("gamepad.zig");

const GamepadButton = gamepad.GamepadButton;
const GamepadAxis = gamepad.GamepadAxis;
const GamepadState = gamepad.GamepadState;
const AnalogStickState = gamepad.AnalogStickState;
const DigitalInputs = gamepad.DigitalInputs;

const MouseButton = @import("mouse.zig").MouseButton;
const Keycode = @import("keycode.zig").Keycode;

pub const AxisDiagonal = enum { raw, normalized, square, digital };

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

/// can manage all InputBindings instead of having separate InputActions
/// this would make it more like Godots input system. Still needs the get* methods added
pub const InputMapper = struct {
    actions: std.StringHashMap(pxl.util.Vec(InputBinding)),

    pub fn init() InputMapper {
        return .{
            .actions = std.StringHashMap(pxl.util.Vec(InputBinding)).init(pxl.mem.allocator),
        };
    }

    pub fn deinit(self: *InputMapper) void {
        var it = self.actions.valueIterator();
        while (it.next()) |*vec| vec.*.deinit();
        self.actions.deinit();
    }

    pub fn addBinding(self: *InputMapper, action_name: []const u8, binding: InputBinding) void {
        const res = self.actions.getOrPut(action_name) catch unreachable;
        if (!res.found_existing) {
            res.value_ptr.* = pxl.util.Vec(InputBinding).empty;
        }
        res.value_ptr.append(binding);
    }

    /// Checks if action is currently active (Godot's is_action_pressed)
    pub fn isActionPressed(self: *const InputMapper, action_name: []const u8) bool {
        const bindings = self.actions.get(action_name) orelse return false;
        for (bindings.items) |b| {
            if (self.evaluateBindingDown(b)) return true;
        }
        return false;
    }

    /// Checks frame 0 press (Godot's is_action_just_pressed)
    pub fn isActionJustPressed(self: *const InputMapper, action_name: []const u8) bool {
        const bindings = self.actions.get(action_name) orelse return false;
        for (bindings.items) |b| {
            if (self.evaluateBindingJustPressed(b)) return true;
        }
        return false;
    }

    /// Checks frame 0 release
    pub fn isActionJustReleased(self: *const InputMapper, action_name: []const u8) bool {
        const bindings = self.actions.get(action_name) orelse return false;
        for (bindings.items) |b| {
            if (self.evaluateBindingJustReleased(b)) return true;
        }
        return false;
    }

    /// Gets a 1D float value (-1.0 to 1.0) for things like triggers or paired keys
    pub fn getActionAxis1D(self: *const InputMapper, action_name: []const u8) f32 {
        const bindings = self.actions.get(action_name) orelse return 0.0;
        var total: f32 = 0.0;
        for (bindings.items) |b| {
            total += evaluateBindingValue(b) * b.scale;
        }
        return std.math.clamp(total, -1.0, 1.0);
    }

    /// Composite 2D Vector Helper (Godot's get_vector)
    pub fn getVector(
        self: *const InputMapper,
        neg_x_action: []const u8,
        pos_x_action: []const u8,
        neg_y_action: []const u8,
        pos_y_action: []const u8,
        diagonal: AxisDiagonal,
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
            .keycode => |k| input.keyDown(k),
            .mouse_button => |m| input.mouseDown(m),
            .gamepad_button => |gb| gamepad.isButtonDown(gb),
            .gamepad_axis => evaluateBindingValue(b),
        };
    }

    fn evaluateBindingJustPressed(b: InputBinding) bool {
        return switch (b.source) {
            .keycode => |k| input.keyPressed(k),
            .mouse_button => |m| input.mousePressed(m),
            .gamepad_button => |gb| gamepad.isButtonJustPressed(gb),
            .gamepad_axis => false,
        };
    }

    fn evaluateBindingJustReleased(b: InputBinding) bool {
        return switch (b.source) {
            .keycode => |k| input.keyUp(k),
            .mouse_button => |m| input.mouseUp(m),
            .gamepad_button => |gb| gamepad.isButtonJustReleased(gb),
            .gamepad_axis => false,
        };
    }

    fn evaluateBindingValue(b: InputBinding) f32 {
        return switch (b.source) {
            .keycode => |k| if (input.keyDown(k)) 1.0 else 0.0,
            .mouse_button => |m| if (input.mouseDown(m)) 1.0 else 0.0,
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
