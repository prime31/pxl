const std = @import("std");
const pxl = @import("pxl.zig");
const sapp = pxl.sapp;
const math = @import("math/math.zig");
const FixedList = @import("util/fixed_list.zig").FixedList;

const released: u3 = 1; // true only the frame the key is released
const down: u3 = 2; // true the entire time the key is down
const pressed: u3 = 3; // only true if down this frame and not down the previous frame

pub const MouseButton = enum(usize) {
    left = 0,
    right = 1,
    middle = 2,
};

pub const Input = struct {
    keys: [@intFromEnum(sapp.Keycode.MENU)]u2 = [_]u2{0} ** @intFromEnum(sapp.Keycode.MENU),
    dirty_keys: FixedList(i32, 10),
    mouse_buttons: [4]u2 = [_]u2{0} ** 4,
    dirty_mouse_buttons: FixedList(u2, 3),
    mouse_wheel_y: f32 = 0,
    mouse_x: f32 = 0,
    mouse_y: f32 = 0,
    mouse_rel_x: f32 = 0,
    mouse_rel_y: f32 = 0,
    window_scale: i32 = 0,
    // res_scaler: gfx.ResolutionScaler = undefined,

    pub fn init(win_scale: f32) Input {
        return .{
            .dirty_keys = FixedList(i32, 10).init(),
            .dirty_mouse_buttons = FixedList(u2, 3).init(),
            .window_scale = @intFromFloat(win_scale),
            // .res_scaler = gfx.getResolutionScaler(),
        };
    }

    /// clears any released keys
    pub fn newFrame(self: *Input) void {
        if (self.dirty_keys.len > 0) {
            var iter = self.dirty_keys.iter();
            while (iter.next()) |key| {
                const ukey: usize = @intCast(key);

                // guard against double key presses
                if (self.keys[ukey] > 0)
                    self.keys[ukey] -= 1;
            }
            self.dirty_keys.clear();
        }

        if (self.dirty_mouse_buttons.len > 0) {
            var iter = self.dirty_mouse_buttons.iter();
            while (iter.next()) |button| {

                // guard against double mouse presses
                if (self.mouse_buttons[button] > 0)
                    self.mouse_buttons[button] -= 1;
            }
            self.dirty_mouse_buttons.clear();
        }

        self.mouse_wheel_y = 0;
        self.mouse_rel_x = 0;
        self.mouse_rel_y = 0;
    }

    pub fn handleEvent(self: *Input, evt: *const sapp.Event) void {
        switch (evt.type) {
            .KEY_DOWN, .KEY_UP => self.handleKeyboardEvent(evt),
            .MOUSE_DOWN, .MOUSE_UP => self.handleMouseEvent(evt),
            .MOUSE_MOVE => {
                // TODO: why does sokol send two mouse events with the same data???
                if (self.mouse_x == evt.mouse_x and self.mouse_y == evt.mouse_y) return;

                self.mouse_rel_x = evt.mouse_x - self.mouse_x;
                self.mouse_rel_y = self.mouse_y - evt.mouse_y;
                self.mouse_x = evt.mouse_x;
                self.mouse_y = evt.mouse_y;
            },
            .MOUSE_SCROLL => {
                self.mouse_wheel_y = evt.scroll_y;
            },
            else => {},
        }
    }

    fn handleKeyboardEvent(self: *Input, evt: *const sapp.Event) void {
        const scancode = @intFromEnum(evt.key_code);
        self.dirty_keys.append(scancode);

        if (evt.type == .KEY_UP) {
            self.keys[@intCast(scancode)] = released;
        } else {
            self.keys[@intCast(scancode)] = pressed;
        }
    }

    fn handleMouseEvent(self: *Input, evt: *const sapp.Event) void {
        const button = @intFromEnum(evt.mouse_button);
        self.dirty_mouse_buttons.append(@intCast(button));

        if (evt.type == .MOUSE_UP) {
            self.mouse_buttons[@intCast(button)] = released;
        } else {
            self.mouse_buttons[@intCast(button)] = pressed;
        }
    }

    /// only true if down this frame and not down the previous frame
    pub fn keyPressed(self: Input, scancode: sapp.Keycode) bool {
        return self.keys[@intCast(@intFromEnum(scancode))] == pressed;
    }

    /// true the entire time the key is down
    pub fn keyDown(self: Input, scancode: sapp.Keycode) bool {
        return self.keys[@intCast(@intFromEnum(scancode))] > released;
    }

    /// true only the frame the key is released
    pub fn keyUp(self: Input, scancode: sapp.Keycode) bool {
        return self.keys[@intCast(@intFromEnum(scancode))] == released;
    }

    /// only true if down this frame and not down the previous frame
    pub fn mousePressed(self: Input, button: MouseButton) bool {
        return self.mouse_buttons[@intFromEnum(button)] == pressed;
    }

    /// true the entire time the button is down
    pub fn mouseDown(self: Input, button: MouseButton) bool {
        return self.mouse_buttons[@intFromEnum(button)] > released;
    }

    /// true only the frame the button is released
    pub fn mouseUp(self: Input, button: MouseButton) bool {
        return self.mouse_buttons[@intFromEnum(button)] == released;
    }

    pub fn mouseWheel(self: Input) i32 {
        return self.mouse_wheel_y;
    }

    pub fn mousePosVec(self: Input) math.Vec2 {
        return .{ .x = self.mouse_x, .y = self.mouse_y };
    }

    pub fn mousePos(self: Input, x: *i32, y: *i32) void {
        x.* = self.mouse_x;
        y.* = self.mouse_y;
    }

    // gets the scaled mouse position based on the currently bound render texture scale and offset
    // as calcuated in OffscreenPass. scale should be scale and offset_n is the calculated x, y value.
    pub fn mousePosScaled(self: Input, x: *i32, y: *i32) void {
        self.mousePos(x, y);

        const xf = @as(f32, @floatFromInt(x.*)) - @as(f32, @floatFromInt(self.res_scaler.x));
        const yf = @as(f32, @floatFromInt(y.*)) - @as(f32, @floatFromInt(self.res_scaler.y));
        x.* = @intFromFloat(xf / self.res_scaler.scale);
        y.* = @intFromFloat(yf / self.res_scaler.scale);
    }

    pub fn mousePosScaledVec(self: Input) math.Vec2 {
        var x: i32 = undefined;
        var y: i32 = undefined;
        self.mousePosScaled(&x, &y);
        return .{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
    }

    pub fn mouseRelMotion(self: Input) math.Vec2 {
        return .{ .x = self.mouse_rel_x, .y = self.mouse_rel_y };
    }
};
