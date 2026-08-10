const std = @import("std");
const pxl = @import("../pxl.zig");
const api = pxl.api;

const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;

var debug_items: pxl.util.Vec(DebugDrawCommand) = .empty;

const DebugDrawCommand = union(enum) {
    point: Point,
    line: Line,
    rect: Rect,
    circle: Circle,
    text: Text,
};

const Point = struct {
    pos: Vec2,
    size: f32,
    color: Color,
};

const Line = struct {
    pt1: Vec2,
    pt2: Vec2,
    thickness: f32,
    color: Color,
};

const Rect = struct {
    pos: Vec2,
    size: Vec2,
    thickness: f32 = 0,
    hollow: bool = false,
    color: Color,
};

const Circle = struct {
    center: Vec2,
    r: f32,
    thickness: f32,
    hollow: bool = true,
    color: Color,
};

const Text = struct {
    pos: Vec2,
    text: []const u8,
    color: Color,
};

pub fn deinit() void {
    debug_items.deinit();
}

/// renders
pub fn render(enabled: bool) void {
    if (enabled and debug_items.items.len > 0) {
        for (debug_items.items) |item| {
            switch (item) {
                .point => |pt| api.drawPoint(pt.pos, pt.size, pt.color),
                .line => |line| api.drawLine(line.pt1, line.pt2, line.thickness, line.color),
                .rect => |rect| {
                    if (rect.hollow) {
                        api.drawRectOutline(rect.pos, rect.size, rect.thickness, rect.color);
                    } else {
                        api.drawRect(rect.pos, rect.size, rect.color);
                    }
                },
                .circle => |circle| api.drawCircle(circle.center, circle.r, 12, circle.color),
                .text => |text| {
                    api.drawText(null, text.pos, text.text, text.color);
                    // draw.textOptions(text.text, null, .{ .x = text.pos.x, .y = text.pos.y, .color = text.color, .sx = 2, .sy = 2 }),
                },
            }
        }
    }

    debug_items.clearRetainingCapacity();
}

pub fn drawPoint(pos: Vec2, size: f32, color: ?Color) void {
    const point = Point{ .pos = pos, .size = size, .color = color orelse Color.white };
    debug_items.append(.{ .point = point });
}

pub fn drawLine(pt1: Vec2, pt2: Vec2, thickness: f32, color: ?Color) void {
    const line = Line{ .pt1 = pt1, .pt2 = pt2, .thickness = thickness, .color = color orelse Color.white };
    debug_items.append(.{ .line = line });
}

pub fn drawRect(pos: Vec2, width: f32, height: f32, color: ?Color) void {
    const rect = Rect{ .pos = pos, .size = .init(width, height), .hollow = false, .color = color orelse Color.white };
    debug_items.append(.{ .rect = rect });
}

pub fn drawHollowRect(pos: Vec2, width: f32, height: f32, thickness: f32, color: ?Color) void {
    const rect = Rect{ .pos = pos, .size = .init(width, height), .thickness = thickness, .hollow = true, .color = color orelse Color.white };
    debug_items.append(.{ .rect = rect });
}

pub fn drawHollowCircle(center: Vec2, radius: f32, thickness: f32, color: ?Color) void {
    const circle = Circle{ .center = center, .r = radius, .thickness = thickness, .color = color orelse Color.white };
    debug_items.append(.{ .circle = circle });
}

pub fn drawText(text: []const u8, pos: Vec2, color: ?Color) void {
    const text_item = Text{ .pos = pos, .text = text, .color = color orelse Color.white };
    debug_items.append(.{ .text = text_item });
}

pub fn drawTextFmt(comptime fmt: []const u8, args: anytype, pos: Vec2, color: ?Color) void {
    const text = std.fmt.allocPrint(pxl.mem.scratch, fmt, args) catch |err| {
        std.debug.print("drawTextFormat error: {}\n", .{err});
        return;
    };

    const text_item = Text{ .pos = pos, .text = text, .color = color orelse Color.white };
    debug_items.append(.{ .text = text_item });
}
