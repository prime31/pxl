const std = @import("std");

const Color = @import("color.zig").Color;

// TODO: add init and seed with the address of `var seed: u64 = undefined;`
var rng = std.Random.DefaultPrng.init(0x12345678);
var random = rng.random();

pub fn seed(new_seed: u64) void {
    rng.seed(new_seed);
    random = rng.random();
}

pub fn boolean() bool {
    return random.boolean();
}

/// Returns a random int `i` such that `0 <= i <= maxInt(T)`
pub fn int(comptime T: type) T {
    return random.int(T);
}

/// Return a floating point value evenly distributed in the range [0, 1).
pub fn float(comptime T: type) T {
    return random.float(T);
}

pub fn color() Color {
    return Color.fromBytes(range(u8, 0, 255), range(u8, 0, 255), range(u8, 0, 255), 255);
}

/// Returns an evenly distributed random integer `at_least <= i < less_than`.
pub fn range(comptime T: type, at_least: T, less_than: T) T {
    if (@typeInfo(T) == .int) {
        return random.intRangeLessThanBiased(T, at_least, less_than);
    } else if (@typeInfo(T) == .float) {
        return at_least + random.float(T) * (less_than - at_least);
    }
    unreachable;
}

/// Returns an evenly distributed random unsigned integer `0 <= i < less_than`.
pub fn uintLessThan(comptime T: type, less_than: T) T {
    return random.uintLessThanBiased(T, less_than);
}

/// returns true if the next random is less than percent. Percent should be between 0 and 1
pub fn chance(percent: f32) bool {
    return random.float(f32) < percent;
}

pub fn choose(comptime T: type, first: T, second: T) T {
    if (random.int(u1) == 0) return first;
    return second;
}

pub fn choose3(comptime T: type, first: T, second: T, third: T) T {
    return switch (random.int(u2)) {
        0 => first,
        1 => second,
        2 => third,
    };
}
