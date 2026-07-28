const std = @import("std");
const pxl = @import("../pxl.zig");
const math = pxl.math;
const cast = pxl.util.cast;

pub const LDtk = @import("LDtk.zig");

const LayerInstance = LDtk.LayerInstance;
const CollisionIterator = @import("collision_iterator.zig").CollisionIterator;

pub const CollisionState = struct {
    below: bool = false,
    above: bool = false,
    right: bool = false,
    left: bool = false,
    was_grounded_last_frame: bool = false,
    became_grounded_this_frame: bool = false,
    // x_remainder: SubpixelFloat = .{},
    // y_remainder: SubpixelFloat = .{},

    pub fn reset(self: *CollisionState, motion: *math.Vec2) void {
        if (motion.x == 0) {
            self.right = false;
            self.left = false;
        }

        if (motion.y == 0) {
            self.above = false;
            self.below = false;
        }

        self.became_grounded_this_frame = false;

        // self.x_remainder.update(&motion.x);
        // self.y_remainder.update(&motion.y);

        // due to subpixel movement we might end up with 0 gravity when we really want there to be at least 1 pixel so slopes can work
        // if (self.below and motion.y == 0 and self.y_remainder.remainder > 0) {
        //     motion.y = 1;
        //     self.y_remainder.remainder = 0;
        // }
    }
};

// the inset on the horizontal/vertical planes that the BoxCollider will be shrunk by when moving
const horiz_inset = 2;
const vert_inset = 2;

pub fn move(map: *LDtk, rect: math.RectI, movement: *math.Vec2) void {
    // save off our current grounded state which we will use for was_grounded_last_frame and became_grounded_this_frame
    // state.was_grounded_last_frame = state.below;
    // state.reset(movement);

    const layer_index = 1; // TODO: layer needs to be passed in at some point
    const layer = map.root.levels[0].layerInstances.?[layer_index];

    var local_rect = rect;

    // TODO: should we still run through x movement even if there is none so the insets can push the player to the right spot?
    // we would need to fix the edge code because it uses move_x to determine which direction to look
    if (movement.x != 0) {
        const x = moveX(map, layer, rect, @as(i32, @intFromFloat(movement.x)));
        movement.x = @as(f32, @floatFromInt(x));
        local_rect.x += x;
    }

    movement.y = @as(f32, @floatFromInt(moveY(map, layer, local_rect, @as(i32, @intFromFloat(movement.y)))));

    // if (!state.was_grounded_last_frame and state.below)
    //     state.became_grounded_this_frame = true;
}

pub fn moveX(map: *LDtk, layer: LayerInstance, rect: math.RectI, move_x: i32) i32 {
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
                // state.left = true;
                return world_x + tile_size - rect.x;
            } else {
                // state.right = true;
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

pub fn moveY(map: *LDtk, layer: LayerInstance, rect: math.RectI, move_y: i32) i32 {
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
                // state.above = true;
                return world_y + tile_size - rect.y;
            } else {
                // state.below = true;
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
