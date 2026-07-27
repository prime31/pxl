const std = @import("std");
const pxl = @import("pxl.zig");

var start: i96 = 0;
var fps_frames: i96 = 0;
var prev_time: i96 = 0;
var curr_time: i96 = 0;
var fps_last_update: i96 = 0;
var frames_per_second: i64 = 0;
var frame_count: u32 = 1;

pub fn init() void {
    start = std.Io.Clock.now(.awake, pxl.io).toNanoseconds();
}

pub fn update() void {
    frame_count += 1;
    fps_frames += 1;
    prev_time = curr_time;
    curr_time = std.Io.Clock.now(.awake, pxl.io).toNanoseconds();

    if (curr_time > fps_last_update + 1_000_000_000) {
        const time_since_last = curr_time - fps_last_update;
        frames_per_second = @intCast(@divTrunc(fps_frames * 1_000_000_000, time_since_last));
        fps_last_update = curr_time;
        fps_frames = 0;
    }
}

pub fn dt() f32 {
    const ms = curr_time - prev_time;
    return @as(f32, @floatFromInt(ms)) / 1_000_000_000.0;
}

pub fn dt64() f64 {
    const ms = curr_time - prev_time;
    return @as(f64, @floatFromInt(ms)) / 1_000_000_000.0;
}
