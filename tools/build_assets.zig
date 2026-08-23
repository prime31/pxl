const std = @import("std");
const Build = std.Build;

pub const AssetManifest = struct {
    zig_source: Build.LazyPath,
    c_header: Build.LazyPath,
};

const AssetKind = enum { texture, font, tilemap, audio };

const AssetEntry = struct {
    id_name: []const u8,
    kind: AssetKind,
    path: []const u8,
    atlas_path: ?[]const u8 = null,
};

/// The Aseprite CLI's `--data` output (json-array).
const AsepriteJson = struct {
    frames: []Frame,
    meta: Meta,

    const Frame = struct {
        frame: Rect,
        duration: u32,
        spriteSourceSize: ?Rect = null,
        sourceSize: ?Size = null,
        rotated: bool = false,
        trimmed: bool = false,
    };
    const Rect = struct { x: i32, y: i32, w: i32, h: i32 };
    const Size = struct { w: i32, h: i32 };
    const Meta = struct {
        size: Size,
        image: []const u8 = "",
        frameTags: ?[]Tag = null,
        slices: ?[]Slice = null,
        layers: ?[]Layer = null,
    };
    const Tag = struct { name: []const u8, from: u32, to: u32, direction: []const u8, color: ?[]const u8 = null };
    const Slice = struct { name: []const u8, keys: ?[]Key = null, color: ?[]const u8 = null };
    const Key = struct { frame: u32, bounds: Rect, pivot: ?Pivot = null };
    const Pivot = struct { x: f32, y: f32 };
    const Layer = struct { name: []const u8, opacity: ?u32 = null, blendMode: ?[]const u8 = null };
};

const AsepriteExport = struct {
    id_name: []const u8,
    parsed: std.json.Parsed(AsepriteJson),
};

fn requireGeneratedFile(b: *Build, path: []const u8) !void {
    if (std.Io.Dir.accessAbsolute(b.graph.io, b.pathFromRoot(path), .{})) |_| return else |_| {
        std.debug.print("pxl: generated asset '{s}' is missing; run `zig build assets`\n", .{path});
        return error.GeneratedAssetMissing;
    }
}

pub fn addValidationStep(b: *Build) !*Build.Step {
    const tool = b.addExecutable(.{
        .name = "pxl-asset-processor-validate",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/asset_processor.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const run = b.addRunArtifact(tool);
    run.setCwd(b.path("."));
    run.addArg("validate");
    return &run.step;
}

pub fn addPreparationStep(b: *Build) !void {
    const tool = b.addExecutable(.{
        .name = "pxl-asset-processor",
        .root_module = b.createModule(.{
            .root_source_file = b.path("tools/asset_processor.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const run = b.addRunArtifact(tool);
    run.setCwd(b.path("."));
    run.addArg("all");
    if (b.option([]const u8, "aseprite", "Path to the Aseprite CLI executable")) |path| {
        run.addArg(b.fmt("--aseprite={s}", .{path}));
    }
    try addSourceInputs(b, run);
    run.has_side_effects = true;
    b.step("assets", "Process LDtk and Aseprite source assets").dependOn(&run.step);
}

fn addSourceInputs(b: *Build, run: *Build.Step.Run) !void {
    const roots = [_][]const u8{ "assets_src/maps", "assets_src/aseprite" };
    for (roots) |root| {
        var dir = std.Io.Dir.openDir(std.Io.Dir.cwd(), b.graph.io, root, .{ .iterate = true }) catch |err| switch (err) {
            error.FileNotFound => continue,
            else => return err,
        };
        defer dir.close(b.graph.io);
        var walker = try std.Io.Dir.walkSelectively(dir, b.allocator);
        defer walker.deinit();
        while (try walker.next(b.graph.io)) |entry| {
            if (entry.kind == .directory) {
                try walker.enter(b.graph.io, entry);
                continue;
            }
            if (entry.kind != .file) continue;
            const ext = std.fs.path.extension(entry.path);
            if (!std.mem.eql(u8, ext, ".ldtk") and !std.mem.eql(u8, ext, ".aseprite")) continue;
            const path = try std.fs.path.join(b.allocator, &.{ root, entry.path });
            defer b.allocator.free(path);
            run.addFileInput(b.path(path));
        }
    }
}

pub fn addManifest(b: *Build) !AssetManifest {
    const exports = try loadAsepriteExports(b);
    defer {
        for (exports) |e| {
            e.parsed.deinit();
            b.allocator.free(e.id_name);
        }
        b.allocator.free(exports);
    }
    var entries = try collectAssetEntries(b, exports);
    defer entries.deinit(b.allocator);
    const zig_source = try generateAssetManifest(b, &entries, exports);
    const c_header = try generateAssetCHeader(b, &entries);
    const wf = b.addWriteFiles();
    _ = wf.addCopyDirectory(b.path("assets"), "assets", .{});
    return .{
        .zig_source = wf.add("asset_manifest.zig", zig_source),
        .c_header = wf.add("pxl_assets.h", c_header),
    };
}

fn assetIdName(b: *Build, rel_path: []const u8) ![]u8 {
    const ext = std.fs.path.extension(rel_path);
    const stem = rel_path[0 .. rel_path.len - ext.len];
    const name_part = if (std.mem.indexOfScalar(u8, stem, std.fs.path.sep)) |slash| stem[slash + 1 ..] else stem;
    var out = std.ArrayList(u8).empty;
    errdefer out.deinit(b.allocator);
    for (name_part) |c| {
        const mapped: u8 = switch (c) {
            'a'...'z' => c,
            'A'...'Z' => c + ('a' - 'A'),
            '0'...'9' => c,
            else => '_',
        };
        try out.append(b.allocator, mapped);
    }
    if (out.items.len > 0 and out.items[0] >= '0' and out.items[0] <= '9') try out.insert(b.allocator, 0, '_');
    return out.toOwnedSlice(b.allocator);
}

fn loadAsepriteExports(b: *Build) ![]AsepriteExport {
    const metadata_root = b.pathFromRoot("assets/atlases");
    var dir = std.Io.Dir.openDirAbsolute(b.graph.io, metadata_root, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return &.{},
        else => return err,
    };
    defer dir.close(b.graph.io);
    var walker = try std.Io.Dir.walkSelectively(dir, b.allocator);
    defer walker.deinit();
    var exports = std.ArrayList(AsepriteExport).empty;
    errdefer {
        for (exports.items) |e| {
            e.parsed.deinit();
            b.allocator.free(e.id_name);
        }
        exports.deinit(b.allocator);
    }
    while (try walker.next(b.graph.io)) |entry| {
        if (entry.kind == .directory) {
            try walker.enter(b.graph.io, entry);
            continue;
        }
        if (entry.kind != .file or !std.mem.eql(u8, std.fs.path.extension(entry.path), ".json")) continue;
        const path = try std.fs.path.join(b.allocator, &.{ metadata_root, entry.path });
        defer b.allocator.free(path);
        const bytes = try std.Io.Dir.readFileAlloc(std.Io.Dir.cwd(), b.graph.io, path, b.allocator, .unlimited);
        defer b.allocator.free(bytes);
        const parsed = try std.json.parseFromSlice(AsepriteJson, b.allocator, bytes, .{ .ignore_unknown_fields = true, .allocate = .alloc_always });
        const basename = std.fs.path.basename(entry.path);
        const stem = basename[0 .. basename.len - std.fs.path.extension(basename).len];
        try exports.append(b.allocator, .{ .id_name = b.dupe(stem), .parsed = parsed });
    }
    return exports.toOwnedSlice(b.allocator);
}

fn assetKind(rel_path: []const u8) ?AssetKind {
    const ext = std.fs.path.extension(rel_path);
    if (std.mem.eql(u8, ext, ".png")) return .texture;
    if (std.mem.eql(u8, ext, ".fnt")) return .font;
    if (std.mem.eql(u8, ext, ".pxlmap")) return .tilemap;
    if (std.mem.eql(u8, ext, ".ogg")) return .audio;
    return null;
}

fn containsPath(paths: []const []const u8, needle: []const u8) bool {
    for (paths) |p| if (std.mem.eql(u8, p, needle)) return true;
    return false;
}

fn isAsepriteExportPng(exports: []AsepriteExport, rel: []const u8) bool {
    if (!std.mem.eql(u8, std.fs.path.extension(rel), ".png")) return false;
    const basename = std.fs.path.basename(rel);
    const stem = basename[0 .. basename.len - std.fs.path.extension(basename).len];
    for (exports) |e| if (std.mem.eql(u8, e.id_name, stem)) return true;
    return false;
}

fn collectAssetEntries(b: *Build, exports: []AsepriteExport) !std.ArrayList(AssetEntry) {
    var rel_paths = std.ArrayList([]u8).empty;
    defer {
        for (rel_paths.items) |p| b.allocator.free(p);
        rel_paths.deinit(b.allocator);
    }
    const assets_abs = b.pathFromRoot("assets");
    var assets_dir = try std.Io.Dir.openDirAbsolute(b.graph.io, assets_abs, .{ .iterate = true });
    defer assets_dir.close(b.graph.io);
    var walker = try std.Io.Dir.walkSelectively(assets_dir, b.allocator);
    defer walker.deinit();
    while (try walker.next(b.graph.io)) |entry| {
        if (entry.kind == .directory) {
            try walker.enter(b.graph.io, entry);
            continue;
        }
        if (entry.kind != .file or std.mem.indexOfScalar(u8, entry.basename, '.') == 0) continue;
        if (std.mem.indexOfScalar(u8, entry.path, std.fs.path.sep) == null) {
            std.debug.print("pxl assets: '{s}' must live in a subfolder under assets/ (e.g. assets/textures/)\n", .{entry.path});
            return error.AssetNotInSubfolder;
        }
        const ext = std.fs.path.extension(entry.path);
        if (std.mem.eql(u8, ext, ".aseprite") or std.mem.eql(u8, ext, ".ldtk")) continue;
        if (assetKind(entry.path) == null) {
            if (!std.mem.eql(u8, ext, ".json"))
                std.debug.print("pxl assets: ignoring unsupported file 'assets/{s}'\n", .{entry.path});
            continue;
        }
        try rel_paths.append(b.allocator, b.dupe(entry.path));
    }

    var font_stems = std.ArrayList([]const u8).empty;
    defer {
        for (font_stems.items) |p| b.allocator.free(p);
        font_stems.deinit(b.allocator);
    }
    for (rel_paths.items) |rel| {
        const ext = std.fs.path.extension(rel);
        if (std.mem.eql(u8, ext, ".fnt")) try font_stems.append(b.allocator, b.dupe(rel[0 .. rel.len - ext.len]));
    }

    var entries = std.ArrayList(AssetEntry).empty;
    for (rel_paths.items) |rel| {
        const ext = std.fs.path.extension(rel);
        const stem = rel[0 .. rel.len - ext.len];
        if (std.mem.eql(u8, ext, ".png") and containsPath(font_stems.items, stem)) continue;
        if (isAsepriteExportPng(exports, rel)) continue;
        const kind = assetKind(rel).?;
        var entry = AssetEntry{ .id_name = try assetIdName(b, rel), .kind = kind, .path = b.fmt("assets/{s}", .{rel}) };
        if (kind == .font) entry.atlas_path = b.fmt("assets/{s}.png", .{stem});
        try entries.append(b.allocator, entry);
    }
    std.mem.sort(AssetEntry, entries.items, {}, struct {
        fn lt(_: void, a: AssetEntry, other: AssetEntry) bool {
            const ka = @intFromEnum(a.kind);
            const kb = @intFromEnum(other.kind);
            if (ka != kb) return ka < kb;
            return std.mem.lessThan(u8, a.id_name, other.id_name);
        }
    }.lt);
    for (entries.items, 0..) |a, i| {
        if (i == 0) continue;
        const prev = entries.items[i - 1];
        if (a.kind == prev.kind and std.mem.eql(u8, a.id_name, prev.id_name)) {
            std.debug.print("pxl assets: '{s}' and '{s}' both map to enum '{s}'\n", .{ prev.path, a.path, a.id_name });
            return error.AssetNameCollision;
        }
    }
    return entries;
}

fn generateAssetManifest(b: *Build, entries: *const std.ArrayList(AssetEntry), exports: []AsepriteExport) ![]const u8 {
    var src = std.ArrayList(u8).empty;
    errdefer src.deinit(b.allocator);
    try src.appendSlice(b.allocator,
        \\// GENERATED by build.zig - do not edit.
        \\const std = @import("std");
        \\const builtin = @import("builtin");
        \\
        \\pub const Meta = struct { name: []const u8, path: []const u8 };
        \\pub const FontMeta = struct { name: []const u8, path: []const u8, atlas_path: ?[]const u8 = null };
        \\
    );
    const kinds = [_]struct { kind: AssetKind, id_type: []const u8, array_name: []const u8, meta_type: []const u8 }{
        .{ .kind = .texture, .id_type = "TextureId", .array_name = "textures", .meta_type = "Meta" },
        .{ .kind = .font, .id_type = "FontId", .array_name = "fonts", .meta_type = "FontMeta" },
        .{ .kind = .tilemap, .id_type = "TilemapId", .array_name = "tilemaps", .meta_type = "Meta" },
        .{ .kind = .audio, .id_type = "AudioId", .array_name = "audio", .meta_type = "Meta" },
    };
    for (kinds) |k| {
        try src.appendSlice(b.allocator, b.fmt("pub const {s} = enum {{\n", .{k.id_type}));
        for (entries.items) |e| if (e.kind == k.kind) try src.appendSlice(b.allocator, b.fmt("    {s},\n", .{e.id_name}));
        try src.appendSlice(b.allocator, "};\n\n");
        try src.appendSlice(b.allocator, b.fmt("pub const {s} = [_]{s}{{\n", .{ k.array_name, k.meta_type }));
        for (entries.items) |e| if (e.kind == k.kind) {
            if (e.atlas_path) |atlas| try src.appendSlice(b.allocator, b.fmt("    .{{ .name = \"{s}\", .path = \"{s}\", .atlas_path = \"{s}\" }},\n", .{ e.id_name, e.path, atlas })) else try src.appendSlice(b.allocator, b.fmt("    .{{ .name = \"{s}\", .path = \"{s}\" }},\n", .{ e.id_name, e.path }));
        };
        try src.appendSlice(b.allocator, "};\n\n");
        try src.appendSlice(b.allocator, b.fmt("pub fn find{s}(path: []const u8) ?{s} {{\n", .{ k.id_type, k.id_type }));
        try src.appendSlice(b.allocator, b.fmt("    for ({s}, 0..) |m, i| {{\n        if (std.mem.eql(u8, m.path, path)) return @enumFromInt(i);\n    }}\n    return null;\n}}\n\n", .{k.array_name}));
    }

    const embed_fns = [_]struct { fn_name: []const u8, id_type: []const u8, kind: AssetKind, use_atlas: bool = false }{
        .{ .fn_name = "embedTexture", .id_type = "TextureId", .kind = .texture },
        .{ .fn_name = "embedFont", .id_type = "FontId", .kind = .font },
        .{ .fn_name = "embedFontAtlas", .id_type = "FontId", .kind = .font, .use_atlas = true },
        .{ .fn_name = "embedTilemap", .id_type = "TilemapId", .kind = .tilemap },
        .{ .fn_name = "embedAudio", .id_type = "AudioId", .kind = .audio },
    };
    for (embed_fns) |ef| {
        try src.appendSlice(b.allocator, b.fmt("pub fn {s}(id: {s}) []const u8 {{\n    if (builtin.target.cpu.arch.isWasm()) return switch (id) {{\n", .{ ef.fn_name, ef.id_type }));
        var count: usize = 0;
        for (entries.items) |e| {
            if (e.kind == ef.kind) count += 1;
        }
        if (count == 0) {
            try src.appendSlice(b.allocator, b.fmt("        @compileError(\\\"no {s} assets in manifest\\\");\\n", .{ef.id_type}));
        } else {
            for (entries.items) |e| {
                if (e.kind != ef.kind) continue;
                const path = if (ef.use_atlas) e.atlas_path.? else e.path;
                try src.appendSlice(b.allocator, b.fmt("        .{s} => @embedFile(\"{s}\"),\n", .{ e.id_name, path }));
            }
        }
        try src.appendSlice(b.allocator, "    };\n    unreachable;\n}\n\n");
    }
    try emitAseprite(&src, b, exports);
    return src.toOwnedSlice(b.allocator);
}

fn generateAssetCHeader(b: *Build, entries: *const std.ArrayList(AssetEntry)) ![]const u8 {
    var buf = std.ArrayList(u8).empty;
    try buf.appendSlice(b.allocator,
        \\// GENERATED by build.zig — do not edit.
        \\// pxl asset id constants. Include after pxl.h.
        \\#ifndef PXL_ASSETS_H
        \\#define PXL_ASSETS_H
        \\
    );
    const kinds = [_]struct { prefix: []const u8, kind: AssetKind }{
        .{ .prefix = "PXL_TEXTURE_", .kind = .texture }, .{ .prefix = "PXL_FONT_", .kind = .font },
        .{ .prefix = "PXL_TILEMAP_", .kind = .tilemap }, .{ .prefix = "PXL_AUDIO_", .kind = .audio },
    };
    for (kinds) |k| {
        var idx: u32 = 0;
        for (entries.items) |e| if (e.kind == k.kind) {
            var name_buf: [256]u8 = undefined;
            var j: usize = 0;
            for (e.id_name) |c| {
                if (j >= 250) break;
                name_buf[j] = if (c >= 'a' and c <= 'z') c - 32 else c;
                j += 1;
            }
            try buf.appendSlice(b.allocator, b.fmt("#define {s}{s} {d}\n", .{ k.prefix, name_buf[0..j], idx }));
            idx += 1;
        };
        try buf.appendSlice(b.allocator, "\n");
    }
    try buf.appendSlice(b.allocator, "#endif // PXL_ASSETS_H\n");
    return buf.toOwnedSlice(b.allocator);
}

const LoopSuffix = struct { base: []const u8, loop: bool };
fn stripLoopSuffix(name: []const u8) LoopSuffix {
    if (std.mem.endsWith(u8, name, "_loop")) return .{ .base = name[0 .. name.len - 5], .loop = true };
    return .{ .base = name, .loop = false };
}

fn asepriteDirection(dir: []const u8) []const u8 {
    if (std.mem.eql(u8, dir, "reverse")) return "reverse";
    if (std.mem.eql(u8, dir, "pingpong") or std.mem.eql(u8, dir, "ping-pong")) return "ping_pong";
    return "forward";
}

fn appendEscapedString(src: *std.ArrayList(u8), b: *Build, s: []const u8) !void {
    for (s) |c| switch (c) {
        '"' => try src.appendSlice(b.allocator, "\\\""),
        '\\' => try src.appendSlice(b.allocator, "\\\\"),
        else => try src.append(b.allocator, c),
    };
}

fn emitAseprite(src: *std.ArrayList(u8), b: *Build, exports: []AsepriteExport) !void {
    const TagEntry = struct { atlas_idx: u16, tag_idx: u16, name: []const u8, base: []const u8, loop: bool };
    var tags = std.ArrayList(TagEntry).empty;
    defer tags.deinit(b.allocator);
    for (exports, 0..) |e, ai| {
        const frame_tags = e.parsed.value.meta.frameTags orelse &.{};
        for (frame_tags, 0..) |t, ti| {
            const suffix = stripLoopSuffix(t.name);
            try tags.append(b.allocator, .{ .atlas_idx = @intCast(ai), .tag_idx = @intCast(ti), .name = t.name, .base = suffix.base, .loop = suffix.loop });
        }
    }
    for (tags.items, 0..) |t, i| {
        for (tags.items[0..i]) |prev| {
            if (t.atlas_idx == prev.atlas_idx and std.mem.eql(u8, t.base, prev.base)) {
                std.debug.print("pxl assets: tags '{s}' and '{s}' collide after stripping _loop\\n", .{ prev.name, t.name });
                return error.TagNameCollision;
            }
        }
    }

    try src.appendSlice(b.allocator, "pub const AsepriteId = enum(u32) {\n");
    if (exports.len == 0) try src.appendSlice(b.allocator, "    _,\n") else for (exports) |e| try src.appendSlice(b.allocator, b.fmt("    {s},\n", .{e.id_name}));
    try src.appendSlice(b.allocator, "};\n\n\npub const TagId = enum(u32) {\n");
    if (tags.items.len == 0) try src.appendSlice(b.allocator, "    _,\n") else for (tags.items) |t| try src.appendSlice(b.allocator, b.fmt("    {s}_{s},\n", .{ exports[t.atlas_idx].id_name, t.base }));
    try src.appendSlice(b.allocator, "};\n\n");
    try src.appendSlice(b.allocator,
        \\pub const AsepriteDirection = enum(u8) { forward, reverse, ping_pong };
        \\pub const AsepriteFrame = struct { x: u32, y: u32, w: u32, h: u32, duration: u32 };
        \\pub const AsepriteTag = struct { name: []const u8, from: u32, to: u32, direction: AsepriteDirection, loop: bool };
        \\pub const AsepriteSliceKey = struct { frame: u32, x: i32, y: i32, w: u32, h: u32, pivot_x: f32, pivot_y: f32, has_pivot: bool };
        \\pub const AsepriteSlice = struct { name: []const u8, keys: []const AsepriteSliceKey };
        \\pub const AsepriteMeta = struct { name: []const u8, path: []const u8, size_w: u32, size_h: u32, frames: []const AsepriteFrame, tags: []const AsepriteTag, slices: []const AsepriteSlice, layers: []const []const u8 };
        \\pub const TagInfo = struct { aseprite: AsepriteId, index: u16 };
        \\pub const tags = [_]TagInfo{
        \\
    );
    for (tags.items) |t| try src.appendSlice(b.allocator, b.fmt("    .{{ .aseprite = .{s}, .index = {d} }},\n", .{ exports[t.atlas_idx].id_name, t.tag_idx }));
    try src.appendSlice(b.allocator, "};\n\n");

    for (exports) |e| {
        const m = e.parsed.value.meta;
        try src.appendSlice(b.allocator, b.fmt("pub const {s}_meta = AsepriteMeta{{ .name = \"{s}\", .path = \"assets/atlases/{s}.png\", .size_w = {d}, .size_h = {d},\n", .{ e.id_name, e.id_name, e.id_name, m.size.w, m.size.h }));
        try src.appendSlice(b.allocator, "    .frames = &.{\n");
        for (e.parsed.value.frames) |f| try src.appendSlice(b.allocator, b.fmt("        .{{ .x = {d}, .y = {d}, .w = {d}, .h = {d}, .duration = {d} }},\n", .{ f.frame.x, f.frame.y, f.frame.w, f.frame.h, f.duration }));
        try src.appendSlice(b.allocator, "    },\n    .tags = &.{\n");
        const frame_tags = m.frameTags orelse &.{};
        for (frame_tags) |t| {
            const suffix = stripLoopSuffix(t.name);
            try src.appendSlice(b.allocator, "        .{ .name = \"");
            try appendEscapedString(src, b, suffix.base);
            try src.appendSlice(b.allocator, b.fmt("\", .from = {d}, .to = {d}, .direction = .{s}, .loop = {s} }},\n", .{ t.from, t.to, asepriteDirection(t.direction), if (suffix.loop) "true" else "false" }));
        }
        try src.appendSlice(b.allocator, "    },\n    .slices = &.{\n");
        const slices = m.slices orelse &.{};
        for (slices) |s| {
            try src.appendSlice(b.allocator, "        .{ .name = \"");
            try appendEscapedString(src, b, s.name);
            try src.appendSlice(b.allocator, "\", .keys = &.{");
            const keys = s.keys orelse &.{};
            for (keys) |k| {
                const px: f32 = if (k.pivot) |p| p.x else 0;
                const py: f32 = if (k.pivot) |p| p.y else 0;
                try src.appendSlice(b.allocator, b.fmt(" .{{ .frame = {d}, .x = {d}, .y = {d}, .w = {d}, .h = {d}, .pivot_x = {d}, .pivot_y = {d}, .has_pivot = {s} }},", .{ k.frame, k.bounds.x, k.bounds.y, k.bounds.w, k.bounds.h, px, py, if (k.pivot != null) "true" else "false" }));
            }
            try src.appendSlice(b.allocator, " } },\n");
        }
        try src.appendSlice(b.allocator, "    },\n    .layers = &.{");
        const layers = m.layers orelse &.{};
        for (layers) |l| {
            try src.appendSlice(b.allocator, " \"");
            try appendEscapedString(src, b, l.name);
            try src.appendSlice(b.allocator, "\",");
        }
        try src.appendSlice(b.allocator, " },\n};\n\n");
    }
    try src.appendSlice(b.allocator, "pub const aseprites = [_]*const AsepriteMeta{\n");
    for (exports) |e| try src.appendSlice(b.allocator, b.fmt("    &{s}_meta,\n", .{e.id_name}));
    try src.appendSlice(b.allocator, "};\n\npub fn asepriteMeta(id: AsepriteId) *const AsepriteMeta { return aseprites[@intFromEnum(id)]; }\n\n");
    try src.appendSlice(b.allocator, "pub fn embedAseprite(id: AsepriteId) []const u8 {\n    if (builtin.target.cpu.arch.isWasm()) return switch (id) {\n");
    if (exports.len == 0) try src.appendSlice(b.allocator, "        else => unreachable,\n") else for (exports) |e| try src.appendSlice(b.allocator, b.fmt("        .{s} => @embedFile(\"assets/atlases/{s}.png\"),\n", .{ e.id_name, e.id_name }));
    try src.appendSlice(b.allocator, "    };\n    unreachable;\n}\n\n");
}
