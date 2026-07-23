const std = @import("std");
const pxl = @import("pxl");
const sgp = pxl.sgp;
const LDtk = pxl.util.LDtk;
const Texture = pxl.gpu.Texture;

var map: LDtk = undefined;
var textures: std.AutoHashMap(i64, Texture) = undefined;

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        .render = render,
    });
}

fn setup() !void {
    textures = std.AutoHashMap(i64, Texture).init(pxl.mem.allocator);

    map = try LDtk.parse(try pxl.fs.read("examples/assets/ldtk.ldtk", .persistent));
    if (map.root.defs) |defs| {
        for (defs.tilesets) |tileset| {
            if (tileset.relPath) |rel_path| {
                const path = try std.mem.concatWithSentinel(pxl.mem.scratch, u8, &.{ "examples/assets/", rel_path }, 0);
                const tex = try Texture.initFromFile(path);
                try textures.put(tileset.uid, tex);
            } else if (tileset.embedAtlas) |atlas| {
                if (atlas == .LdtkIcons) {
                    const tex = try Texture.initFromFile("examples/assets/ldtk_icons.png");
                    try textures.put(tileset.uid, tex);
                }
            }
        }
    }
}

fn render() !void {
    pxl.beginPass(.{ .action = .clear });
    sgp.reset_project();
    sgp.setBlendMode(.blend);

    for (map.root.levels) |level| renderLevel(level);

    pxl.endPass();
}

fn shutdown() !void {
    map.deinit();
    textures.deinit();
}

/// Main level rendering routine
pub fn renderLevel(level: LDtk.Level) void {
    const layer_instances = level.layerInstances orelse return;

    // LDtk stores layers top-to-bottom (index 0 is the top-most layer).
    // Loop backwards to draw bottom layers first (back-to-front rendering).
    var i: usize = layer_instances.len;
    while (i > 0) {
        i -= 1;
        const layer = layer_instances[i];

        // Skip hidden layers
        if (!layer.visible) continue;

        // Calculate world-space offsets for this layer
        const layer_x: f32 = @floatFromInt(level.worldX + layer.__pxTotalOffsetX);
        const layer_y: f32 = @floatFromInt(level.worldY + layer.__pxTotalOffsetY);

        switch (layer.__type) {
            .Entities => {
                std.debug.print("---------- entities\n", .{});
                renderEntities(layer, layer_x, layer_y);
            },
            .Tiles, .AutoLayer, .IntGrid => {
                const grid_size: f32 = @floatFromInt(layer.__gridSize);
                // Resolve active tileset UID (override instance UID takes precedence if set)
                const tileset_uid = layer.overrideTilesetUid orelse layer.__tilesetDefUid orelse continue;
                const tex = textures.get(tileset_uid) orelse continue;
                sgp.set_image(0, tex.img);

                const opacity: f32 = @floatCast(layer.__opacity);

                for (layer.gridTiles) |tile| {
                    sgp.set_color(1.0, 1.0, 1.0, opacity * @as(f32, @floatCast(tile.a)));
                    drawTile(tile, grid_size, layer_x, layer_y);
                }
                for (layer.autoLayerTiles) |tile| {
                    sgp.set_color(1.0, 1.0, 1.0, opacity * @as(f32, @floatCast(tile.a)));
                    drawTile(tile, grid_size, layer_x, layer_y);
                }
            },
        }
    }
}

/// Renders an individual tile instance
fn drawTile(tile: LDtk.TileInstance, grid_size: f32, layer_x: f32, layer_y: f32) void {
    // Destination rectangle on screen/world
    const dest_rect = sgp.sgp_rect{
        .x = layer_x + @as(f32, @floatFromInt(tile.px[0])),
        .y = layer_y + @as(f32, @floatFromInt(tile.px[1])),
        .w = grid_size,
        .h = grid_size,
    };

    // Source coordinates in the tileset atlas
    var src_x: f32 = @floatFromInt(tile.src[0]);
    var src_y: f32 = @floatFromInt(tile.src[1]);
    var src_w: f32 = grid_size;
    var src_h: f32 = grid_size;

    // Handle horizontal / vertical flip bits using negative dimensions
    if (tile.isFlippedX()) {
        src_x += src_w;
        src_w = -src_w;
    }

    if (tile.isFlippedY()) {
        src_y += src_h;
        src_h = -src_h;
    }

    const src_rect = sgp.sgp_rect{
        .x = src_x,
        .y = src_y,
        .w = src_w,
        .h = src_h,
    };

    sgp.draw_textured_rect(0, dest_rect, src_rect);
}

/// Render all entities in an Entity layer
pub fn renderEntities(layer: LDtk.LayerInstance, layer_x: f32, layer_y: f32) void {
    if (layer.__type != .Entities) return;

    for (layer.entityInstances) |entity| {
        renderEntity(entity, layer_x, layer_y);
    }
}

/// Render a single entity instance
pub fn renderEntity(entity: LDtk.EntityInstance, layer_x: f32, layer_y: f32) void {
    const width: f32 = @floatFromInt(entity.width);
    const height: f32 = @floatFromInt(entity.height);
    const pivot_x: f32 = @floatCast(entity.__pivot[0]);
    const pivot_y: f32 = @floatCast(entity.__pivot[1]);

    // Calculate top-left world-space position based on pivot
    const x: f32 = layer_x + @as(f32, @floatFromInt(entity.px[0])) - (pivot_x * width);
    const y: f32 = layer_y + @as(f32, @floatFromInt(entity.px[1])) - (pivot_y * height);

    // 1. Draw entity Tile if present
    if (entity.__tile) |tile| {
        const tex = textures.get(tile.tilesetUid) orelse return;
        sgp.set_image(0, tex.img);

        const dest_rect = sgp.sgp_rect{
            .x = x,
            .y = y,
            .w = width,
            .h = height,
        };

        const src_rect = sgp.sgp_rect{
            .x = @floatFromInt(tile.x),
            .y = @floatFromInt(tile.y),
            .w = @floatFromInt(tile.w),
            .h = @floatFromInt(tile.h),
        };

        // Reset tint color to white for entity graphics
        sgp.set_color(1.0, 1.0, 1.0, 1.0);
        sgp.draw_textured_rect(0, dest_rect, src_rect);
    } else {
        // 2. Fallback / Debug: Draw a colored rectangle using __smartColor
        const color = parseHexColor(entity.__smartColor);
        sgp.set_color(color[0], color[1], color[2], 0.6);

        // If you have a solid fill function in your renderer:
        sgp.draw_filled_rect(x, y, width, height);
    }
}

/// Converts LDtk hex color strings (e.g. "#FF0055" or "FF0055") to normalized RGBA [0.0 - 1.0]
fn parseHexColor(hex_str: []const u8) [4]f32 {
    var src = hex_str;
    if (src.len > 0 and src[0] == '#') {
        src = src[1..];
    }
    if (src.len < 6) return .{ 1.0, 0.0, 1.0, 1.0 }; // Fallback magenta

    const r = std.fmt.parseInt(u8, src[0..2], 16) catch 255;
    const g = std.fmt.parseInt(u8, src[2..4], 16) catch 0;
    const b = std.fmt.parseInt(u8, src[4..6], 16) catch 255;

    return .{
        @as(f32, @floatFromInt(r)) / 255.0,
        @as(f32, @floatFromInt(g)) / 255.0,
        @as(f32, @floatFromInt(b)) / 255.0,
        1.0,
    };
}
