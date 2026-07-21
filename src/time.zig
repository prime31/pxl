const std = @import("std");
const pxl = @import("pxl.zig");

pub const Time = struct {
    start: i96,
    fps_frames: i96 = 0,
    prev_time: i96 = 0,
    curr_time: i96 = 0,
    fps_last_update: i96 = 0,
    frames_per_second: i64 = 0,
    frame_count: u32 = 1,

    pub fn init() Time {
        return .{
            .start = std.Io.Clock.now(.awake, pxl.io).toNanoseconds(),
        };
    }

    pub fn update(self: *Time) void {
        self.frame_count += 1;
        self.fps_frames += 1;
        self.prev_time = self.curr_time;
        self.curr_time = std.Io.Clock.now(.awake, pxl.io).toNanoseconds();

        if (self.curr_time > self.fps_last_update + 1_000_000_000) {
            const time_since_last = self.curr_time - self.fps_last_update;
            self.frames_per_second = @intCast(@divTrunc(self.fps_frames * 1_000_000_000, time_since_last));
            self.fps_last_update = self.curr_time;
            self.fps_frames = 0;
        }
    }

    pub fn deltaTime(self: *const Time) f32 {
        const ms = self.curr_time - self.prev_time;
        return @as(f32, @floatFromInt(ms)) / 1_000_000_000.0;
    }

    pub fn deltaTimeF64(self: *const Time) f64 {
        const ms = self.curr_time - self.prev_time;
        return @as(f64, @floatFromInt(ms)) / 1_000_000_000.0;
    }
};
