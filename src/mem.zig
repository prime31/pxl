const std = @import("std");
const builtin = @import("builtin");

pub const AllocationType = enum { temp, persistent };

const Gpa = if (builtin.target.cpu.arch.isWasm()) WasmAllocator else std.heap.DebugAllocator(.{ .stack_trace_frames = 16 });

pub var default_gpa: Gpa = .{};

pub var allocator: std.mem.Allocator = undefined;
pub var scratch: std.mem.Allocator = undefined;
var scratch_instance: ScratchAllocator = undefined;

pub fn init() void {
    default_gpa = .{};
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

/// malloc/free-based allocator for wasm32-emscripten. The target can't use
/// std.heap.DebugAllocator (its stack-trace capture materializes
/// std.Options.debug_io, which doesn't compile for emscripten in Zig 0.16)
/// nor std.heap.wasm_allocator (it grows raw wasm memory and bypasses
/// Emscripten's fixed-size heap). Zig doesn't link libc itself for
/// wasm32-emscripten, so std.heap.c_allocator is unavailable and the libc
/// functions are declared manually, allocating out of Emscripten's own heap.
const WasmAllocator = struct {
    const Self = @This();

    extern "c" fn malloc(size: usize) ?*anyopaque;
    extern "c" fn free(ptr: ?*anyopaque) void;

    fn allocator(_: *const Self) std.mem.Allocator {
        return .{
            .ptr = undefined,
            .vtable = &.{
                .alloc = Self.alloc,
                .resize = std.mem.Allocator.noResize,
                .remap = std.mem.Allocator.noRemap,
                .free = Self.free_,
            },
        };
    }
    fn deinit(_: *const Self) void {}

    fn alloc(_: *anyopaque, len: usize, alignment: std.mem.Alignment, ret_addr: usize) ?[*]u8 {
        _ = ret_addr;
        // overallocate so we can store the original pointer before the aligned one
        const padded = len + @sizeOf(usize) + alignment.toByteUnits() - 1;
        const raw = malloc(padded) orelse return null;
        const raw_addr = @intFromPtr(raw);
        const aligned_addr = alignment.forward(raw_addr + @sizeOf(usize));
        const aligned: [*]u8 = @ptrFromInt(aligned_addr);
        (@as(*?*anyopaque, @ptrFromInt(aligned_addr - @sizeOf(usize)))).* = raw;
        return aligned;
    }

    fn free_(ctx: *anyopaque, memory: []u8, alignment: std.mem.Alignment, ret_addr: usize) void {
        _ = ctx;
        _ = alignment;
        _ = ret_addr;
        const header: *?*anyopaque = @ptrFromInt(@intFromPtr(memory.ptr) - @sizeOf(usize));
        Self.free(header.*);
    }
};

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
                if (!builtin.target.cpu.arch.isWasm()) {
                    std.debug.print("\n---------\nwarning: tmp allocated more than is in our temp allocator. This memory WILL leak!\n--------\n", .{});
                }
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
