const std = @import("std");
const pxl = @import("../pxl.zig");

const Rect = pxl.math.Rect;
const Texture = @import("texture.zig").Texture;

/// One frame of an animation: a texture region and how long it stays on screen.
/// `duration` is seconds for this specific frame, so frames may have different timings.
pub const Frame = struct {
    texture: Texture,
    source: Rect,
    duration: f32,
};

pub const LoopMode = enum(u8) {
    /// Wrap back to the first frame forever.
    loop,
    /// Play once, hold the last frame, and mark the player completed.
    once,
    /// Play to the last frame and hold it while staying in the running state.
    clamp_forever,
    /// Cycle first..last..first forever.
    ping_pong,
    /// Cycle first..last..first once, then complete.
    ping_pong_once,
    /// Cycle last..first..last forever.
    reverse,
    /// Cycle last..first once, then complete.
    reverse_once,
};

/// Stable id into an append-only `Store`. Animations are never deleted, so ids
/// are plain indices; `.none` doubles as "no animation".
pub const AnimationId = enum(u32) {
    none = std.math.maxInt(u32),
    _,
};

/// Immutable animation data. Playback state lives in `AnimationPlayer`, so one
/// `Animation` can be played by any number of players at once. `frames` is
/// borrowed from one of two owners: a `&.{...}` comptime literal for hand-tuned
/// frames, or a `Store` frame pool for `framesFromCells`/`gridFrames` output.
pub const Animation = struct {
    name: []const u8 = "",
    frames: []const Frame,
    loop_mode: LoopMode = .loop,
    /// After a `once`/`ping_pong_once` finishes, play this animation instead of completing.
    next: AnimationId = .none,
};

/// Append-only animation storage with stable element addresses. A fixed-capacity
/// array (rather than a growable Vec) keeps `*const Animation` pointers valid for
/// the store's whole lifetime — a Vec would reallocate and dangle them.
///
/// `frame_capacity` is the inline pool for heap-built frames (`framesFromCells` /
/// `gridFrames`). Frames written there are owned by the store and stay valid for
/// its whole lifetime, so callers never allocate or free animation frames.
pub fn Store(comptime animation_capacity: usize, comptime frame_capacity: usize) type {
    return struct {
        const Self = @This();

        items: [animation_capacity]Animation = undefined,
        len: usize = 0,

        frame_pool: [frame_capacity]Frame = undefined,
        frame_len: usize = 0,

        pub fn add(self: *Self, anim: Animation) AnimationId {
            std.debug.assert(self.len < animation_capacity);
            const id: AnimationId = @enumFromInt(@as(u32, @intCast(self.len)));
            self.items[self.len] = anim;
            self.len += 1;
            return id;
        }

        pub fn get(self: *const Self, id: AnimationId) *const Animation {
            std.debug.assert(id != .none);
            const i = @intFromEnum(id);
            std.debug.assert(i < self.len);
            return &self.items[i];
        }

        /// Reserve `n` frames in the store's pool; callers fill the slice, which
        /// stays valid for the store's lifetime (no free).
        fn reserveFrames(self: *Self, n: usize) []Frame {
            std.debug.assert(self.frame_len + n <= frame_capacity);
            const out = self.frame_pool[self.frame_len..][0..n];
            self.frame_len += n;
            return out;
        }

        /// Build frames from hardcoded atlas cell coordinates into the store's pool.
        pub fn framesFromCells(self: *Self, tex: Texture, cell_w: f32, cell_h: f32, cells: []const Cell, fps: f32) []const Frame {
            const frames = self.reserveFrames(cells.len);
            for (cells, frames) |c, *f| {
                f.* = .{
                    .texture = tex,
                    .source = Rect.init(@as(f32, @floatFromInt(c.x)) * cell_w, @as(f32, @floatFromInt(c.y)) * cell_h, cell_w, cell_h),
                    .duration = 1.0 / fps,
                };
            }
            return frames;
        }

        /// Slice a texture into a uniform grid of frames (row-major, cells of
        /// equal size) and store them in the store's pool.
        pub fn gridFrames(
            self: *Self,
            tex: Texture,
            cell_w: u32,
            cell_h: u32,
            padding: u32,
            margin: u32,
            cell_offset: u32,
            count: u32,
            duration: f32,
        ) []const Frame {
            const tex_w: u32 = @intCast(tex.width);
            const tex_h: u32 = @intCast(tex.height);
            if (tex_w <= margin * 2 or tex_h <= margin * 2) return &.{};

            const avail_w = tex_w - margin * 2;
            const avail_h = tex_h - margin * 2;
            const cols = (avail_w + padding) / (cell_w + padding);
            const rows = (avail_h + padding) / (cell_h + padding);
            const total = cols * rows;
            const want: usize = @intCast(@min(count, total - @min(cell_offset, total)));

            const frames = self.reserveFrames(want);
            for (frames, 0..) |*f, i| {
                const cell_idx: u32 = cell_offset + @as(u32, @intCast(i));
                const c = cell_idx % cols;
                const r = cell_idx / cols;
                f.* = .{
                    .texture = tex,
                    .source = Rect.init(
                        @floatFromInt(margin + c * (cell_w + padding)),
                        @floatFromInt(margin + r * (cell_h + padding)),
                        @floatFromInt(cell_w),
                        @floatFromInt(cell_h),
                    ),
                    .duration = duration,
                };
            }
            return frames;
        }

        /// Build + register a cell-based animation in one step.
        pub fn addCells(
            self: *Self,
            name: []const u8,
            tex: Texture,
            cell_w: f32,
            cell_h: f32,
            cells: []const Cell,
            fps: f32,
            loop_mode: LoopMode,
        ) AnimationId {
            return self.add(.{
                .name = name,
                .frames = self.framesFromCells(tex, cell_w, cell_h, cells, fps),
                .loop_mode = loop_mode,
            });
        }

        /// Build + register a grid-based animation in one step.
        pub fn addGrid(
            self: *Self,
            name: []const u8,
            tex: Texture,
            cell_w: u32,
            cell_h: u32,
            padding: u32,
            margin: u32,
            cell_offset: u32,
            count: u32,
            duration: f32,
            loop_mode: LoopMode,
        ) AnimationId {
            return self.add(.{
                .name = name,
                .frames = self.gridFrames(tex, cell_w, cell_h, padding, margin, cell_offset, count, duration),
                .loop_mode = loop_mode,
            });
        }
    };
}

const default_animation_capacity = 512;
const default_frame_capacity = 8192;
var store: Store(default_animation_capacity, default_frame_capacity) = .{};

/// Add an animation to the global store and return its id.
pub fn add(anim: Animation) AnimationId {
    return store.add(anim);
}

/// Reserve `n` frames in the global store's pool. Callers fill the returned
/// mutable slice; it stays valid for the store's lifetime (no free). Used by
/// asset loaders that build frames from external metadata (e.g. aseprite).
pub fn reserveFrames(n: usize) []Frame {
    return store.reserveFrames(n);
}

/// Resolve an id to its animation in the global store.
pub fn get(id: AnimationId) *const Animation {
    return store.get(id);
}

/// Build frames from hardcoded atlas cell coordinates into the global store's pool.
pub fn framesFromCells(tex: Texture, cell_w: f32, cell_h: f32, cells: []const Cell, fps: f32) []const Frame {
    return store.framesFromCells(tex, cell_w, cell_h, cells, fps);
}

/// Slice a texture into a uniform grid of frames in the global store's pool.
pub fn gridFrames(
    tex: Texture,
    cell_w: u32,
    cell_h: u32,
    padding: u32,
    margin: u32,
    cell_offset: u32,
    count: u32,
    duration: f32,
) []const Frame {
    return store.gridFrames(tex, cell_w, cell_h, padding, margin, cell_offset, count, duration);
}

/// Build + register a cell-based animation in the global store.
pub fn addCells(
    name: []const u8,
    tex: Texture,
    cell_w: f32,
    cell_h: f32,
    cells: []const Cell,
    fps: f32,
    loop_mode: LoopMode,
) AnimationId {
    return store.addCells(name, tex, cell_w, cell_h, cells, fps, loop_mode);
}

/// Build + register a grid-based animation in the global store.
pub fn addGrid(
    name: []const u8,
    tex: Texture,
    cell_w: u32,
    cell_h: u32,
    padding: u32,
    margin: u32,
    cell_offset: u32,
    count: u32,
    duration: f32,
    loop_mode: LoopMode,
) AnimationId {
    return store.addGrid(name, tex, cell_w, cell_h, padding, margin, cell_offset, count, duration, loop_mode);
}

pub const State = enum(u8) { none, running, paused, completed };

/// Playback state for one animation instance. Consumes an `Animation` by pointer;
/// the same animation data can drive many players without duplicating frames.
pub const AnimationPlayer = struct {
    animation: ?*const Animation = null,
    state: State = .none,
    frame_index: usize = 0,
    frame_time_left: f32 = 0,
    dir: i8 = 1,
    speed: f32 = 1,

    pub fn play(self: *AnimationPlayer, anim: *const Animation) void {
        self.animation = anim;
        self.dir = 1;
        if (anim.frames.len == 0) {
            self.state = .completed;
            return;
        }
        self.state = .running;
        self.frame_index = switch (anim.loop_mode) {
            .reverse, .reverse_once => anim.frames.len - 1,
            else => 0,
        };
        self.frame_time_left = anim.frames[self.frame_index].duration;
    }

    /// Convenience for `play(pxl.animation.get(id))`.
    pub fn playId(self: *AnimationPlayer, id: AnimationId) void {
        self.play(get(id));
    }

    pub fn update(self: *AnimationPlayer) void {
        self.updateWith(pxl.time.dt());
    }

    /// Advance by `dt` seconds (already multiplied by `speed`).
    pub fn updateWith(self: *AnimationPlayer, dt: f32) void {
        const anim = self.animation orelse return;
        if (self.state != .running or anim.frames.len == 0) return;

        self.frame_time_left -= dt * self.speed;
        while (self.frame_time_left <= 0) {
            if (!self.advance(anim)) break;
            self.frame_time_left += anim.frames[self.frame_index].duration;
        }
    }

    pub fn pause(self: *AnimationPlayer) void {
        if (self.state == .running) self.state = .paused;
    }

    pub fn resumePlaying(self: *AnimationPlayer) void {
        if (self.state == .paused) self.state = .running;
    }

    pub fn stop(self: *AnimationPlayer) void {
        self.animation = null;
        self.state = .none;
    }

    /// Current frame; only valid while `animation != null`.
    pub fn frame(self: AnimationPlayer) Frame {
        return self.animation.?.frames[self.frame_index];
    }

    /// True once a `once`/`ping_pong_once`/`reverse_once` animation has played through.
    pub fn finished(self: AnimationPlayer) bool {
        return self.state == .completed;
    }

    /// Advance to the next frame. Returns false when the loop stopped advancing
    /// (completion, chaining, or clamping), in which case the caller should not
    /// add more frame time.
    fn advance(self: *AnimationPlayer, anim: *const Animation) bool {
        switch (anim.loop_mode) {
            .loop => {
                self.setFrame((self.frame_index + 1) % anim.frames.len);
                return true;
            },
            .once => {
                if (self.frame_index + 1 >= anim.frames.len) return self.finish(anim);
                self.setFrame(self.frame_index + 1);
                return true;
            },
            .clamp_forever => {
                if (self.frame_index + 1 >= anim.frames.len) {
                    self.frame_time_left = anim.frames[self.frame_index].duration;
                    return false;
                }
                self.setFrame(self.frame_index + 1);
                return true;
            },
            .ping_pong, .ping_pong_once => return self.pingPong(anim),
            .reverse => {
                if (self.frame_index == 0) {
                    self.setFrame(anim.frames.len - 1);
                } else {
                    self.setFrame(self.frame_index - 1);
                }
                return true;
            },
            .reverse_once => {
                if (self.frame_index == 0) return self.finish(anim);
                self.setFrame(self.frame_index - 1);
                return true;
            },
        }
    }

    fn pingPong(self: *AnimationPlayer, anim: *const Animation) bool {
        if (anim.frames.len <= 1) {
            self.frame_time_left = anim.frames[self.frame_index].duration;
            return false;
        }
        const len: isize = @intCast(anim.frames.len);
        const next: isize = @as(isize, @intCast(self.frame_index)) + self.dir;
        if (next < 0 or next >= len) {
            if (anim.loop_mode == .ping_pong_once and self.dir < 0) return self.finish(anim);
            self.dir = -self.dir;
            self.setFrame(@intCast(@as(isize, @intCast(self.frame_index)) + self.dir));
        } else {
            self.setFrame(@intCast(next));
        }
        return true;
    }

    fn finish(self: *AnimationPlayer, anim: *const Animation) bool {
        if (anim.next != .none) {
            self.play(get(anim.next));
        } else {
            self.state = .completed;
        }
        return false;
    }

    fn setFrame(self: *AnimationPlayer, index: usize) void {
        self.frame_index = index;
    }
};

/// A grid cell for `framesFromCells`.
pub const Cell = struct { x: u16, y: u16 };

test "once completes and holds the last frame" {
    const frames = [_]Frame{
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
    };
    const anim = Animation{ .name = "once", .frames = &frames, .loop_mode = .once };
    var player = AnimationPlayer{};
    player.play(&anim);
    player.updateWith(3.5);
    try std.testing.expect(player.finished());
    try std.testing.expectEqual(@as(usize, 2), player.frame_index);
}

test "loop wraps back to the first frame" {
    const frames = [_]Frame{
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
    };
    const anim = Animation{ .name = "loop", .frames = &frames, .loop_mode = .loop };
    var player = AnimationPlayer{};
    player.play(&anim);
    player.updateWith(3);
    try std.testing.expectEqual(@as(usize, 0), player.frame_index);
    try std.testing.expectEqual(State.running, player.state);
}

test "clamp_forever holds the last frame while still running" {
    const frames = [_]Frame{
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
    };
    const anim = Animation{ .name = "clamp", .frames = &frames, .loop_mode = .clamp_forever };
    var player = AnimationPlayer{};
    player.play(&anim);
    player.updateWith(10);
    try std.testing.expectEqual(@as(usize, 1), player.frame_index);
    try std.testing.expectEqual(State.running, player.state);
}

test "ping_pong_once completes after the return trip" {
    const frames = [_]Frame{
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
    };
    const anim = Animation{ .name = "pp", .frames = &frames, .loop_mode = .ping_pong_once };
    var player = AnimationPlayer{};
    player.play(&anim);
    // 0->1->2->1->0 takes five 1s steps; completion lands on the sixth boundary.
    player.updateWith(5);
    try std.testing.expectEqual(@as(usize, 0), player.frame_index);
    try std.testing.expect(player.finished());
}

test "reverse_once plays backward and completes at the first frame" {
    const frames = [_]Frame{
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
    };
    const anim = Animation{ .name = "rev", .frames = &frames, .loop_mode = .reverse_once };
    var player = AnimationPlayer{};
    player.play(&anim);
    try std.testing.expectEqual(@as(usize, 2), player.frame_index);
    player.updateWith(3);
    try std.testing.expectEqual(@as(usize, 0), player.frame_index);
    try std.testing.expect(player.finished());
}

test "reverse wraps from the first frame back to the last" {
    const frames = [_]Frame{
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
        .{ .texture = Texture{}, .source = Rect{}, .duration = 1 },
    };
    const anim = Animation{ .name = "rev", .frames = &frames, .loop_mode = .reverse };
    var player = AnimationPlayer{};
    player.play(&anim);
    player.updateWith(3);
    try std.testing.expectEqual(@as(usize, 2), player.frame_index);
    try std.testing.expectEqual(State.running, player.state);
}

test "store ids are stable indices and get returns the stored animation" {
    var s = Store(4, 8){};
    const a = Animation{ .name = "a", .frames = &.{} };
    const b = Animation{ .name = "b", .frames = &.{} };
    const id_a = s.add(a);
    const id_b = s.add(b);
    try std.testing.expectEqual(@as(u32, 0), @intFromEnum(id_a));
    try std.testing.expectEqual(@as(u32, 1), @intFromEnum(id_b));
    try std.testing.expectEqualStrings("b", s.get(id_b).name);
}

test "gridFrames and addGrid store frames in the pool, no caller free" {
    var s = Store(8, 64){};
    const tex = Texture{ .width = 24, .height = 24 };

    const frames = s.gridFrames(tex, 12, 12, 0, 0, 0, 4, 0.1);
    try std.testing.expectEqual(@as(usize, 4), frames.len);
    // The slice lives inside the store's inline pool, so it needs no free.
    try std.testing.expect(@intFromPtr(frames.ptr) == @intFromPtr(&s.frame_pool[0]));

    const id = s.addGrid("grid", tex, 12, 12, 0, 0, 0, 4, 0.1, .once);
    try std.testing.expectEqualStrings("grid", s.get(id).name);
    try std.testing.expectEqual(@as(usize, 4), s.get(id).frames.len);
}

test "gridFrames clamps to the available cells" {
    var s = Store(8, 64){};
    const tex = Texture{ .width = 24, .height = 12 };
    const frames = s.gridFrames(tex, 12, 12, 0, 0, 0, 100, 0.1);
    try std.testing.expectEqual(@as(usize, 2), frames.len);
}

test "next chains into another animation instead of completing" {
    const frames_a = [_]Frame{.{ .texture = Texture{}, .source = Rect{}, .duration = 1 }};
    const frames_b = [_]Frame{.{ .texture = Texture{}, .source = Rect{}, .duration = 1 }};
    const b_id = add(.{ .name = "b", .frames = &frames_b });
    const a = Animation{ .name = "a", .frames = &frames_a, .loop_mode = .once, .next = b_id };
    var player = AnimationPlayer{};
    player.play(&a);
    player.updateWith(1);
    try std.testing.expectEqualStrings("b", player.animation.?.name);
    try std.testing.expectEqual(State.running, player.state);
}
