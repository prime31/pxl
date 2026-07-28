const std = @import("std");
const pxl = @import("../pxl.zig");

/// TODO: decide if the surrogate way is better. it lets state methods exist outside of the TObj struct.
/// TEnum: the enum that represents all your states
/// TObj: the object this state machine is wrapping
/// each state should be a method on your object converted to camelCase with State appended to it
/// ex: enum { run, wall_run } would have runState and wallRunState methods that take in *TObj
///
/// const States = enum { idle, run, fall, jump, dash, wall_jump };
/// var sm: StateMachine(States, Player) = .init(.fall);
pub fn StateMachine(TEnum: type, TObj: type) type {
    return struct {
        current: TEnum,
        elapsed: f32,

        pub fn init(initial_state: TEnum) @This() {
            return .{ .current = initial_state };
        }

        pub fn tick(self: @This(), obj: *TObj) void {
            self.elapsed += pxl.time.dt();

            switch (self.current) {
                inline else => |tag| {
                    const state_method = comptime pxl.util.snakeToCamel(@tagName(tag));
                    @call(.always_inline, @field(TObj, state_method ++ "State"), .{obj});
                },
            }
        }

        pub fn tickSurrogate(self: @This(), obj: *TObj, surrogate: anytype) void {
            self.elapsed += pxl.time.dt();

            switch (self.current) {
                inline else => |tag| {
                    const state_method = comptime pxl.util.snakeToCamel(@tagName(tag));
                    @call(.always_inline, @field(surrogate, state_method ++ "State"), .{obj});
                },
            }
        }

        // TODO: the method this calls (stateChanged) can return a bool to indicate a rejection of the state change
        /// calls a method fn stateChanged(prev: TEnum, next: TEnum, *TObj)
        pub fn change(self: *@This(), obj: *TObj, state: TEnum) void {
            if (self.current == state) return;
            const prev = self.current;
            self.current = state;
            obj.stateChanged(prev, self.current);
            self.elapsed = 0;
        }

        pub fn changeSurrogate(self: *@This(), obj: *TObj, state: TEnum, surrogate: anytype) void {
            if (self.current == state) return;
            const prev = self.current;
            self.current = state;
            surrogate.stateChanged(obj, prev, self.current);
            self.elapsed = 0;
        }
    };
}
