const std = @import("std");

const pxl = @import("pxl");
const api = pxl.api;
const mu = pxl.mu;
const input = pxl.input;

const Color = pxl.math.Color;
const Vec2 = pxl.math.Vec2;

/// Most recent polled state of the first (index 0) gamepad. Both the microui
/// readout (update) and the on-canvas schematic (render) draw from this.
var state: input.GamepadState = undefined;
var has_state: bool = false;

var fmt_buf: [256]u8 = undefined;
fn fmt(comptime f: []const u8, args: anytype) [:0]const u8 {
    return std.fmt.bufPrintZ(&fmt_buf, f, args) catch unreachable;
}

// ---------- microui helpers ----------

fn buttonRow(name: [*c]const u8, pressed: bool) void {
    mu.layoutRow(2, &[_]c_int{ 84, -1 }, 0);
    mu.label(name);
    mu.label(if (pressed) "  ON" else "  --");
}

fn valueRow(name: [*c]const u8, value: [:0]const u8) void {
    mu.layoutRow(2, &[_]c_int{ 84, -1 }, 0);
    mu.label(name);
    mu.label(value);
}

// ---------- on-canvas drawing helpers ----------

fn drawStickPad(center: Vec2, radius: f32, stick: input.AnalogStickState, color: Color, label: []const u8) void {
    // outer boundary, dead-zone ring and crosshair
    api.drawCircleOutline(center, radius, 4, 48, Color.light_gray);
    api.drawCircleOutline(center, radius * 0.35, 2, 48, Color.gray);
    api.drawLine(.init(center.x - radius, center.y), .init(center.x + radius, center.y), 2, Color.gray);
    api.drawLine(.init(center.x, center.y - radius), .init(center.x, center.y + radius), 2, Color.gray);

    // direction vector
    api.drawLine(
        center,
        .init(center.x + stick.direction_x * radius, center.y - stick.direction_y * radius),
        3,
        color,
    );

    // knob dot pushed out by the normalized deflection
    const max_deflect = radius * 0.72;
    const knob = Vec2.init(
        center.x + stick.normalized_x * max_deflect,
        center.y - stick.normalized_y * max_deflect,
    );
    api.drawCircle(knob, 20, 32, color);
    api.drawCircleOutline(knob, 20, 3, 32, Color.black);

    api.drawText(null, .init(center.x - 8, center.y + radius + 12), label, Color.white);
    api.drawText(
        null,
        .init(center.x - radius, center.y - radius - 26),
        fmt("x:{d:.2} y:{d:.2} mag:{d:.2}", .{ stick.normalized_x, stick.normalized_y, stick.magnitude }),
        Color.white,
    );
}

fn drawButton(center: Vec2, radius: f32, pressed: bool, color: Color, label: []const u8) void {
    const c = if (pressed) color else Color.dark_gray;
    api.drawCircle(center, radius, 24, c);
    api.drawCircleOutline(center, radius, 3, 24, Color.light_gray);
    if (pressed) api.drawCircleOutline(center, radius, 6, 24, Color.white);
    // label tucked below so it never overlaps the lit state
    api.drawText(null, .init(center.x - 6, center.y + radius + 8), label, Color.white);
}

fn drawMeter(pos: Vec2, w: f32, h: f32, label: []const u8, value: f32, color: Color) void {
    api.drawText(null, .init(pos.x, pos.y - 18), label, Color.white);
    api.drawRectOutline(pos, .init(w, h), 2, Color.light_gray);
    const fill_w = std.math.clamp(value, 0.0, 1.0) * w;
    if (fill_w > 0) api.drawRect(pos, .init(fill_w, h), color);
}
// ---------- app callbacks ----------

pub fn update() !void {
    state = input.getGamepadState(0) orelse {
        has_state = false;
        state = .{};
        return;
    };
    has_state = true;

    if (mu.beginWindowEx("Gamepad 0", .{ .x = 740, .y = 20, .w = 268, .h = 460 }, .{ .no_close = true })) {
        mu.layoutRow(2, &[_]c_int{ 84, -1 }, 0);
        mu.label("Connected");
        mu.label(if (has_state and state.connected) "YES" else "NO");
        valueRow("Max pads", fmt("{d}", .{input.getMaxSupportedGamepads()}));

        if (mu.headerEx("Buttons", .{ .expanded = true })) {
            buttonRow("D-Pad Up", state.digital_inputs.dpad_up);
            buttonRow("D-Pad Down", state.digital_inputs.dpad_down);
            buttonRow("D-Pad Left", state.digital_inputs.dpad_left);
            buttonRow("D-Pad Right", state.digital_inputs.dpad_right);
            buttonRow("A", state.digital_inputs.a);
            buttonRow("B", state.digital_inputs.b);
            buttonRow("X", state.digital_inputs.x);
            buttonRow("Y", state.digital_inputs.y);
            buttonRow("Start", state.digital_inputs.start);
            buttonRow("Back", state.digital_inputs.back);
            buttonRow("L3 Thumb", state.digital_inputs.left_thumb);
            buttonRow("R3 Thumb", state.digital_inputs.right_thumb);
        }

        if (mu.headerEx("Sticks", .{ .expanded = true })) {
            valueRow("L X", fmt("{d:.2}", .{state.left_stick.normalized_x}));
            valueRow("L Y", fmt("{d:.2}", .{state.left_stick.normalized_y}));
            valueRow("L Mag", fmt("{d:.2}", .{state.left_stick.magnitude}));
            valueRow("R X", fmt("{d:.2}", .{state.right_stick.normalized_x}));
            valueRow("R Y", fmt("{d:.2}", .{state.right_stick.normalized_y}));
            valueRow("R Mag", fmt("{d:.2}", .{state.right_stick.magnitude}));
        }

        if (mu.headerEx("Shoulders / Triggers", .{ .expanded = true })) {
            valueRow("L1", fmt("{d:.2}", .{state.left_shoulder}));
            valueRow("R1", fmt("{d:.2}", .{state.right_shoulder}));
            valueRow("LT", fmt("{d:.2}", .{state.left_trigger}));
            valueRow("RT", fmt("{d:.2}", .{state.right_trigger}));
        }

        mu.endWindow();
    }
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = Color.aya });
    defer pxl.endPass();

    const connected = has_state and state.connected;

    api.drawText(null, .init(20, 18), "Gamepad 0 Tester", Color.white);
    api.drawText(
        null,
        .init(20, 38),
        if (connected) "Controller connected" else "No controller detected",
        if (connected) Color.green else Color.gray,
    );

    // analog stick pads
    drawStickPad(.init(200, 250), 100, state.left_stick, Color.sky_blue, "L");
    drawStickPad(.init(560, 250), 100, state.right_stick, Color.orange, "R");

    // d-pad
    const dp = Vec2.init(200, 520);
    drawButton(dp.add(.init(0, -34)), 15, state.digital_inputs.dpad_up, Color.light_gray, "UP");
    drawButton(dp.add(.init(0, 34)), 15, state.digital_inputs.dpad_down, Color.light_gray, "DN");
    drawButton(dp.add(.init(-34, 0)), 15, state.digital_inputs.dpad_left, Color.light_gray, "LT");
    drawButton(dp.add(.init(34, 0)), 15, state.digital_inputs.dpad_right, Color.light_gray, "RT");

    // face buttons (A/B/X/Y)
    const fb = Vec2.init(560, 520);
    drawButton(fb.add(.init(0, -34)), 16, state.digital_inputs.x, Color.blue, "X");
    drawButton(fb.add(.init(-34, 0)), 16, state.digital_inputs.y, Color.gold, "Y");
    drawButton(fb.add(.init(34, 0)), 16, state.digital_inputs.a, Color.red, "A");
    drawButton(fb.add(.init(0, 34)), 16, state.digital_inputs.b, Color.green, "B");

    // thumbstick (L3 / R3) press indicators
    drawButton(.init(200, 250), 24, state.digital_inputs.left_thumb, Color.green, "L3");
    drawButton(.init(560, 250), 24, state.digital_inputs.right_thumb, Color.green, "R3");

    // start / back
    drawButton(.init(400, 610), 16, state.digital_inputs.back, Color.gray, "Back");
    drawButton(.init(450, 610), 16, state.digital_inputs.start, Color.gray, "Start");

    // shoulder / trigger meters
    drawMeter(.init(90, 680), 130, 16, "L1", state.left_shoulder, Color.sky_blue);
    drawMeter(.init(250, 680), 130, 16, "R1", state.right_shoulder, Color.orange);
    drawMeter(.init(90, 720), 130, 16, "LT", state.left_trigger, Color.green);
    drawMeter(.init(250, 720), 130, 16, "RT", state.right_trigger, Color.green);
}
