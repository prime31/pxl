const std = @import("std");
const pxl = @import("../pxl.zig");
const math = pxl.math;
const cast = pxl.util.cast;

pub const LDtk = @import("LDtk.zig");

const LayerInstance = LDtk.LayerInstance;
const CollisionIterator = @import("collision_iterator.zig").CollisionIterator;

/// Accumulates fractional pixel movement while still letting the body move in
/// whole-pixel steps. This is what makes smooth low-res movement possible: a
/// velocity of e.g. 0.4 px/frame is carried in `remainder` until it crosses a
/// whole pixel, so a 1.5 px/frame speed produces 1,2,1,2... steps instead of
/// being truncated to 1 every frame. It also means a joystick reading well below
/// 1.0 never stalls the player.
pub const SubpixelFloat = struct {
    remainder: f32 = 0,

    /// Feeds `velocity` (in pixels per frame, i.e. px/sec * dt) into the
    /// accumulator and returns the number of whole pixels to move this frame.
    /// The remaining fraction is kept for the next frame. `@trunc` rounds toward
    /// zero so a resting (0) velocity never drifts into a pixel.
    pub fn update(self: *SubpixelFloat, velocity: f32) i32 {
        const acc: f32 = self.remainder + velocity;
        const integral: i32 = @intFromFloat(@trunc(acc));
        self.remainder = acc - @as(f32, @floatFromInt(integral));
        return integral;
    }

    /// Drops any saved fraction. Called when that axis is blocked by a collision
    /// so leftover subpixel velocity can't push through the wall next frame.
    pub fn reset(self: *SubpixelFloat) void {
        self.remainder = 0;
    }
};

pub const CollisionState = struct {
    below: bool = false,
    above: bool = false,
    right: bool = false,
    left: bool = false,
    was_grounded_last_frame: bool = false,
    became_grounded_this_frame: bool = false,
    /// When true the body moves in whole-pixel steps (crisp low-res / pixel art)
    /// using the subpixel accumulators. When false it moves fractionally and
    /// smoothly (for non-pixel-art) against the same collision map.
    pixel_perfect: bool = true,
    x: SubpixelFloat = .{},
    y: SubpixelFloat = .{},

    pub fn reset(self: *CollisionState, motion: *const math.Vec2) void {
        if (motion.x == 0) {
            self.right = false;
            self.left = false;
        }

        if (motion.y == 0) {
            self.above = false;
            self.below = false;
        }

        self.became_grounded_this_frame = false;
    }
};

// the inset on the horizontal/vertical planes that the BoxCollider will be shrunk by when moving
const horiz_inset = 2;
const vert_inset = 2;

/// Moves `rect` by `velocity` (in pixels/sec), clamped against the collision
/// layer, and fills in the collision state. When `state.pixel_perfect` is true
/// the velocity is scaled by the frame time and fed through the subpixel
/// accumulators so the body only ever moves in whole pixels while retaining its
/// fractional speed. When false the body moves fractionally for smooth
/// non-pixel-art movement.
pub fn moveBody(map: *LDtk, rect: *math.Rect, state: *CollisionState, velocity: math.Vec2) void {
    // save off our current grounded state for was_grounded_last_frame / became_grounded_this_frame
    state.was_grounded_last_frame = state.below;
    state.reset(&velocity);

    const layer_index = 1; // TODO: layer needs to be passed in at some point
    const layer = map.root.levels[0].layerInstances.?[layer_index];
    const dt = pxl.time.dt();

    // --- X axis ---
    if (state.pixel_perfect) {
        const step = state.x.update(velocity.x * dt); // whole pixels for this frame
        if (step != 0) {
            const local = rect.asRectI();
            const moved = moveX(map, layer, local, step, state);
            if (@abs(moved) < @abs(step)) state.x.reset(); // hit a wall: drop leftover remainder
            rect.x += @floatFromInt(moved);
        }
    } else {
        rect.x += moveXFloat(map, layer, rect.*, velocity.x * dt, state);
    }

    // --- Y axis ---
    if (state.pixel_perfect) {
        const step = state.y.update(velocity.y * dt);
        if (step != 0) {
            const local = rect.asRectI();
            const moved = moveY(map, layer, local, step, state);
            if (@abs(moved) < @abs(step)) state.y.reset();
            rect.y += @floatFromInt(moved);
        }
    } else {
        rect.y += moveYFloat(map, layer, rect.*, velocity.y * dt, state);
    }

    if (!state.was_grounded_last_frame and state.below)
        state.became_grounded_this_frame = true;
}

/// A convenience wrapper around `moveBody` for the common player case.
pub const Player = struct {
    rect: math.Rect = .{},
    state: CollisionState = .{},
    speed: f32 = 60,

    pub fn move(self: *Player, map: *LDtk, input: math.Vec2) void {
        const velocity = math.Vec2{
            .x = input.x * self.speed,
            .y = input.y * self.speed,
        };
        moveBody(map, &self.rect, &self.state, velocity);
    }
};

pub fn moveX(map: *LDtk, layer: LayerInstance, rect: math.RectI, move_x: i32, state: *CollisionState) i32 {
    const edge: math.Edge = if (move_x > 0) .right else .left;
    var bounds = rect.halfRect(edge);

    // we contract horizontally for vertical movement and vertically for horizontal movement
    bounds.contract(0, vert_inset);
    // finally expand the side in the direction of movement
    bounds.expandEdge(edge, move_x);

    // debugOverlaps(map, bounds, edge);

    // keep track of any rows with slopes. We use this info to ignore collisions that occur with tiles behind slopes (inaccessible)
    // var slope_rows = [_]i32{ -1, -1, -1 };
    // var last_slope_row: usize = 0;

    var iter = CollisionIterator.init(map, bounds, edge);
    while (iter.next()) |pt| {
        if (layer.isCellSolid(@intCast(pt.x), @intCast(pt.y))) {
            // world_x is the LEFT of the tile
            const tile_size = cast(i32, layer.__gridSize);
            const world_x = tile_size * pt.x;
            if (move_x < 0) {
                state.left = true;
                return world_x + tile_size - rect.x;
            } else {
                state.right = true;
                return world_x - rect.right();
            }
        }

        // const tid = layer.getTileId(pt.x, pt.y);
        // if (tid >= 0) {
        //     if (map.tryGetTilesetTile(tid)) |tileset_tile| {
        //         // ignore oneway platforms and slopes
        //         if (tileset_tile.oneway) {
        //             continue;
        //         }
        //         if (tileset_tile.slope) {
        //             slope_rows[last_slope_row] = pt.y;
        //             last_slope_row += 1;
        //             continue;
        //         }
        //     }

        //     if (std.mem.indexOfScalar(i32, &slope_rows, pt.y) != null) {
        //         continue;
        //     }

        //     // world_x is the LEFT of the tile
        //     const world_x = map.tileToWorldX(pt.x);
        //     if (move_x < 0) {
        //         return world_x + map.tile_size - rect.x;
        //     } else {
        //         return world_x - rect.right();
        //     }
        // }
    }

    // state.right = false;
    // state.left = false;

    return move_x;
}

pub fn moveY(map: *LDtk, layer: LayerInstance, rect: math.RectI, move_y: i32, state: *CollisionState) i32 {
    const edge: math.Edge = if (move_y >= 0) .bottom else .top;
    var bounds = rect.halfRect(edge);

    // we contract horizontally for vertical movement and vertically for horizontal movement
    bounds.contract(horiz_inset, 0);
    // finally expand the side in the direction of movement
    bounds.expandEdge(edge, move_y);

    // debugOverlaps(map, bounds, edge);

    var iter = CollisionIterator.init(map, bounds, edge);
    while (iter.next()) |pt| {
        if (layer.isCellSolid(@intCast(pt.x), @intCast(pt.y))) {
            // world_y is the TOP of the tile
            const tile_size = cast(i32, layer.__gridSize);
            const world_y = tile_size * pt.y;
            if (move_y < 0) {
                state.above = true;
                return world_y + tile_size - rect.y;
            } else {
                state.below = true;
                return world_y - rect.bottom();
            }
        }

        // const tid = layer.getTileId(pt.x, pt.y);
        // if (tid >= 0) {
        //     if (map.tryGetTilesetTile(tid)) |tileset_tile| {
        //         if (tileset_tile.oneway) {
        //             // allow movement up always and down if our bottom is not above the tile
        //             if (edge == .top or map.tileToWorldY(pt.y) < rect.bottom()) {
        //                 continue;
        //             }
        //         } else if (tileset_tile.slope) {
        //             const perp_pos = bounds.centerX();
        //             const tile_world_x = map.tileToWorldY(pt.x);

        //             // only process the slope if our center is within the tiles bounds
        //             if (math.between(perp_pos, tile_world_x, tile_world_x + map.tile_size)) {
        //                 const leading_edge_pos = bounds.side(edge);
        //                 const tile_world_y = map.tileToWorldY(pt.y);
        //                 const slope_pos_y = tileset_tile.nameMe(tid, map.tile_size, perp_pos, tile_world_x, tile_world_y);

        //                 if (leading_edge_pos >= slope_pos_y) {
        //                     return slope_pos_y - rect.bottom();
        //                 }
        //                 return move_y;
        //             }
        //             continue;
        //         }
        //     } // end tryGetTilesetTile

        //     // world_y is the TOP of the tile
        //     const world_y = map.tileToWorldY(pt.y);

        //     if (edge == .top) {
        //         return world_y + map.tile_size - rect.y;
        //     } else {
        //         return world_y - rect.bottom();
        //     }
        // }
    }

    // state.above = false;
    // state.below = false;

    return move_y;
}

/// Fractional variant of `moveX` for non-pixel-perfect (smooth) movement. The
/// body rect may sit at a fractional position; collisions are still resolved
/// against integer tile cells, and the returned distance is the exact
/// fractional distance to the blocking wall (so motion stays smooth, not
/// snapped to whole pixels).
fn moveXFloat(map: *LDtk, layer: LayerInstance, rect: math.Rect, move_x: f32, state: *CollisionState) f32 {
    const edge: math.Edge = if (move_x > 0) .right else .left;
    // leading half of the body
    var bounds: math.Rect = if (edge == .right)
        .{ .x = rect.x + rect.w / 2, .y = rect.y, .w = rect.w / 2, .h = rect.h }
    else
        .{ .x = rect.x, .y = rect.y, .w = rect.w / 2, .h = rect.h };

    // contract vertically, then expand the leading edge in the direction of movement
    bounds.y += vert_inset;
    bounds.h -= 2 * vert_inset;
    const amt = @abs(move_x);
    if (edge == .right) {
        bounds.w += amt;
    } else {
        bounds.x -= amt;
        bounds.w += amt;
    }

    const ib = math.RectI{
        .x = @intFromFloat(@floor(bounds.x)),
        .y = @intFromFloat(@floor(bounds.y)),
        .w = @intFromFloat(@ceil(bounds.w)),
        .h = @intFromFloat(@ceil(bounds.h)),
    };

    var iter = CollisionIterator.init(map, ib, edge);
    while (iter.next()) |pt| {
        if (layer.isCellSolid(@intCast(pt.x), @intCast(pt.y))) {
            // world_x is the LEFT of the tile
            const tile_size = cast(f32, layer.__gridSize);
            const world_x = tile_size * @as(f32, @floatFromInt(pt.x));
            if (move_x < 0) {
                state.left = true;
                return world_x + tile_size - rect.x;
            } else {
                state.right = true;
                return world_x - rect.right();
            }
        }
    }

    return move_x;
}

/// Fractional variant of `moveY`, see `moveXFloat`.
fn moveYFloat(map: *LDtk, layer: LayerInstance, rect: math.Rect, move_y: f32, state: *CollisionState) f32 {
    const edge: math.Edge = if (move_y >= 0) .bottom else .top;
    // leading half of the body
    var bounds: math.Rect = if (edge == .bottom)
        .{ .x = rect.x, .y = rect.y + rect.h / 2, .w = rect.w, .h = rect.h / 2 }
    else
        .{ .x = rect.x, .y = rect.y, .w = rect.w, .h = rect.h / 2 };

    // contract horizontally, then expand the leading edge in the direction of movement
    bounds.x += horiz_inset;
    bounds.w -= 2 * horiz_inset;
    const amt = @abs(move_y);
    if (edge == .bottom) {
        bounds.h += amt;
    } else {
        bounds.y -= amt;
        bounds.h += amt;
    }

    const ib = math.RectI{
        .x = @intFromFloat(@floor(bounds.x)),
        .y = @intFromFloat(@floor(bounds.y)),
        .w = @intFromFloat(@ceil(bounds.w)),
        .h = @intFromFloat(@ceil(bounds.h)),
    };

    var iter = CollisionIterator.init(map, ib, edge);
    while (iter.next()) |pt| {
        if (layer.isCellSolid(@intCast(pt.x), @intCast(pt.y))) {
            // world_y is the TOP of the tile
            const tile_size = cast(f32, layer.__gridSize);
            const world_y = tile_size * @as(f32, @floatFromInt(pt.y));
            if (move_y < 0) {
                state.above = true;
                return world_y + tile_size - rect.y;
            } else {
                state.below = true;
                return world_y - rect.bottom();
            }
        }
    }

    return move_y;
}

fn debugOverlaps(map: *LDtk, bounds: math.RectI, edge: math.Edge) void {
    const layer = map.root.levels[0].layerInstances.?[1];
    var tile_cnt: i32 = 0;
    const tile_size = cast(f32, layer.__gridSize);

    var iter = CollisionIterator.init(map, bounds, edge);
    while (iter.next()) |pt| {
        const xw = cast(f32, pt.x) * tile_size;
        const yw = cast(f32, pt.y) * tile_size;
        const color = switch (tile_cnt) {
            0 => math.Color.yellow,
            1 => math.Color.red,
            2 => math.Color.blue,
            3 => math.Color.black,
            else => math.Color.orange,
        };
        pxl.dbg.drawHollowRect(.{ .x = xw, .y = yw }, tile_size, tile_size, 1, color);
        tile_cnt += 1;
    }
}

test "SubpixelFloat accumulates fractional velocity into whole-pixel steps" {
    var sp: SubpixelFloat = .{};

    // 0.4 px/frame for 5 frames should produce one move of 1 px on the 3rd
    // frame (0.4+0.4+0.4 = 1.2) and keep a remainder, never truncating below 1.
    const steps = [_]i32{ sp.update(0.4), sp.update(0.4), sp.update(0.4), sp.update(0.4), sp.update(0.4) };
    try std.testing.expectEqualSlices(i32, &[_]i32{ 0, 0, 1, 0, 1 }, &steps);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), sp.remainder, 0.0001);

    // A 1.5 px/frame velocity alternates 1,2,1,2 and does not lose the fraction.
    var sp2: SubpixelFloat = .{};
    const steps2 = [_]i32{ sp2.update(1.5), sp2.update(1.5), sp2.update(1.5), sp2.update(1.5) };
    try std.testing.expectEqualSlices(i32, &[_]i32{ 1, 2, 1, 2 }, &steps2);

    // reset() drops any saved fraction.
    var sp3: SubpixelFloat = .{};
    _ = sp3.update(0.6);
    sp3.reset();
    try std.testing.expectEqual(@as(i32, 0), sp3.update(0.6));
    try std.testing.expectApproxEqAbs(@as(f32, 0.6), sp3.remainder, 0.0001);
}
