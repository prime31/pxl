const std = @import("std");

pub const Vec = @import("vec.zig").Vec;
pub const SlotMap = @import("slotmap.zig").SlotMap;

/// asserts with a message
pub fn assertMsg(ok: bool, comptime msg: []const u8, args: anytype) void {
    if (@import("builtin").mode == .Debug) {
        if (!ok) {
            std.debug.print("Assertion: " ++ msg ++ "\n", args);
            unreachable;
        }
    }
}

pub fn printLn(comptime msg: []const u8, args: anytype) void {
    std.debug.print(msg ++ "\n", args);
}

/// gets a unique global id for a type
pub fn typeId(comptime T: type) usize {
    return @intFromPtr(&PerTypeGlobalStruct(T).unique_global);
}

fn PerTypeGlobalStruct(comptime _: type) type {
    return struct {
        pub var unique_global: u1 = 0;
    };
}

pub const BlockTimer = struct {
    start: i128,

    pub fn init() BlockTimer {
        return BlockTimer{ .start = std.time.nanoTimestamp() };
    }

    pub fn deinit(self: BlockTimer) void {
        const end = std.time.nanoTimestamp();
        const elapsed_ns = end - self.start;
        const elapsed_ms: f64 = @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000.0;
        std.debug.print("Elapsed: {d:.3} ms\n", .{elapsed_ms});
    }
};
