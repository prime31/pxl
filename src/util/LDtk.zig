const std = @import("std");
const pxl = @import("../pxl.zig");

/// LDtk Project Parser
parsed_root: std.json.Parsed(Root),
root: Root,

/// Parse an entire LDtk project JSON file (.ldtk)
pub fn parse(ldtk_file_content: []const u8) !@This() {
    var parsed = try std.json.parseFromSlice(Root, pxl.mem.allocator, ldtk_file_content, .{
        .ignore_unknown_fields = true,
        .allocate = .alloc_always,
    });
    errdefer parsed.deinit();

    return .{
        .parsed_root = parsed,
        .root = parsed.value,
    };
}

/// Parse a standalone external level JSON file (.ldtkl)
pub fn parseLevel(level_file_content: []const u8) !std.json.Parsed(Level) {
    return try std.json.parseFromSlice(Level, pxl.mem.allocator, level_file_content, .{
        .ignore_unknown_fields = true,
        .allocate = .alloc_always,
    });
}

pub fn deinit(this: *@This()) void {
    this.parsed_root.deinit();
}

/// 1. LDtk JSON Root
pub const Root = struct {
    bgColor: []const u8,
    defs: ?Definitions = null,
    externalLevels: bool,
    iid: []const u8,
    jsonVersion: []const u8,
    levels: []Level = &.{},
    toc: []TableOfContentEntry = &.{},
    worldGridHeight: ?i64 = null,
    worldGridWidth: ?i64 = null,
    worldLayout: ?WorldLayout = null,
    worlds: []World = &.{},

    // Optional editor & project settings
    appBuildId: ?f64 = null,
    backupLimit: ?i64 = null,
    backupOnSave: ?bool = null,
    defaultGridSize: ?i64 = null,
    defaultLevelBgColor: ?[]const u8 = null,
    defaultLevelHeight: ?i64 = null,
    defaultLevelWidth: ?i64 = null,
    defaultPivotX: ?f64 = null,
    defaultPivotY: ?f64 = null,
    dummyWorldIid: ?[]const u8 = null,
    identifierStyle: ?[]const u8 = null,
    imageExportMode: ?[]const u8 = null,
    minified: ?bool = null,
    pngFilePattern: ?[]const u8 = null,
};

/// 1.1. World
pub const World = struct {
    identifier: []const u8,
    iid: []const u8,
    levels: []Level = &.{},
    worldGridHeight: i64,
    worldGridWidth: i64,
    worldLayout: ?WorldLayout = null,
};

pub const WorldLayout = enum {
    Free,
    GridVania,
    LinearHorizontal,
    LinearVertical,
};

/// 2. Level
pub const Level = struct {
    __bgColor: []const u8,
    __bgPos: ?LevelBgPos = null,
    __neighbours: []Neighbour = &.{},
    __smartColor: ?[]const u8 = null,
    bgColor: ?[]const u8 = null,
    bgPivotX: f64 = 0.5,
    bgPivotY: f64 = 0.5,
    bgPos: ?BgPosMode = null,
    bgRelPath: ?[]const u8 = null,
    externalRelPath: ?[]const u8 = null,
    fieldInstances: []FieldInstance = &.{},
    identifier: []const u8,
    iid: []const u8,
    /// Layer instances will be `null` in main .ldtk file when `externalLevels` is true
    layerInstances: ?[]LayerInstance = null,
    pxHei: i64,
    pxWid: i64,
    uid: i64,
    worldDepth: i64 = 0,
    worldX: i64 = 0,
    worldY: i64 = 0,
    toc: []TableOfContentEntry = &.{},
};

pub const LevelBgPos = struct {
    cropRect: [4]f64,
    scale: [2]f64,
    topLeftPx: [2]i64,
};

pub const BgPosMode = enum {
    Unscaled,
    Contain,
    Cover,
    CoverDirty,
    Repeat,
};

pub const Neighbour = struct {
    dir: []const u8,
    levelIid: []const u8,
    levelUid: ?i64 = null,
};

/// 2.1. Layer Instance
pub const LayerInstance = struct {
    __cHei: i64,
    __cWid: i64,
    __gridSize: i64,
    __identifier: []const u8,
    __opacity: f64,
    __pxTotalOffsetX: i64 = 0,
    __pxTotalOffsetY: i64 = 0,
    __tilesetDefUid: ?i64 = null,
    __tilesetRelPath: ?[]const u8 = null,
    __type: LayerType,
    __totalTilesCount: i64 = 0,
    autoLayerTiles: []TileInstance = &.{},
    entityInstances: []EntityInstance = &.{},
    gridTiles: []TileInstance = &.{},
    iid: []const u8,
    intGridCsv: []i64 = &.{},
    layerDefUid: i64,
    levelId: i64,
    overrideTilesetUid: ?i64 = null,
    pxOffsetX: i64 = 0,
    pxOffsetY: i64 = 0,
    pxTilesetOffsetX: i64 = 0,
    pxTilesetOffsetY: i64 = 0,
    visible: bool = true,
};

pub const LayerType = enum {
    IntGrid,
    Entities,
    Tiles,
    AutoLayer,
};

/// 2.2. Tile Instance
pub const TileInstance = struct {
    a: f64 = 1.0,
    f: i64,
    px: [2]i64,
    src: [2]i64,
    t: i64,
    d: ?[]i64 = null,

    pub fn isFlippedX(self: TileInstance) bool {
        return (self.f & 1) != 0;
    }

    pub fn isFlippedY(self: TileInstance) bool {
        return (self.f & 2) != 0;
    }
};

/// 2.3. Entity Instance
pub const EntityInstance = struct {
    __grid: [2]i64,
    __identifier: []const u8,
    __pivot: [2]f64,
    __smartColor: []const u8,
    __tags: [][]const u8 = &.{},
    __tile: ?TilesetRectangle = null,
    __worldX: ?i64 = null,
    __worldY: ?i64 = null,
    defUid: i64,
    fieldInstances: []FieldInstance = &.{},
    height: i64,
    iid: []const u8,
    px: [2]i64,
    width: i64,
};

/// 2.4. Field Instance
pub const FieldInstance = struct {
    __identifier: []const u8,
    __tile: ?TilesetRectangle = null,
    __type: []const u8,
    __value: std.json.Value,
    defUid: i64,
    realEditorValues: []std.json.Value = &.{},

    pub fn asInt(self: FieldInstance) ?i64 {
        return switch (self.__value) {
            .integer => |i| i,
            else => null,
        };
    }

    pub fn asFloat(self: FieldInstance) ?f64 {
        return switch (self.__value) {
            .float => |f| f,
            .integer => |i| @floatFromInt(i),
            else => null,
        };
    }

    pub fn asBool(self: FieldInstance) ?bool {
        return switch (self.__value) {
            .bool => |b| b,
            else => null,
        };
    }

    pub fn asString(self: FieldInstance) ?[]const u8 {
        return switch (self.__value) {
            .string => |s| s,
            else => null,
        };
    }
};

/// Table of Contents
pub const TableOfContentEntry = struct {
    identifier: []const u8,
    instancesData: []TocInstanceData = &.{},
};

pub const TocInstanceData = struct {
    fields: ?std.json.Value = null,
    heiPx: i64,
    iids: TocReference,
    widPx: i64,
    worldX: i64,
    worldY: i64,
};

pub const TocReference = struct {
    entityIid: []const u8,
    layerIid: []const u8,
    levelIid: []const u8,
    worldIid: []const u8,
};

/// 3. Definitions
pub const Definitions = struct {
    entities: []EntityDefinition = &.{},
    enums: []EnumDefinition = &.{},
    externalEnums: []EnumDefinition = &.{},
    layers: []LayerDefinition = &.{},
    levelFields: []FieldDefinition = &.{},
    tilesets: []TilesetDefinition = &.{},
};

/// 3.1. Layer Definition
pub const LayerDefinition = struct {
    __type: []const u8,
    autoSourceLayerDefUid: ?i64 = null,
    displayOpacity: f64 = 1.0,
    gridSize: i64,
    identifier: []const u8,
    intGridValues: []IntGridValueDefinition = &.{},
    parallaxFactorX: f64 = 0,
    parallaxFactorY: f64 = 0,
    parallaxScaling: bool = false,
    pxOffsetX: i64 = 0,
    pxOffsetY: i64 = 0,
    tilesetDefUid: ?i64 = null,
    uid: i64,
    autoTilesetDefUid: ?i64 = null,
};

pub const IntGridValueDefinition = struct {
    color: []const u8,
    groupUid: ?i64 = null,
    identifier: ?[]const u8 = null,
    tile: ?TilesetRectangle = null,
    value: i64,
};

/// 3.2. Entity Definition
pub const EntityDefinition = struct {
    color: []const u8,
    doc: ?[]const u8 = null,
    exportToToc: bool = false,
    fieldDefs: []FieldDefinition = &.{},
    fillOpacity: f64 = 0.0,
    height: i64,
    identifier: []const u8,
    keepAspectRatio: bool = false,
    limitBehavior: ?LimitBehavior = null,
    limitScope: ?LimitScope = null,
    lineOpacity: f64 = 0.0,
    maxCount: i64 = 0,
    nineSliceBorders: []i64 = &.{},
    pivotX: f64 = 0,
    pivotY: f64 = 0,
    resizableX: bool = false,
    resizableY: bool = false,
    showName: bool = false,
    tileOpacity: f64 = 1.0,
    tileRect: ?TilesetRectangle = null,
    tileRenderMode: ?TileRenderMode = null,
    tilesetId: ?i64 = null,
    uid: i64,
    width: i64,
    tileId: ?i64 = null,
};

pub const LimitBehavior = enum {
    DiscardOldOnes,
    PreventAdding,
    MoveLastOne,
};

pub const LimitScope = enum {
    PerLayer,
    PerLevel,
    PerWorld,
    PerProject,
};

pub const TileRenderMode = enum {
    Cover,
    FitInside,
    Repeat,
    Stretch,
    FullSizeCropped,
    FullSizeUncropped,
    NineSlice,
};

/// 3.2.1. Field Definition
pub const FieldDefinition = struct {
    __type: []const u8,
    acceptFileTypes: ?[]const u8 = null,
    arrayMaxLength: ?i64 = null,
    arrayMinLength: ?i64 = null,
    canBeNull: bool = true,
    defaultOverride: ?std.json.Value = null,
    editorAlwaysShow: bool = false,
    editorCutLongValues: bool = false,
    editorDisplayMode: ?[]const u8 = null,
    editorDisplayPos: ?[]const u8 = null,
    editorLinkTo: ?[]const u8 = null,
    editorShowInWorld: bool = false,
    elementMin: ?f64 = null,
    elementMax: ?f64 = null,
    identifier: []const u8,
    isArray: bool = false,
    type: []const u8,
    uid: i64,
    useForToc: bool = false,
};

/// 3.2.2. Tileset Rectangle
pub const TilesetRectangle = struct {
    tilesetUid: i64,
    w: i64,
    h: i64,
    x: i64,
    y: i64,
};

/// 3.3. Tileset Definition
pub const TilesetDefinition = struct {
    __cHei: i64,
    __cWid: i64,
    customData: []CustomData = &.{},
    embedAtlas: ?EmbedAtlas = null,
    enumTags: []EnumTag = &.{},
    identifier: []const u8,
    padding: i64 = 0,
    pxHei: i64,
    pxWid: i64,
    relPath: ?[]const u8 = null,
    spacing: i64 = 0,
    tags: [][]const u8 = &.{},
    tagsSourceEnumUid: ?i64 = null,
    tileGridSize: i64,
    uid: i64,
};

pub const CustomData = struct {
    data: []const u8,
    tileId: i64,
};

pub const EnumTag = struct {
    enumValueId: []const u8,
    tileIds: []i64 = &.{},
};

pub const EmbedAtlas = enum {
    LdtkIcons,
};

/// 3.4. Enum Definition
pub const EnumDefinition = struct {
    externalRelPath: ?[]const u8 = null,
    externalFileChecksum: ?[]const u8 = null,
    iconTilesetUid: ?i64 = null,
    identifier: []const u8,
    tags: [][]const u8 = &.{},
    uid: i64,
    values: []EnumValueDefinition = &.{},
};

/// 3.4.1. Enum Value Definition
pub const EnumValueDefinition = struct {
    color: i64 = 0,
    id: []const u8,
    tileRect: ?TilesetRectangle = null,
};
