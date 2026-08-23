const std = @import("std");
const pxl = @import("../pxl.zig");
const Texture = pxl.gpu.Texture;
const Color = pxl.math.Color;

const magic = "PXLM";
const version: u16 = 1;

pub const LayerType = enum(u8) {
    int_grid,
    tiles,
    auto_layer,
    entities,
};

pub const Tile = struct {
    x: i32,
    y: i32,
    source_x: u16,
    source_y: u16,
    tile_id: i32,
    flip_x: bool,
    flip_y: bool,
    alpha: u8,
};

pub const Field = struct {
    identifier: []const u8,
    type_name: []const u8,
    value_json: []const u8,
};

pub const EntityTile = struct {
    tileset_uid: i64,
    x: i32,
    y: i32,
    w: u16,
    h: u16,
};

pub const Entity = struct {
    identifier: []const u8,
    iid: []const u8,
    x: i32,
    y: i32,
    width: u16,
    height: u16,
    pivot_x: f32,
    pivot_y: f32,
    tile: ?EntityTile,
    tags: []const []const u8,
    fields: []const Field,
};

pub const Layer = struct {
    identifier: []const u8,
    iid: []const u8,
    kind: LayerType,
    visible: bool,
    opacity: f32,
    grid_size: u16,
    width: u32,
    height: u32,
    offset_x: i32,
    offset_y: i32,
    total_offset_x: i32,
    total_offset_y: i32,
    tileset_uid: ?i64,
    tiles: []const Tile,
    collision: []const u8,
    entities: []const Entity,

    pub fn isCellSolid(self: Layer, x: u32, y: u32) bool {
        return self.collisionValue(x, y) > 0;
    }

    pub fn collisionValue(self: Layer, x: u32, y: u32) u8 {
        if (x >= self.width or y >= self.height) return 0;
        const i = x + y * self.width;
        if (i >= self.collision.len) return 0;
        return self.collision[i];
    }

    pub fn findEntity(self: Layer, identifier: []const u8) ?*const Entity {
        for (self.entities) |*entity| {
            if (std.mem.eql(u8, entity.identifier, identifier)) return entity;
        }
        return null;
    }
};

pub const Level = struct {
    identifier: []const u8,
    iid: []const u8,
    uid: i64,
    world_x: i32,
    world_y: i32,
    width: u32,
    height: u32,
    background: Color,
    layers: []const Layer,

    pub fn findLayer(self: Level, identifier: []const u8) ?*const Layer {
        for (self.layers) |*layer| {
            if (std.mem.eql(u8, layer.identifier, identifier)) return layer;
        }
        return null;
    }
};

pub const Tileset = struct {
    uid: i64,
    identifier: []const u8,
    texture_path: []const u8,
    tile_grid_size: u16,
    pixel_width: u32,
    pixel_height: u32,
    spacing: u16,
    padding: u16,
};

pub const Map = struct {
    data: []u8,
    tile_size: u16,
    tilesets: []const Tileset,
    levels: []const Level,
    tileset_textures: std.AutoHashMap(i64, *Texture),

    pub fn parse(bytes: []const u8) !Map {
        const data = pxl.mem.dupe(u8, bytes, .persistent);
        errdefer pxl.mem.free(data);

        var reader = Reader{ .data = data };
        if (!std.mem.eql(u8, try reader.readBytes(4), magic)) return error.InvalidPxlMap;
        if (try reader.readU16() != version) return error.UnsupportedPxlMapVersion;
        _ = try reader.readU16(); // flags
        const tile_size = try reader.readU16();
        _ = try reader.readU16(); // reserved
        const tileset_count = try reader.readU16();
        const level_count = try reader.readU16();

        var map = Map{
            .data = data,
            .tile_size = tile_size,
            .tilesets = &.{},
            .levels = &.{},
            .tileset_textures = std.AutoHashMap(i64, *Texture).init(pxl.mem.allocator),
        };
        errdefer map.deinit();

        const tilesets = pxl.mem.alloc(Tileset, tileset_count, .persistent);
        map.tilesets = tilesets;
        for (tilesets) |*tileset| {
            tileset.* = .{
                .uid = try reader.readI64(),
                .identifier = try reader.string(),
                .texture_path = try reader.string(),
                .tile_grid_size = try reader.readU16(),
                .pixel_width = try reader.readU32(),
                .pixel_height = try reader.readU32(),
                .spacing = try reader.readU16(),
                .padding = try reader.readU16(),
            };
        }

        const levels = pxl.mem.alloc(Level, level_count, .persistent);
        map.levels = levels;
        for (levels) |*level| {
            level.* = try reader.level();
        }
        if (reader.offset != data.len) return error.InvalidPxlMap;
        return map;
    }

    pub fn deinit(self: *Map) void {
        var iter = self.tileset_textures.iterator();
        while (iter.next()) |entry| pxl.assets.destroy(entry.value_ptr.*);
        self.tileset_textures.deinit();
        for (self.levels) |level| {
            for (level.layers) |layer| {
                for (layer.entities) |entity| {
                    pxl.mem.free(entity.tags);
                    pxl.mem.free(entity.fields);
                }
                pxl.mem.free(layer.tiles);
                pxl.mem.free(layer.collision);
                pxl.mem.free(layer.entities);
            }
            pxl.mem.free(level.layers);
        }
        pxl.mem.free(self.levels);
        pxl.mem.free(self.tilesets);
        pxl.mem.free(self.data);
        self.* = undefined;
    }

    pub fn tileSize(self: *const Map) u16 {
        return self.tile_size;
    }

    pub fn findLayer(self: *const Map, identifier: []const u8) ?*const Layer {
        if (self.levels.len == 0) return null;
        return self.levels[0].findLayer(identifier);
    }

    pub fn getTexture(self: *const Map, uid: i64) ?Texture {
        const ptr = self.tileset_textures.get(uid) orelse return null;
        return ptr.*;
    }

    pub fn loadTilesetTextures(self: *Map) !void {
        for (self.tilesets) |tileset| {
            if (self.tileset_textures.contains(tileset.uid)) continue;
            const texture_id = pxl.assets.findTextureId(tileset.texture_path) orelse {
                std.debug.print("tilemap texture is not in the asset manifest: {s}\n", .{tileset.texture_path});
                return error.AssetNotFound;
            };
            const texture = try pxl.assets.loadTexture(texture_id);
            errdefer pxl.assets.destroy(texture);
            try self.tileset_textures.put(tileset.uid, texture);
        }
    }
};

test "pxlmap parses the minimal map" {
    pxl.mem.init();
    defer pxl.mem.deinit();
    const bytes = [_]u8{
        'P', 'X', 'L', 'M',
        1, 0, // version
        0, 0, // flags
        16, 0, // tile size
        0, 0, // reserved
        0, 0, // tilesets
        0, 0, // levels
    };
    var map = try Map.parse(&bytes);
    map.deinit();
}

test "pxlmap rejects invalid headers" {
    pxl.mem.init();
    defer pxl.mem.deinit();
    try std.testing.expectError(error.InvalidPxlMap, Map.parse("not a pxlmap"));
}

const Reader = struct {
    data: []const u8,
    offset: usize = 0,

    fn take(self: *Reader, n: usize) ![]const u8 {
        if (n > self.data.len - self.offset) return error.InvalidPxlMap;
        const result = self.data[self.offset .. self.offset + n];
        self.offset += n;
        return result;
    }

    fn readBytes(self: *Reader, n: usize) ![]const u8 {
        return self.take(n);
    }

    fn readU8(self: *Reader) !u8 {
        return (try self.take(1))[0];
    }

    fn readU16(self: *Reader) !u16 {
        var raw: [2]u8 = undefined;
        @memcpy(&raw, try self.take(2));
        return std.mem.readInt(u16, &raw, .little);
    }

    fn readU32(self: *Reader) !u32 {
        var raw: [4]u8 = undefined;
        @memcpy(&raw, try self.take(4));
        return std.mem.readInt(u32, &raw, .little);
    }

    fn readU64(self: *Reader) !u64 {
        var raw: [8]u8 = undefined;
        @memcpy(&raw, try self.take(8));
        return std.mem.readInt(u64, &raw, .little);
    }

    fn readI32(self: *Reader) !i32 {
        return @bitCast(try self.readU32());
    }

    fn readI64(self: *Reader) !i64 {
        return @bitCast(try self.readU64());
    }

    fn readF32(self: *Reader) !f32 {
        return @bitCast(try self.readU32());
    }

    fn string(self: *Reader) ![]const u8 {
        const len = try self.readU32();
        return self.take(len);
    }

    fn level(self: *Reader) !Level {
        const parsed_level = Level{
            .identifier = try self.string(),
            .iid = try self.string(),
            .uid = try self.readI64(),
            .world_x = try self.readI32(),
            .world_y = try self.readI32(),
            .width = try self.readU32(),
            .height = try self.readU32(),
            .background = .{ .value = try self.readU32() },
            .layers = &.{},
        };
        const layers = pxl.mem.alloc(Layer, try self.readU16(), .persistent);
        for (layers) |*item| item.* = try self.layer();
        return .{ .identifier = parsed_level.identifier, .iid = parsed_level.iid, .uid = parsed_level.uid, .world_x = parsed_level.world_x, .world_y = parsed_level.world_y, .width = parsed_level.width, .height = parsed_level.height, .background = parsed_level.background, .layers = layers };
    }

    fn layer(self: *Reader) !Layer {
        const identifier = try self.string();
        const iid = try self.string();
        const kind: LayerType = @enumFromInt(try self.readU8());
        const visible = (try self.readU8()) != 0;
        const opacity = @as(f32, @floatFromInt(try self.readU8())) / 255.0;
        const grid_size = try self.readU16();
        const width = try self.readU32();
        const height = try self.readU32();
        const offset_x = try self.readI32();
        const offset_y = try self.readI32();
        const total_offset_x = try self.readI32();
        const total_offset_y = try self.readI32();
        const tileset_raw = try self.readI64();
        const tile_count = try self.readU32();
        const tiles = pxl.mem.alloc(Tile, tile_count, .persistent);
        for (tiles) |*tile| {
            const flags = try self.readU8();
            tile.* = .{
                .x = try self.readI32(),
                .y = try self.readI32(),
                .source_x = try self.readU16(),
                .source_y = try self.readU16(),
                .tile_id = try self.readI32(),
                .flip_x = (flags & 1) != 0,
                .flip_y = (flags & 2) != 0,
                .alpha = try self.readU8(),
            };
        }
        const collision_count = try self.readU32();
        const collision = pxl.mem.alloc(u8, collision_count, .persistent);
        @memcpy(collision, try self.readBytes(collision_count));
        const entity_count = try self.readU32();
        const entities = pxl.mem.alloc(Entity, entity_count, .persistent);
        for (entities) |*item| item.* = try self.entity();
        return .{
            .identifier = identifier,
            .iid = iid,
            .kind = kind,
            .visible = visible,
            .opacity = opacity,
            .grid_size = grid_size,
            .width = width,
            .height = height,
            .offset_x = offset_x,
            .offset_y = offset_y,
            .total_offset_x = total_offset_x,
            .total_offset_y = total_offset_y,
            .tileset_uid = if (tileset_raw < 0) null else tileset_raw,
            .tiles = tiles,
            .collision = collision,
            .entities = entities,
        };
    }

    fn entity(self: *Reader) !Entity {
        const identifier = try self.string();
        const iid = try self.string();
        const parsed_entity = Entity{
            .identifier = identifier,
            .iid = iid,
            .x = try self.readI32(),
            .y = try self.readI32(),
            .width = try self.readU16(),
            .height = try self.readU16(),
            .pivot_x = try self.readF32(),
            .pivot_y = try self.readF32(),
            .tile = null,
            .tags = &.{},
            .fields = &.{},
        };
        const has_tile = try self.readU8();
        var result = parsed_entity;
        if (has_tile != 0) result.tile = .{ .tileset_uid = try self.readI64(), .x = try self.readI32(), .y = try self.readI32(), .w = try self.readU16(), .h = try self.readU16() };
        const tag_count = try self.readU16();
        const tags = pxl.mem.alloc([]const u8, tag_count, .persistent);
        for (tags) |*tag| tag.* = try self.string();
        result.tags = tags;
        const field_count = try self.readU16();
        const fields = pxl.mem.alloc(Field, field_count, .persistent);
        for (fields) |*field| field.* = .{ .identifier = try self.string(), .type_name = try self.string(), .value_json = try self.string() };
        result.fields = fields;
        return result;
    }
};
