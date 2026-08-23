const std = @import("std");

const allocator = std.heap.page_allocator;
const PxlMapJson = std.json.Value;

fn jsonGet(value: PxlMapJson, key: []const u8) ?PxlMapJson {
    return switch (value) {
        .object => |object| object.get(key),
        else => null,
    };
}

fn jsonString(value: ?PxlMapJson) []const u8 {
    return if (value) |v| switch (v) {
        .string => |s| s,
        else => "",
    } else "";
}

fn jsonInt(value: ?PxlMapJson) i64 {
    return if (value) |v| switch (v) {
        .integer => |i| i,
        .float => |f| @intFromFloat(f),
        else => 0,
    } else 0;
}

fn jsonOptionalInt(value: ?PxlMapJson) ?i64 {
    return if (value) |v| switch (v) {
        .integer => |i| i,
        .float => |f| @intFromFloat(f),
        .null => null,
        else => null,
    } else null;
}

fn jsonFloat(value: ?PxlMapJson) f64 {
    return if (value) |v| switch (v) {
        .integer => |i| @floatFromInt(i),
        .float => |f| f,
        else => 0,
    } else 0;
}

fn jsonFloatOr(value: ?PxlMapJson, fallback: f64) f64 {
    return if (value) |v| switch (v) {
        .integer => |i| @floatFromInt(i),
        .float => |f| f,
        else => fallback,
    } else fallback;
}

fn jsonBoolOr(value: ?PxlMapJson, fallback: bool) bool {
    return if (value) |v| switch (v) {
        .bool => |b| b,
        else => fallback,
    } else fallback;
}

fn jsonArray(value: ?PxlMapJson) []const PxlMapJson {
    return if (value) |v| switch (v) {
        .array => |a| a.items,
        else => &.{},
    } else &.{};
}

fn appendBytes(out: *std.ArrayList(u8), bytes: []const u8) !void {
    try out.appendSlice(allocator, bytes);
}
fn appendU8(out: *std.ArrayList(u8), value: u8) !void {
    try out.append(allocator, value);
}

fn appendU16(out: *std.ArrayList(u8), value: u16) !void {
    var bytes: [2]u8 = undefined;
    std.mem.writeInt(u16, &bytes, value, .little);
    try appendBytes(out, &bytes);
}

fn appendU32(out: *std.ArrayList(u8), value: u32) !void {
    var bytes: [4]u8 = undefined;
    std.mem.writeInt(u32, &bytes, value, .little);
    try appendBytes(out, &bytes);
}

fn appendI32(out: *std.ArrayList(u8), value: i32) !void {
    try appendU32(out, @bitCast(value));
}

fn appendI64(out: *std.ArrayList(u8), value: i64) !void {
    var bytes: [8]u8 = undefined;
    std.mem.writeInt(i64, &bytes, value, .little);
    try appendBytes(out, &bytes);
}

fn appendF32(out: *std.ArrayList(u8), value: f32) !void {
    try appendU32(out, @bitCast(value));
}

fn appendString(out: *std.ArrayList(u8), value: []const u8) !void {
    try appendU32(out, @intCast(value.len));
    try appendBytes(out, value);
}

fn appendColor(out: *std.ArrayList(u8), value: []const u8) !void {
    var color: u32 = 0xFF000000;
    const hex = if (value.len > 0 and value[0] == '#') value[1..] else value;
    if (hex.len >= 6) {
        const r = std.fmt.parseInt(u8, hex[0..2], 16) catch 0;
        const g = std.fmt.parseInt(u8, hex[2..4], 16) catch 0;
        const b = std.fmt.parseInt(u8, hex[4..6], 16) catch 0;
        const a = if (hex.len >= 8) std.fmt.parseInt(u8, hex[6..8], 16) catch 255 else 255;
        color = @as(u32, r) | (@as(u32, g) << 8) | (@as(u32, b) << 16) | (@as(u32, a) << 24);
    }
    try appendU32(out, color);
}

fn appendJson(out: *std.ArrayList(u8), value: PxlMapJson) !void {
    switch (value) {
        .null => try appendBytes(out, "null"),
        .bool => |v| try appendBytes(out, if (v) "true" else "false"),
        .integer => |v| try out.print(allocator, "{d}", .{v}),
        .float => |v| try out.print(allocator, "{d}", .{v}),
        .number_string => |v| try appendBytes(out, v),
        .string => |v| {
            try out.append(allocator, '"');
            for (v) |c| switch (c) {
                '"' => try appendBytes(out, "\\\""),
                '\\' => try appendBytes(out, "\\\\"),
                '\n' => try appendBytes(out, "\\n"),
                '\r' => try appendBytes(out, "\\r"),
                '\t' => try appendBytes(out, "\\t"),
                else => try out.append(allocator, c),
            };
            try out.append(allocator, '"');
        },
        .array => |a| {
            try out.append(allocator, '[');
            for (a.items, 0..) |item, i| {
                if (i != 0) try out.append(allocator, ',');
                try appendJson(out, item);
            }
            try out.append(allocator, ']');
        },
        .object => |object| {
            try out.append(allocator, '{');
            var it = object.iterator();
            var first = true;
            while (it.next()) |entry| {
                if (!first) try out.append(allocator, ',');
                first = false;
                try appendJson(out, .{ .string = entry.key_ptr.* });
                try out.append(allocator, ':');
                try appendJson(out, entry.value_ptr.*);
            }
            try out.append(allocator, '}');
        },
    }
}

fn appendField(out: *std.ArrayList(u8), field: PxlMapJson) !void {
    try appendString(out, jsonString(jsonGet(field, "__identifier")));
    try appendString(out, jsonString(jsonGet(field, "__type")));
    var value = std.ArrayList(u8).empty;
    defer value.deinit(allocator);
    if (jsonGet(field, "__value")) |v| try appendJson(&value, v);
    try appendString(out, value.items);
}

fn appendEntity(out: *std.ArrayList(u8), entity: PxlMapJson) !void {
    try appendString(out, jsonString(jsonGet(entity, "__identifier")));
    try appendString(out, jsonString(jsonGet(entity, "iid")));
    const px = jsonArray(jsonGet(entity, "px"));
    try appendI32(out, @intCast(jsonInt(if (px.len > 0) px[0] else null)));
    try appendI32(out, @intCast(jsonInt(if (px.len > 1) px[1] else null)));
    try appendU16(out, @intCast(jsonInt(jsonGet(entity, "width"))));
    try appendU16(out, @intCast(jsonInt(jsonGet(entity, "height"))));
    const pivot = jsonArray(jsonGet(entity, "__pivot"));
    try appendF32(out, @floatCast(jsonFloat(if (pivot.len > 0) pivot[0] else null)));
    try appendF32(out, @floatCast(jsonFloat(if (pivot.len > 1) pivot[1] else null)));
    if (jsonGet(entity, "__tile")) |tile| {
        try appendU8(out, 1);
        try appendI64(out, jsonInt(jsonGet(tile, "tilesetUid")));
        try appendI32(out, @intCast(jsonInt(jsonGet(tile, "x"))));
        try appendI32(out, @intCast(jsonInt(jsonGet(tile, "y"))));
        try appendU16(out, @intCast(jsonInt(jsonGet(tile, "w"))));
        try appendU16(out, @intCast(jsonInt(jsonGet(tile, "h"))));
    } else try appendU8(out, 0);
    const tags = jsonArray(jsonGet(entity, "__tags"));
    try appendU16(out, @intCast(tags.len));
    for (tags) |tag| try appendString(out, jsonString(tag));
    const fields = jsonArray(jsonGet(entity, "fieldInstances"));
    try appendU16(out, @intCast(fields.len));
    for (fields) |field| try appendField(out, field);
}

fn generatePxlMap(source: []const u8, map_dir: []const u8) ![]u8 {
    var parsed = try std.json.parseFromSlice(PxlMapJson, allocator, source, .{ .allocate = .alloc_always });
    defer parsed.deinit();
    const root = parsed.value;
    var out = std.ArrayList(u8).empty;
    errdefer out.deinit(allocator);
    try appendBytes(&out, "PXLM");
    try appendU16(&out, 1);
    try appendU16(&out, 0);
    const defs = jsonGet(root, "defs");
    const tilesets = jsonArray(if (defs) |d| jsonGet(d, "tilesets") else null);
    const levels = jsonArray(jsonGet(root, "levels"));
    const first_level = if (levels.len > 0) levels[0] else null;
    const first_layers = jsonArray(if (first_level) |level| jsonGet(level, "layerInstances") else null);
    const grid_size = if (first_layers.len > 0) jsonInt(jsonGet(first_layers[0], "__gridSize")) else jsonInt(jsonGet(root, "defaultGridSize"));
    try appendU16(&out, @intCast(grid_size));
    try appendU16(&out, 0);
    try appendU16(&out, @intCast(tilesets.len));
    try appendU16(&out, @intCast(levels.len));
    for (tilesets) |tileset| {
        try appendI64(&out, jsonInt(jsonGet(tileset, "uid")));
        try appendString(&out, jsonString(jsonGet(tileset, "identifier")));
        const rel_path = jsonString(jsonGet(tileset, "relPath"));
        if (rel_path.len > 0) {
            var path = std.ArrayList(u8).empty;
            defer path.deinit(allocator);
            try path.appendSlice(allocator, map_dir);
            try path.appendSlice(allocator, rel_path);
            try appendString(&out, path.items);
        } else try appendString(&out, "assets/maps/ldtk_icons.png");
        try appendU16(&out, @intCast(jsonInt(jsonGet(tileset, "tileGridSize"))));
        try appendU32(&out, @intCast(jsonInt(jsonGet(tileset, "pxWid"))));
        try appendU32(&out, @intCast(jsonInt(jsonGet(tileset, "pxHei"))));
        try appendU16(&out, @intCast(jsonInt(jsonGet(tileset, "spacing"))));
        try appendU16(&out, @intCast(jsonInt(jsonGet(tileset, "padding"))));
    }
    for (levels) |level| {
        try appendString(&out, jsonString(jsonGet(level, "identifier")));
        try appendString(&out, jsonString(jsonGet(level, "iid")));
        try appendI64(&out, jsonInt(jsonGet(level, "uid")));
        try appendI32(&out, @intCast(jsonInt(jsonGet(level, "worldX"))));
        try appendI32(&out, @intCast(jsonInt(jsonGet(level, "worldY"))));
        try appendU32(&out, @intCast(jsonInt(jsonGet(level, "pxWid"))));
        try appendU32(&out, @intCast(jsonInt(jsonGet(level, "pxHei"))));
        try appendColor(&out, jsonString(jsonGet(level, "__bgColor")));
        const layers = jsonArray(jsonGet(level, "layerInstances"));
        try appendU16(&out, @intCast(layers.len));
        for (layers) |layer| {
            try appendString(&out, jsonString(jsonGet(layer, "__identifier")));
            try appendString(&out, jsonString(jsonGet(layer, "iid")));
            const kind_name = jsonString(jsonGet(layer, "__type"));
            const kind: u8 = if (std.mem.eql(u8, kind_name, "IntGrid")) 0 else if (std.mem.eql(u8, kind_name, "Entities")) 3 else if (std.mem.eql(u8, kind_name, "Tiles")) 1 else 2;
            try appendU8(&out, kind);
            try appendU8(&out, if (jsonBoolOr(jsonGet(layer, "visible"), true)) 1 else 0);
            try appendU8(&out, @as(u8, @intFromFloat(@round(jsonFloatOr(jsonGet(layer, "__opacity"), 1) * 255))));
            try appendU16(&out, @intCast(jsonInt(jsonGet(layer, "__gridSize"))));
            try appendU32(&out, @intCast(jsonInt(jsonGet(layer, "__cWid"))));
            try appendU32(&out, @intCast(jsonInt(jsonGet(layer, "__cHei"))));
            try appendI32(&out, @intCast(jsonInt(jsonGet(layer, "pxOffsetX"))));
            try appendI32(&out, @intCast(jsonInt(jsonGet(layer, "pxOffsetY"))));
            try appendI32(&out, @intCast(jsonInt(jsonGet(layer, "__pxTotalOffsetX"))));
            try appendI32(&out, @intCast(jsonInt(jsonGet(layer, "__pxTotalOffsetY"))));
            const tile_uid = jsonOptionalInt(jsonGet(layer, "overrideTilesetUid")) orelse jsonOptionalInt(jsonGet(layer, "__tilesetDefUid"));
            try appendI64(&out, tile_uid orelse -1);
            const grid_tiles = jsonArray(jsonGet(layer, "gridTiles"));
            const auto_tiles = jsonArray(jsonGet(layer, "autoLayerTiles"));
            try appendU32(&out, @intCast(grid_tiles.len + auto_tiles.len));
            for ([_][]const PxlMapJson{ grid_tiles, auto_tiles }) |tile_list| for (tile_list) |tile| {
                try appendU8(&out, @intCast(jsonInt(jsonGet(tile, "f"))));
                const px = jsonArray(jsonGet(tile, "px"));
                const src = jsonArray(jsonGet(tile, "src"));
                try appendI32(&out, @intCast(jsonInt(if (px.len > 0) px[0] else null)));
                try appendI32(&out, @intCast(jsonInt(if (px.len > 1) px[1] else null)));
                try appendU16(&out, @intCast(jsonInt(if (src.len > 0) src[0] else null)));
                try appendU16(&out, @intCast(jsonInt(if (src.len > 1) src[1] else null)));
                try appendI32(&out, @intCast(jsonInt(jsonGet(tile, "t"))));
                try appendU8(&out, @as(u8, @intFromFloat(@round(jsonFloatOr(jsonGet(tile, "a"), 1) * 255))));
            };
            const collision = jsonArray(jsonGet(layer, "intGridCsv"));
            try appendU32(&out, @intCast(collision.len));
            for (collision) |cell| try appendU8(&out, @intCast(jsonInt(cell)));
            const entities = jsonArray(jsonGet(layer, "entityInstances"));
            try appendU32(&out, @intCast(entities.len));
            for (entities) |entity| try appendEntity(&out, entity);
        }
    }
    return out.toOwnedSlice(allocator);
}

fn readFile(io: std.Io, path: []const u8) ![]u8 {
    return std.Io.Dir.readFileAlloc(std.Io.Dir.cwd(), io, path, allocator, .unlimited);
}

fn writeFile(io: std.Io, path: []const u8, data: []const u8) !void {
    if (std.fs.path.dirname(path)) |dir| try std.Io.Dir.createDirPath(std.Io.Dir.cwd(), io, dir);
    try std.Io.Dir.writeFile(std.Io.Dir.cwd(), io, .{ .sub_path = path, .data = data });
}

fn processMaps(io: std.Io) !void {
    var dir = try std.Io.Dir.openDir(std.Io.Dir.cwd(), io, "assets_src/maps", .{ .iterate = true });
    defer dir.close(io);
    var walker = try std.Io.Dir.walkSelectively(dir, allocator);
    defer walker.deinit();
    while (try walker.next(io)) |entry| {
        if (entry.kind == .directory) {
            try walker.enter(io, entry);
            continue;
        }
        if (entry.kind != .file or !std.mem.eql(u8, std.fs.path.extension(entry.path), ".ldtk")) continue;
        const source_path = try std.fs.path.join(allocator, &.{ "assets_src/maps", entry.path });
        defer allocator.free(source_path);
        const source = try readFile(io, source_path);
        defer allocator.free(source);
        const map_dir = std.fs.path.dirname(entry.path) orelse "";
        const prefix = try std.fmt.allocPrint(allocator, "assets/maps/{s}", .{map_dir});
        defer allocator.free(prefix);
        const compiled = try generatePxlMap(source, prefix);
        defer allocator.free(compiled);
        const output = try std.fmt.allocPrint(allocator, "assets/maps/{s}.pxlmap", .{entry.path[0 .. entry.path.len - 5]});
        defer allocator.free(output);
        try writeFile(io, output, compiled);
    }
}

fn pathExists(io: std.Io, path: []const u8) bool {
    std.Io.Dir.access(std.Io.Dir.cwd(), io, path, .{}) catch return false;
    return true;
}

fn validateGenerated(io: std.Io) !void {
    var maps_dir = std.Io.Dir.openDir(std.Io.Dir.cwd(), io, "assets_src/maps", .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    defer maps_dir.close(io);
    var maps = try std.Io.Dir.walkSelectively(maps_dir, allocator);
    defer maps.deinit();
    while (try maps.next(io)) |entry| {
        if (entry.kind == .directory) {
            try maps.enter(io, entry);
            continue;
        }
        if (entry.kind != .file or !std.mem.eql(u8, std.fs.path.extension(entry.path), ".ldtk")) continue;
        const output = try std.fmt.allocPrint(allocator, "assets/maps/{s}.pxlmap", .{entry.path[0 .. entry.path.len - 5]});
        defer allocator.free(output);
        if (!pathExists(io, output)) {
            std.debug.print("pxl assets: generated asset '{s}' is missing; run `zig build assets`\n", .{output});
            return error.GeneratedAssetMissing;
        }
    }

    var aseprite_dir = std.Io.Dir.openDir(std.Io.Dir.cwd(), io, "assets_src/aseprite", .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
    defer aseprite_dir.close(io);
    var aseprite = try std.Io.Dir.walkSelectively(aseprite_dir, allocator);
    defer aseprite.deinit();
    while (try aseprite.next(io)) |entry| {
        if (entry.kind == .directory) {
            try aseprite.enter(io, entry);
            continue;
        }
        if (entry.kind != .file or !std.mem.eql(u8, std.fs.path.extension(entry.path), ".aseprite")) continue;
        const stem = try assetIdName(entry.path);
        defer allocator.free(stem);
        const json = try std.fmt.allocPrint(allocator, "assets/atlases/{s}.json", .{stem});
        defer allocator.free(json);
        const png = try std.fmt.allocPrint(allocator, "assets/atlases/{s}.png", .{stem});
        defer allocator.free(png);
        if (!pathExists(io, json) or !pathExists(io, png)) {
            std.debug.print("pxl assets: generated Aseprite output for '{s}' is missing; run `zig build assets`\n", .{entry.path});
            return error.GeneratedAssetMissing;
        }
    }
}

fn assetIdName(rel_path: []const u8) ![]u8 {
    const ext = std.fs.path.extension(rel_path);
    const stem = rel_path[0 .. rel_path.len - ext.len];
    const name_part = if (std.mem.indexOfScalar(u8, stem, std.fs.path.sep)) |slash| stem[slash + 1 ..] else stem;
    var out = std.ArrayList(u8).empty;
    errdefer out.deinit(allocator);
    for (name_part) |c| {
        const mapped: u8 = switch (c) {
            'a'...'z' => c,
            'A'...'Z' => c + ('a' - 'A'),
            '0'...'9' => c,
            else => '_',
        };
        try out.append(allocator, mapped);
    }
    if (out.items.len > 0 and out.items[0] >= '0' and out.items[0] <= '9') try out.insert(allocator, 0, '_');
    return out.toOwnedSlice(allocator);
}

fn processAseprite(io: std.Io, bin: []const u8) !void {
    var dir = try std.Io.Dir.openDir(std.Io.Dir.cwd(), io, "assets_src/aseprite", .{ .iterate = true });
    defer dir.close(io);
    var walker = try std.Io.Dir.walkSelectively(dir, allocator);
    defer walker.deinit();
    while (try walker.next(io)) |entry| {
        if (entry.kind == .directory) {
            try walker.enter(io, entry);
            continue;
        }
        if (entry.kind != .file or !std.mem.eql(u8, std.fs.path.extension(entry.path), ".aseprite")) continue;
        const id = try assetIdName(entry.path);
        defer allocator.free(id);
        const png = try std.fmt.allocPrint(allocator, "assets/atlases/{s}.png", .{id});
        defer allocator.free(png);
        const json = try std.fmt.allocPrint(allocator, "assets/atlases/{s}.json", .{id});
        defer allocator.free(json);
        const src = try std.fs.path.join(allocator, &.{ "assets_src/aseprite", entry.path });
        defer allocator.free(src);
        const argv = [_][]const u8{ bin, "-b", src, "--sheet", png, "--data", json, "--format", "json-array", "--list-tags", "--list-slices", "--list-layers" };
        const result = try std.process.run(allocator, io, .{ .argv = &argv });
        defer allocator.free(result.stdout);
        defer allocator.free(result.stderr);
        switch (result.term) {
            .exited => |code| if (code != 0) {
                std.debug.print("Aseprite failed ({d}): {s}\n", .{ code, result.stderr });
                return error.AsepriteFailed;
            },
            else => return error.AsepriteFailed,
        }
    }
}

pub fn main(init: std.process.Init) !void {
    var args = std.process.Args.Iterator.init(init.minimal.args);
    defer args.deinit();
    _ = args.next();
    var command: []const u8 = "all";
    var bin: []const u8 = "/Applications/Aseprite.app/Contents/MacOS/aseprite";
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "maps")) command = "maps" else if (std.mem.eql(u8, arg, "aseprite")) command = "aseprite" else if (std.mem.eql(u8, arg, "validate")) command = "validate" else if (std.mem.startsWith(u8, arg, "--aseprite=")) bin = arg[11..];
    }
    if (std.mem.eql(u8, command, "validate")) return validateGenerated(init.io);
    if (std.mem.eql(u8, command, "all") or std.mem.eql(u8, command, "maps")) try processMaps(init.io);
    if (std.mem.eql(u8, command, "all") or std.mem.eql(u8, command, "aseprite")) try processAseprite(init.io, bin);
}
