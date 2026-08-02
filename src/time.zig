const std = @import("std");
const pxl = @import("pxl.zig");
const sapp = @import("sokol").app;
const stm = @import("sokol").time;

// State tracking variables
var start_ticks: u64 = 0;
var fps_frames: u32 = 0;
var fps_last_update_ticks: u64 = 0;
var frames_per_second: u32 = 0;
var frame_count: u32 = 0; // Starts at 0, increments on update

pub fn init() void {
    stm.setup();
    start_ticks = stm.now();
    fps_last_update_ticks = start_ticks;
}

pub fn update() void {
    frame_count += 1;
    fps_frames += 1;

    const curr_ticks = stm.now();
    const elapsed_since_fps_update = stm.diff(curr_ticks, fps_last_update_ticks);

    // Update FPS counter once per second (1,000,000,000 nanoseconds)
    if (elapsed_since_fps_update >= 1_000_000_000) {
        // stm.sec converts high-res ticks directly to standard f64 seconds
        const seconds_passed = stm.sec(elapsed_since_fps_update);

        frames_per_second = @intFromFloat(@as(f64, @floatFromInt(fps_frames)) / seconds_passed);
        fps_last_update_ticks = curr_ticks;
        fps_frames = 0;
    }
}

/// Returns a smoothed 32-bit float delta time averaged over 256 frames.
pub fn dt() f32 {
    return @floatCast(sapp.frameDuration());
}

/// Returns a smoothed 64-bit float delta time averaged over 256 frames.
pub fn dt64() f64 {
    return sapp.frameDuration();
}

/// Returns a raw, non-smoothed delta time for the current frame.
/// Essential for benchmarking or manual accumulator physics steps.
pub fn rawDt() f64 {
    return sapp.frameDurationRaw();
}

/// Returns the stable, averaged frame rate calculated over 1-second intervals.
pub fn fps() u32 {
    return frames_per_second;
}

/// Returns the current total count of processed frames.
pub fn frameCount() u32 {
    return frame_count;
}

/// Returns the total running time in seconds since the application started.
pub fn time() f32 {
    return @floatCast(stm.sec(stm.since(start_ticks)));
}

/// Returns the total running time in high-precision seconds as an f64.
pub fn time64() f64 {
    return stm.sec(stm.since(start_ticks));
}
