const std = @import("std");

const mem = @import("../pxl.zig").mem;

pub fn Vec(comptime T: type) type {
    return struct {
        const Self = @This();
        items: []T = &[_]T{},
        capacity: usize = 0,

        pub const empty: Self = .{
            .items = &.{},
            .capacity = 0,
        };

        pub fn deinit(self: *Self) void {
            mem.allocator.free(self.allocatedSlice());
            self.* = undefined;
        }

        /// The caller owns the returned memory. Empties this Vec. Its capacity is cleared, making `deinit` safe but unnecessary to call.
        pub fn toOwnedSlice(self: *Self) []T {
            const old_memory = self.allocatedSlice();
            if (mem.allocator.remap(old_memory, self.items.len)) |new_items| {
                self.* = .{};
                return new_items;
            }

            const new_memory = mem.allocator.alloc(T, self.items.len) catch unreachable;
            @memcpy(new_memory, self.items);
            self.clearAndFree();
            return new_memory;
        }

        const init_capacity = @as(comptime_int, @max(1, std.atomic.cache_line / @sizeOf(T)));

        fn growCapacity(current: usize, minimum: usize) usize {
            var new = current;
            while (true) {
                new +|= new / 2 + init_capacity;
                if (new >= minimum)
                    return new;
            }
        }

        /// Invalidates all element pointers.
        pub fn clearAndFree(self: *Self) void {
            mem.allocator.free(self.allocatedSlice());
            self.items.len = 0;
            self.capacity = 0;
        }

        pub fn clearRetainingCapacity(self: *Self) void {
            self.items.len = 0;
        }

        pub fn ensureTotalCapacity(self: *Self, new_capacity: usize) void {
            if (self.capacity >= new_capacity) return;
            return self.ensureTotalCapacityPrecise(growCapacity(self.capacity, new_capacity));
        }

        fn ensureTotalCapacityPrecise(self: *Self, new_capacity: usize) void {
            if (@sizeOf(T) == 0) {
                self.capacity = std.math.maxInt(usize);
                return;
            }

            if (self.capacity >= new_capacity) return;

            const old_memory = self.allocatedSlice();
            if (mem.allocator.remap(old_memory, new_capacity)) |new_memory| {
                self.items.ptr = new_memory.ptr;
                self.capacity = new_memory.len;
            } else {
                const new_memory = mem.allocator.alloc(T, new_capacity) catch unreachable;
                @memcpy(new_memory[0..self.items.len], self.items);
                mem.allocator.free(old_memory);
                self.items.ptr = new_memory.ptr;
                self.capacity = new_memory.len;
            }
        }

        /// Modify the array so that it can hold at least `additional_count` **more** items.
        /// Invalidates element pointers if additional memory is needed.
        pub fn ensureUnusedCapacity(self: *Self, additional_count: usize) void {
            return self.ensureTotalCapacity(self.items.len + additional_count);
        }

        pub fn addOne(self: *Self) *T {
            // This can never overflow because `self.items` can never occupy the whole address space
            const newlen = self.items.len + 1;
            self.ensureTotalCapacity(newlen);
            return self.addOneAssumeCapacity();
        }

        pub fn addOneAssumeCapacity(self: *Self) *T {
            std.debug.assert(self.items.len < self.capacity);
            self.items.len += 1;
            return &self.items[self.items.len - 1];
        }

        pub fn append(self: *Self, item: T) void {
            const new_item_ptr = self.addOne();
            new_item_ptr.* = item;
        }

        /// Extends the list by 1 element. Never invalidates element pointers.
        /// Asserts that the list can hold one additional item.
        pub fn appendAssumeCapacity(self: *Self, item: T) void {
            self.addOneAssumeCapacity().* = item;
        }

        /// Append the slice of items to the list. Allocates more
        /// memory as necessary.
        /// Invalidates element pointers if additional memory is needed.
        pub fn appendSlice(self: *Self, items: []const T) void {
            self.ensureUnusedCapacity(items.len);
            const old_len = self.items.len;
            const new_len = old_len + items.len;

            std.debug.assert(new_len <= self.capacity);
            self.items.len = new_len;
            @memcpy(self.items[old_len..][0..items.len], items);
        }

        /// Append a value to the list `n` times.
        /// Never invalidates element pointers.
        /// The function is inline so that a comptime-known `value` parameter will
        /// have a more optimal memset codegen in case it has a repeated byte pattern.
        /// Asserts that the list can hold the additional items.
        pub inline fn appendNTimesAssumeCapacity(self: *Self, value: T, n: usize) void {
            const new_len = self.items.len + n;
            std.debug.assert(new_len <= self.capacity);
            @memset(self.items.ptr[self.items.len..new_len], value);
            self.items.len = new_len;
        }

        pub fn orderedRemove(self: *Self, i: usize) T {
            const old_item = self.items[i];
            self.replaceRangeAssumeCapacity(i, 1, &.{});
            return old_item;
        }

        pub fn swapRemove(self: *Self, i: usize) T {
            if (self.items.len - 1 == i) return self.pop().?;

            const old_item = self.items[i];
            self.items[i] = self.pop().?;
            return old_item;
        }

        pub fn pop(self: *Self) ?T {
            if (self.items.len == 0) return null;
            const val = self.items[self.items.len - 1];
            self.items.len -= 1;
            return val;
        }

        pub fn allocatedSlice(self: Self) []T {
            return self.items.ptr[0..self.capacity];
        }
    };
}
