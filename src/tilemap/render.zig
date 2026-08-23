const std = @import("std");
const pxl = @import("../pxl.zig");
const map_types = @import("map.zig");

const Map = map_types.Map;
const Level = map_types.Level;
const Layer = map_types.Layer;
const Tile = map_types.Tile;
const Entity = map_types.Entity;
const LayerType = map_types.LayerType;

const api = pxl.api;
const Color = pxl.math.Color;
const Rect = pxl.math.Rect;
const Texture = pxl.gpu.Texture;

pub fn renderLevel(map: *const Map, lvl: Level, render_entities: bool) void {
    var i: usize = lvl.layers.len;
    while (i > 0) {
        i -= 1;
        const layer = lvl.layers[i];
        if (!layer.visible) continue;
        if (layer.kind == .entities and !render_entities) continue;
        renderLayer(map, lvl, layer);
    }
}

pub fn renderLayer(map: *const Map, lvl: Level, layer: Layer) void {
    const layer_x: f32 = @floatFromInt(lvl.world_x + layer.total_offset_x);
    const layer_y: f32 = @floatFromInt(lvl.world_y + layer.total_offset_y);
    switch (layer.kind) {
        .entities => renderEntities(map, layer, layer_x, layer_y),
        .tiles, .auto_layer, .int_grid => renderTiles(map, layer, layer_x, layer_y),
    }
}

pub fn renderTiles(map: *const Map, layer: Layer, layer_x: f32, layer_y: f32) void {
    const tileset_uid = layer.tileset_uid orelse return;
    const tex = map.getTexture(tileset_uid) orelse {
        std.debug.print("tilemap: missing tileset texture for tileset uid {d}; skipping layer\n", .{tileset_uid});
        return;
    };
    const grid_size: f32 = @floatFromInt(layer.grid_size);
    for (layer.tiles) |tile| renderTile(tile, tex, grid_size, layer_x, layer_y, layer.opacity);
}

pub fn renderTile(t: Tile, tex: Texture, grid_size: f32, x: f32, y: f32, opacity: f32) void {
    const dest_rect = Rect{
        .x = x + @as(f32, @floatFromInt(t.x)),
        .y = y + @as(f32, @floatFromInt(t.y)),
        .w = grid_size,
        .h = grid_size,
    };
    var src_x: f32 = @floatFromInt(t.source_x);
    var src_y: f32 = @floatFromInt(t.source_y);
    var src_w: f32 = grid_size;
    var src_h: f32 = grid_size;
    if (t.flip_x) {
        src_x += src_w;
        src_w = -src_w;
    }
    if (t.flip_y) {
        src_y += src_h;
        src_h = -src_h;
    }
    const alpha = @as(f32, @floatFromInt(t.alpha)) / 255.0 * opacity;
    api.drawTexturedRect(tex, dest_rect, .{ .x = src_x, .y = src_y, .w = src_w, .h = src_h }, Color.fromRgba(1, 1, 1, alpha));
}

pub fn renderEntities(map: *const Map, layer: Layer, layer_x: f32, layer_y: f32) void {
    if (layer.kind != .entities) return;
    for (layer.entities) |entity| renderEntity(map, entity, layer_x, layer_y);
}

pub fn renderEntity(map: *const Map, entity: Entity, layer_x: f32, layer_y: f32) void {
    const width: f32 = @floatFromInt(entity.width);
    const height: f32 = @floatFromInt(entity.height);
    const x = layer_x + @as(f32, @floatFromInt(entity.x)) - entity.pivot_x * width;
    const y = layer_y + @as(f32, @floatFromInt(entity.y)) - entity.pivot_y * height;

    if (entity.tile) |tile| {
        const tex = map.getTexture(tile.tileset_uid) orelse return;
        api.drawTexturedRect(tex, .{ .x = x, .y = y, .w = width, .h = height }, .{
            .x = @floatFromInt(tile.x),
            .y = @floatFromInt(tile.y),
            .w = @floatFromInt(tile.w),
            .h = @floatFromInt(tile.h),
        }, Color.white);
    } else {
        api.drawRect(.init(x, y - height), .init(width, height), Color.magenta);
    }
}
