const std = @import("std");
const pxl = @import("pxl.zig");
const sapp = pxl.sapp;
const math = @import("math/math.zig");
const gamepad = pxl.gamepad;

const FixedList = @import("util/fixed_list.zig").FixedList;

const released: u3 = 1; // true only the frame the key is released
const down: u3 = 2; // true the entire time the key is down
const pressed: u3 = 3; // only true if down this frame and not down the previous frame

pub const MouseButton = enum(usize) {
    left = 0,
    right = 1,
    middle = 2,
};

var keys: [@intFromEnum(Keycode.menu)]u2 = [_]u2{0} ** @intFromEnum(Keycode.menu);
var dirty_keys: FixedList(i32, 10) = .empty;
var mouse_buttons: [4]u2 = [_]u2{0} ** 4;
var dirty_mouse_buttons: FixedList(u2, 3) = .empty;
var mouse_wheel_y: f32 = 0;
var mouse_x: f32 = 0;
var mouse_y: f32 = 0;
var mouse_rel_x: f32 = 0;
var mouse_rel_y: f32 = 0;

/// clears any released keys
pub fn newFrame() void {
    if (dirty_keys.len > 0) {
        var iter = dirty_keys.iter();
        while (iter.next()) |key| {
            const ukey: usize = @intCast(key);

            // guard against double key presses
            if (keys[ukey] > 0)
                keys[ukey] -= 1;
        }
        dirty_keys.clear();
    }

    if (dirty_mouse_buttons.len > 0) {
        var iter = dirty_mouse_buttons.iter();
        while (iter.next()) |button| {

            // guard against double mouse presses
            if (mouse_buttons[button] > 0)
                mouse_buttons[button] -= 1;
        }
        dirty_mouse_buttons.clear();
    }

    mouse_wheel_y = 0;
    mouse_rel_x = 0;
    mouse_rel_y = 0;
}

pub fn handleEvent(evt: *const sapp.Event) void {
    switch (evt.type) {
        .KEY_DOWN, .KEY_UP => handleKeyboardEvent(evt),
        .MOUSE_DOWN, .MOUSE_UP => handleMouseEvent(evt),
        .MOUSE_MOVE => {
            // TODO: why does sokol send two mouse events with the same data???
            if (mouse_x == evt.mouse_x and mouse_y == evt.mouse_y) return;

            mouse_rel_x = evt.mouse_x - mouse_x;
            mouse_rel_y = mouse_y - evt.mouse_y;
            mouse_x = evt.mouse_x;
            mouse_y = evt.mouse_y;
        },
        .MOUSE_SCROLL => {
            mouse_wheel_y = evt.scroll_y;
        },
        else => {},
    }
}

fn handleKeyboardEvent(evt: *const sapp.Event) void {
    const scancode = @intFromEnum(evt.key_code);
    dirty_keys.append(scancode);

    if (evt.type == .KEY_UP) {
        keys[@intCast(scancode)] = released;
    } else {
        keys[@intCast(scancode)] = pressed;
    }
}

fn handleMouseEvent(evt: *const sapp.Event) void {
    const button = @intFromEnum(evt.mouse_button);
    dirty_mouse_buttons.append(@intCast(button));

    if (evt.type == .MOUSE_UP) {
        mouse_buttons[@intCast(button)] = released;
    } else {
        mouse_buttons[@intCast(button)] = pressed;
    }
}

/// only true if down this frame and not down the previous frame
pub fn keyPressed(scancode: Keycode) bool {
    return keys[@intCast(@intFromEnum(scancode))] == pressed;
}

/// true the entire time the key is down
pub fn keyDown(scancode: Keycode) bool {
    return keys[@intCast(@intFromEnum(scancode))] > released;
}

/// true only the frame the key is released
pub fn keyUp(scancode: Keycode) bool {
    return keys[@intCast(@intFromEnum(scancode))] == released;
}

/// only true if down this frame and not down the previous frame
pub fn mousePressed(button: MouseButton) bool {
    return mouse_buttons[@intFromEnum(button)] == pressed;
}

/// true the entire time the button is down
pub fn mouseDown(button: MouseButton) bool {
    return mouse_buttons[@intFromEnum(button)] > released;
}

/// true only the frame the button is released
pub fn mouseUp(button: MouseButton) bool {
    return mouse_buttons[@intFromEnum(button)] == released;
}

pub fn mouseWheel() i32 {
    return mouse_wheel_y;
}

pub fn mousePosVec() math.Vec2 {
    return .{ .x = mouse_x, .y = mouse_y };
}

pub fn mousePos(x: *i32, y: *i32) void {
    x.* = mouse_x;
    y.* = mouse_y;
}

/// Gets the scaled mouse position in design/render-target coordinates, taking into account
/// the currently active ResolutionPolicy scale and letterbox offset.
pub fn mousePosScaled(x: *f32, y: *f32) void {
    const scaler = pxl.gpu.gfx_config.resolution_policy.getScaler(pxl.gpu.gfx_config.design_width, pxl.gpu.gfx_config.design_height);
    const scale_val = if (scaler.scale == 0) 1.0 else scaler.scale;
    x.* = (mouse_x - @as(f32, @floatFromInt(scaler.x))) / scale_val;
    y.* = (mouse_y - @as(f32, @floatFromInt(scaler.y))) / scale_val;
}

pub fn mousePosScaledVec() math.Vec2 {
    var x: f32 = 0;
    var y: f32 = 0;
    mousePosScaled(&x, &y);
    return .{ .x = x, .y = y };
}

pub fn mouseRelMotion() math.Vec2 {
    return .{ .x = mouse_rel_x, .y = mouse_rel_y };
}

pub const Keycode = enum(i32) {
    invalid = 0,
    space = 32,
    apostrophe = 39,
    comma = 44,
    minus = 45,
    period = 46,
    slash = 47,
    _0 = 48,
    _1 = 49,
    _2 = 50,
    _3 = 51,
    _4 = 52,
    _5 = 53,
    _6 = 54,
    _7 = 55,
    _8 = 56,
    _9 = 57,
    semicolon = 59,
    equal = 61,
    a = 65,
    b = 66,
    c = 67,
    d = 68,
    e = 69,
    f = 70,
    g = 71,
    h = 72,
    i = 73,
    j = 74,
    k = 75,
    l = 76,
    m = 77,
    n = 78,
    o = 79,
    p = 80,
    q = 81,
    r = 82,
    s = 83,
    t = 84,
    u = 85,
    v = 86,
    w = 87,
    x = 88,
    y = 89,
    z = 90,
    left_bracket = 91,
    backslash = 92,
    right_bracket = 93,
    grave_accent = 96,
    world_1 = 161,
    world_2 = 162,
    escape = 256,
    enter = 257,
    tab = 258,
    backspace = 259,
    insert = 260,
    delete = 261,
    right = 262,
    left = 263,
    down = 264,
    up = 265,
    page_up = 266,
    page_down = 267,
    home = 268,
    end = 269,
    caps_lock = 280,
    scroll_lock = 281,
    num_lock = 282,
    print_screen = 283,
    pause = 284,
    f1 = 290,
    f2 = 291,
    f3 = 292,
    f4 = 293,
    f5 = 294,
    f6 = 295,
    f7 = 296,
    f8 = 297,
    f9 = 298,
    f10 = 299,
    f11 = 300,
    f12 = 301,
    f13 = 302,
    f14 = 303,
    f15 = 304,
    f16 = 305,
    f17 = 306,
    f18 = 307,
    f19 = 308,
    f20 = 309,
    f21 = 310,
    f22 = 311,
    f23 = 312,
    f24 = 313,
    f25 = 314,
    kp_0 = 320,
    kp_1 = 321,
    kp_2 = 322,
    kp_3 = 323,
    kp_4 = 324,
    kp_5 = 325,
    kp_6 = 326,
    kp_7 = 327,
    kp_8 = 328,
    kp_9 = 329,
    kp_decimal = 330,
    kp_divide = 331,
    kp_multiply = 332,
    kp_subtract = 333,
    kp_add = 334,
    kp_enter = 335,
    kp_equal = 336,
    left_shift = 340,
    left_control = 341,
    left_alt = 342,
    left_super = 343,
    right_shift = 344,
    right_control = 345,
    right_alt = 346,
    right_super = 347,
    menu = 348,
};
