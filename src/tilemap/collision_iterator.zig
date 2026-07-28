const pxl = @import("../pxl.zig");
const tilemap = pxl.tilemap;
const math = pxl.math;
const cast = pxl.util.cast;

pub const CollisionIterator = struct {
    is_h: bool,
    first_primary: i32,
    last_primary: i32,
    prim_incr: i32,
    first_secondary: i32,
    last_secondary: i32,
    secondary_incr: i32,
    primary: i32,
    secondary: i32,

    const Vec2I = struct { x: i32, y: i32 };

    pub fn init(map: *tilemap.LDtk, bounds: math.RectI, edge: math.Edge) CollisionIterator {
        const is_h = edge.horizontal();
        const prim_axis = if (is_h) math.Axis.x else math.Axis.y;
        const op_axis = if (prim_axis == .x) math.Axis.y else math.Axis.x;

        const op_dir = edge.opposing();
        const frst_prim = worldToTile(map, bounds.side(op_dir), prim_axis);
        const lst_prim = worldToTile(map, bounds.side(edge), prim_axis);
        const prim_incr: i32 = if (edge.max()) 1 else -1;

        const min = worldToTile(map, if (is_h) bounds.top() else bounds.left(), op_axis);
        const mid = worldToTile(map, if (is_h) bounds.centerY() else bounds.centerX(), op_axis);
        const max = worldToTile(map, if (is_h) bounds.bottom() else bounds.right(), op_axis);

        const is_pos = mid - min < max - mid;
        const frst_secondary = if (is_pos) min else max;
        const lst_secondary = if (!is_pos) min else max;
        const secondary_incr: i32 = if (is_pos) 1 else -1;

        return .{
            .is_h = is_h,
            .first_primary = frst_prim,
            .last_primary = lst_prim,
            .prim_incr = prim_incr,
            .first_secondary = frst_secondary,
            .last_secondary = lst_secondary,
            .secondary_incr = secondary_incr,
            .primary = frst_prim,
            .secondary = frst_secondary - secondary_incr,
        };
    }

    pub fn next(self: *CollisionIterator) ?Vec2I {
        // increment the inner loop
        self.secondary += self.secondary_incr;
        if (self.secondary != self.last_secondary + self.secondary_incr) {
            return self.current();
        }

        // reset the inner loop
        self.secondary = self.first_secondary;

        // increment the outer loop
        self.primary += self.prim_incr;
        if (self.primary == self.last_primary + self.prim_incr) {
            return null;
        }

        return self.current();
    }

    fn current(self: CollisionIterator) Vec2I {
        if (self.is_h) {
            return .{ .x = self.primary, .y = self.secondary };
        }
        return .{ .x = self.secondary, .y = self.primary };
    }
};

fn worldToTile(map: *tilemap.LDtk, pos: i32, axis: math.Axis) i32 {
    const pos_f: f32 = @floatFromInt(pos);
    const layer = map.root.levels[0].layerInstances.?[0];

    if (axis == .x) {
        const tile_x = math.ifloor(i32, pos_f / @as(f32, @floatFromInt(layer.__gridSize)));
        return math.iclamp(tile_x, 0, @intCast(layer.__cWid - 1));
    }

    const tile_y = math.ifloor(i32, pos_f / @as(f32, @floatFromInt(layer.__gridSize)));
    return math.iclamp(tile_y, 0, @intCast(layer.__cHei - 1));
}

// pub fn tileToWorldX(self: Map, x: i32) i32 {
//     return self.tile_size * x;
// }

// pub fn tileToWorldY(self: Map, y: i32) i32 {
//     return self.tile_size * y;
// }

// fn worldToTileX(map: *tilemap.LDtk, x: f32) i32 {
//     const tile_x = math.ifloor(i32, x / @as(f32, @floatFromInt(map.tile_size)));
//     return math.iclamp(tile_x, 0, map.width - 1);
// }

// pub fn worldToTileY(self: tilemap.LDtk, y: f32) i32 {
//     const tile_y = aya.math.ifloor(i32, y / @as(f32, @floatFromInt(self.tile_size)));
//     return aya.math.iclamp(tile_y, 0, self.height - 1);
// }
