const std = @import("std");

pub const AllocationType = enum { temp, persistent };

pub var default_gpa = std.heap.DebugAllocator(.{ .stack_trace_frames = 16 }){};

pub var allocator: std.mem.Allocator = undefined;
pub var scratch: std.mem.Allocator = undefined;
var scratch_instance: ScratchAllocator = undefined;

pub fn init() void {
    allocator = default_gpa.allocator();
    scratch_instance = ScratchAllocator.init(allocator);
    scratch = scratch_instance.allocator();
}

pub fn deinit() void {
    // Can check for memory leaks if we use the default GPA
    scratch_instance.deinit();
    _ = default_gpa.deinit();
}

pub fn create(comptime T: type, allocation_type: AllocationType) *T {
    return switch (allocation_type) {
        .temp => scratch.create(T) catch unreachable,
        .persistent => allocator.create(T) catch unreachable,
    };
}

pub fn destroy(ptr: anytype) void {
    allocator.destroy(ptr);
}

pub fn alloc(comptime T: type, n: usize, allocation_type: AllocationType) []T {
    return switch (allocation_type) {
        .temp => scratch.alloc(T, n) catch unreachable,
        .persistent => allocator.alloc(T, n) catch unreachable,
    };
}

pub fn dupe(comptime T: type, m: []const T, allocation_type: AllocationType) []T {
    return switch (allocation_type) {
        .temp => scratch.dupe(T, m) catch unreachable,
        .persistent => allocator.dupe(T, m) catch unreachable,
    };
}

pub fn dupeZ(comptime T: type, m: []const T, allocation_type: AllocationType) [:0]T {
    return switch (allocation_type) {
        .temp => scratch.dupeZ(T, m) catch unreachable,
        .persistent => allocator.dupeZ(T, m) catch unreachable,
    };
}

pub fn free(memory: anytype) void {
    allocator.free(memory);
}

const ScratchAllocator = struct {
    backup_allocator: std.mem.Allocator,
    end_index: usize,
    buffer: []u8,

    pub fn init(backing_allocator: std.mem.Allocator) ScratchAllocator {
        const scratch_buffer = backing_allocator.alloc(u8, 2 * 1024 * 1024) catch unreachable;

        return ScratchAllocator{
            .backup_allocator = backing_allocator,
            .buffer = scratch_buffer,
            .end_index = 0,
        };
    }

    pub fn deinit(self: *ScratchAllocator) void {
        self.backup_allocator.free(self.buffer);
    }

    pub fn allocator(self: *ScratchAllocator) std.mem.Allocator {
        return .{
            .ptr = self,
            .vtable = &.{
                .alloc = allocate,
                .resize = std.mem.Allocator.noResize,
                .remap = std.mem.Allocator.noRemap,
                .free = std.mem.Allocator.noFree,
            },
        };
    }

    fn allocate(ctx: *anyopaque, n: usize, alignment: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
        const self = @as(*ScratchAllocator, @ptrCast(@alignCast(ctx)));
        _ = ret_addr;

        const ptr_align = @as(usize, 1) << @as(std.mem.Allocator.Log2Align, @intFromEnum(alignment));
        const addr = @intFromPtr(self.buffer.ptr) + self.end_index;
        const adjusted_addr = std.mem.alignForward(usize, addr, ptr_align);
        const adjusted_index = self.end_index + (adjusted_addr - addr);
        const new_end_index = adjusted_index + n;

        if (new_end_index > self.buffer.len) {
            // if more memory is requested then we have in our buffer leak like a sieve!
            if (n > self.buffer.len) {
                std.debug.print("\n---------\nwarning: tmp allocated more than is in our temp allocator. This memory WILL leak!\n--------\n", .{});
                // return self.backup_allocator.alloc(allocator, n, ptr_align, len_align, ret_addr);
                return null;
            }

            const result = self.buffer[0..n];
            self.end_index = n;
            return result.ptr;
        }
        const result = self.buffer[adjusted_index..new_end_index];
        self.end_index = new_end_index;

        return result.ptr;
    }
};
