const std = @import("std");
const pxl = @import("../pxl.zig");
const LDtk = @import("LDtk.zig");

const api = pxl.api;
const Color = pxl.math.Color;
const Rect = pxl.math.Rect;
const Texture = pxl.gpu.Texture;

/// Draw every layer of `lvl` back-to-front (LDtk stores layers top-to-bottom,
/// index 0 is the top-most layer). Hidden layers are skipped. When
/// `render_entities` is false, .Entities layers are skipped so games can draw
/// them themselves.
pub fn renderLevel(map: *const LDtk, lvl: LDtk.Level, render_entities: bool) void {
    const layer_instances = lvl.layerInstances orelse return;

    var i: usize = layer_instances.len;
    while (i > 0) {
        i -= 1;
        const layer = layer_instances[i];

        if (!layer.visible) continue;
        if (layer.__type == .Entities and !render_entities) continue;

        renderLayer(map, lvl, layer);
    }
}

/// Draw a single layer at its world position (level world offset + layer offset).
pub fn renderLayer(map: *const LDtk, lvl: LDtk.Level, layer: LDtk.LayerInstance) void {
    const layer_x: f32 = @floatFromInt(lvl.worldX + layer.__pxTotalOffsetX);
    const layer_y: f32 = @floatFromInt(lvl.worldY + layer.__pxTotalOffsetY);

    switch (layer.__type) {
        .Entities => renderEntities(map, layer, layer_x, layer_y),
        .Tiles, .AutoLayer, .IntGrid => renderTiles(map, layer, layer_x, layer_y),
    }
}

/// Draw a tiles-backed layer at `layer_x`/`layer_y` (world pixels). Uses the
/// layer's override tileset UID when present, falling back to its tileset def
/// UID. A missing tileset texture logs a warning and skips the layer instead of
/// crashing. Kept separate from `renderLayer` so layers can be drawn at custom
/// offsets (parallax).
pub fn renderTiles(map: *const LDtk, layer: LDtk.LayerInstance, layer_x: f32, layer_y: f32) void {
    const tileset_uid = layer.overrideTilesetUid orelse layer.__tilesetDefUid orelse return;
    const tex = map.getTexture(tileset_uid) orelse {
        std.debug.print("tilemap: missing tileset texture for tileset uid {d}; skipping layer\n", .{tileset_uid});
        return;
    };

    const grid_size = layer.gridSize();
    for (layer.gridTiles) |tile| renderTile(tile, tex, grid_size, layer_x, layer_y, layer.__opacity);
    for (layer.autoLayerTiles) |tile| renderTile(tile, tex, grid_size, layer_x, layer_y, layer.__opacity);
}

/// Draw one tile instance: dest rect at `x`+px[0], `y`+px[1]; horizontal and
/// vertical flip bits are handled with negative source extents.
pub fn renderTile(t: LDtk.TileInstance, tex: Texture, grid_size: f32, x: f32, y: f32, opacity: f64) void {
    const dest_rect = Rect{
        .x = x + @as(f32, @floatFromInt(t.px[0])),
        .y = y + @as(f32, @floatFromInt(t.px[1])),
        .w = grid_size,
        .h = grid_size,
    };

    var src_x: f32 = @floatFromInt(t.src[0]);
    var src_y: f32 = @floatFromInt(t.src[1]);
    var src_w: f32 = grid_size;
    var src_h: f32 = grid_size;

    if (t.isFlippedX()) {
        src_x += src_w;
        src_w = -src_w;
    }

    if (t.isFlippedY()) {
        src_y += src_h;
        src_h = -src_h;
    }

    const src_rect = Rect{ .x = src_x, .y = src_y, .w = src_w, .h = src_h };
    api.drawTexturedRect(tex, dest_rect, src_rect, Color.fromRgba(1, 1, 1, @floatCast(t.a * opacity)));
}

/// Draw all entities in an `Entities` layer.
pub fn renderEntities(map: *const LDtk, layer: LDtk.LayerInstance, layer_x: f32, layer_y: f32) void {
    if (layer.__type != .Entities) return;

    for (layer.entityInstances) |entity| renderEntity(map, entity, layer_x, layer_y);
}

/// Draw one entity: its `__tile` when present, else a translucent `__smartColor`
/// rect as a fallback placeholder.
pub fn renderEntity(map: *const LDtk, entity: LDtk.EntityInstance, layer_x: f32, layer_y: f32) void {
    const width: f32 = @floatFromInt(entity.width);
    const height: f32 = @floatFromInt(entity.height);
    const pivot_x: f32 = @floatCast(entity.__pivot[0]);
    const pivot_y: f32 = @floatCast(entity.__pivot[1]);

    // top-left world position, pivot-adjusted
    const x: f32 = layer_x + @as(f32, @floatFromInt(entity.px[0])) - (pivot_x * width);
    const y: f32 = layer_y + @as(f32, @floatFromInt(entity.px[1])) - (pivot_y * height);

    if (entity.__tile) |tile| {
        const tex = map.getTexture(tile.tilesetUid) orelse return;

        api.drawTexturedRect(tex, .{ .x = x, .y = y, .w = width, .h = height }, .{
            .x = @floatFromInt(tile.x),
            .y = @floatFromInt(tile.y),
            .w = @floatFromInt(tile.w),
            .h = @floatFromInt(tile.h),
        }, Color.white);
    } else {
        // placeholder: translucent __smartColor rect
        var color = Color.parse(entity.__smartColor) catch Color.magenta;
        color.set_a(153); // ~60% alpha

        api.drawRect(.init(x, y - height), .init(width, height), color);
    }
}
