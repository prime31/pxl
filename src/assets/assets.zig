//! pxl.assets — a refcounted cache over the build-time generated asset manifest.
//!
//! Every file under `assets/` is enumerated at build time into one enum per
//! kind (`TextureId`, `FontId`, `TilemapId`, `AudioId`), so the type system
//! rejects loading a font as a texture. Loaders return stable pointers (or a
//! `SoundId` for audio) and can be called any number of times; each call bumps
//! a refcount. `destroy` releases one reference and frees the resource when
//! the last one is dropped.
//!
//! ```
//! const tex = try pxl.assets.loadTexture(.ferris_smol);
//! defer pxl.assets.destroy(tex);
//!
//! const music = try pxl.assets.loadAudio(.tester, .{ .streamed = true });
//! defer pxl.assets.destroy(music);
//! ```
//!
//! On wasm the bytes come from `@embedFile`; on desktop and Android they are
//! read through `pxl.fs` (which routes Android reads through AAssetManager).
//! Only the source-byte acquisition differs — GPU images, decoded audio and
//! parsed tilemaps are real allocations on every platform, so `destroy` runs
//! everywhere.

const std = @import("std");
const builtin = @import("builtin");
const pxl = @import("../pxl.zig");
const manifest = @import("asset_manifest");

pub const TextureId = manifest.TextureId;
pub const FontId = manifest.FontId;
pub const TilemapId = manifest.TilemapId;
pub const AudioId = manifest.AudioId;
pub const AtlasId = manifest.AtlasId;
pub const TagId = manifest.TagId;
pub const AsepriteMeta = manifest.AsepriteMeta;
pub const AtlasFrame = manifest.AtlasFrame;
pub const AtlasTag = manifest.AtlasTag;
pub const AtlasSlice = manifest.AtlasSlice;
pub const AtlasSliceKey = manifest.AtlasSliceKey;

pub const findTextureId = manifest.findTextureId;
pub const findFontId = manifest.findFontId;
pub const findTilemapId = manifest.findTilemapId;
pub const findAudioId = manifest.findAudioId;

const Texture = pxl.gpu.Texture;
const BMFont = pxl.text.BMFont;
const LDtk = pxl.tilemap.LDtk;
const SoundId = pxl.audio.SoundId;
const AnimationId = pxl.animation.AnimationId;
const Rect = pxl.math.Rect;

/// A loaded aseprite atlas: its texture plus the build-time generated metadata
/// (frames, tags, slices, layers). `meta` is static manifest data.
pub const Atlas = struct {
    texture: *Texture,
    meta: *const AsepriteMeta,
};

var textures: [manifest.textures.len]Texture = undefined;
var tex_refs: [manifest.textures.len]u32 = [1]u32{0} ** manifest.textures.len;
var fonts: [manifest.fonts.len]BMFont = undefined;
var font_refs: [manifest.fonts.len]u32 = [1]u32{0} ** manifest.fonts.len;
var tilemaps: [manifest.tilemaps.len]LDtk = undefined;
var tilemap_refs: [manifest.tilemaps.len]u32 = [1]u32{0} ** manifest.tilemaps.len;
var sounds: [manifest.audio.len]?SoundId = [1]?SoundId{null} ** manifest.audio.len;
var sound_refs: [manifest.audio.len]u32 = [1]u32{0} ** manifest.audio.len;
var atlas_textures: [manifest.atlases.len]Texture = undefined;
var atlas_refs: [manifest.atlases.len]u32 = [1]u32{0} ** manifest.atlases.len;
var tag_animations: [manifest.tags.len]AnimationId = [1]AnimationId{.none} ** manifest.tags.len;

pub fn loadTexture(id: TextureId) !*Texture {
    const i = @intFromEnum(id);
    if (tex_refs[i] > 0) {
        tex_refs[i] += 1;
        return &textures[i];
    }
    textures[i] = if (comptime builtin.target.cpu.arch.isWasm())
        try Texture.initFromMemory(manifest.embedTexture(id))
    else
        try Texture.initFromFile(pxl.mem.dupeZ(u8, manifest.textures[i].path, .temp));
    tex_refs[i] = 1;
    return &textures[i];
}

pub fn loadFont(id: FontId) !*BMFont {
    const i = @intFromEnum(id);
    if (font_refs[i] > 0) {
        font_refs[i] += 1;
        return &fonts[i];
    }
    fonts[i] = if (comptime builtin.target.cpu.arch.isWasm())
        try BMFont.initFromMemory(manifest.embedFont(id), manifest.embedFontAtlas(id))
    else
        try BMFont.initFromFile(manifest.fonts[i].path);
    font_refs[i] = 1;
    return &fonts[i];
}

pub fn loadTilemap(id: TilemapId) !*LDtk {
    const i = @intFromEnum(id);
    if (tilemap_refs[i] > 0) {
        tilemap_refs[i] += 1;
        return &tilemaps[i];
    }
    const bytes = if (comptime builtin.target.cpu.arch.isWasm())
        manifest.embedTilemap(id)
    else
        try pxl.fs.read(manifest.tilemaps[i].path, .temp);
    tilemaps[i] = try LDtk.parse(bytes);
    tilemap_refs[i] = 1;
    return &tilemaps[i];
}

pub fn loadAudio(id: AudioId, opts: pxl.audio.LoadOptions) !SoundId {
    const i = @intFromEnum(id);
    if (sound_refs[i] > 0) {
        sound_refs[i] += 1;
        return sounds[i].?;
    }
    const path = manifest.audio[i].path;
    const sid = if (comptime builtin.target.cpu.arch.isWasm())
        try pxl.audio.manager.loadFromMemory(path, manifest.embedAudio(id), opts)
    else
        try pxl.audio.load(path, opts);
    sounds[i] = sid;
    sound_refs[i] = 1;
    return sid;
}

pub fn loadAtlas(id: AtlasId) !Atlas {
    const i = @intFromEnum(id);
    if (atlas_refs[i] > 0) {
        atlas_refs[i] += 1;
    } else {
        atlas_textures[i] = if (comptime builtin.target.cpu.arch.isWasm())
            try Texture.initFromMemory(manifest.embedAtlas(id))
        else
            try Texture.initFromFile(pxl.mem.dupeZ(u8, manifest.atlasMeta(id).path, .temp));
        atlas_refs[i] = 1;
    }
    return .{ .texture = &atlas_textures[i], .meta = manifest.atlasMeta(id) };
}

/// Register one `pxl.animation.Animation` per tag in this atlas and remember
/// the mapping so `animation(tag_id)` returns stable ids. Frames are built into
/// the animation store's pool, so nothing needs freeing.
pub fn bindAnimations(id: AtlasId) !void {
    const atlas = try loadAtlas(id);
    for (atlas.meta.tags, 0..) |tag, ti| {
        const from: usize = @intCast(tag.from);
        const to: usize = @intCast(tag.to);
        const frames = pxl.animation.reserveFrames(to - from + 1);
        for (atlas.meta.frames[from .. to + 1], frames) |src, *dst| {
            dst.* = .{
                .texture = atlas.texture.*,
                .source = Rect.init(
                    @floatFromInt(src.x),
                    @floatFromInt(src.y),
                    @floatFromInt(src.w),
                    @floatFromInt(src.h),
                ),
                .duration = @as(f32, @floatFromInt(src.duration)) / 1000.0,
            };
        }
        const anim_id = pxl.animation.add(.{
            .name = tag.name,
            .frames = frames,
            .loop_mode = loopModeFrom(tag.direction, tag.loop),
        });
        tag_animations[tagIdIndex(id, @intCast(ti))] = anim_id;
    }
}

/// The runtime `AnimationId` registered for an aseprite tag.
pub fn animation(tag_id: TagId) AnimationId {
    return tag_animations[@intFromEnum(tag_id)];
}

fn loopModeFrom(dir: manifest.AsepriteDirection, loop: bool) pxl.animation.LoopMode {
    return switch (dir) {
        .forward => if (loop) .loop else .once,
        .reverse => if (loop) .reverse else .reverse_once,
        .ping_pong => if (loop) .ping_pong else .ping_pong_once,
    };
}

fn tagIdIndex(atlas_id: AtlasId, tag_idx: u16) usize {
    for (manifest.tags, 0..) |info, i| {
        if (info.atlas == atlas_id and info.index == tag_idx) return i;
    }
    unreachable;
}

/// Release one reference to an asset loaded through `pxl.assets`. The
/// resource is freed when its refcount reaches zero. Accepts a `*Texture`,
/// `*BMFont`, `*LDtk` or `pxl.audio.SoundId`.
pub fn destroy(resource: anytype) void {
    switch (@TypeOf(resource)) {
        *Texture => destroyTexture(resource),
        *BMFont => destroyFont(resource),
        *LDtk => destroyTilemap(resource),
        SoundId => destroyAudio(resource),
        else => @compileError("pxl.assets.destroy: unsupported type " ++ @typeName(@TypeOf(resource))),
    }
}

/// Frees every asset that is still referenced. Called by the engine during
/// shutdown after the user's shutdown callback has run.
pub fn deinit() void {
    var i: usize = 0;
    while (i < manifest.textures.len) : (i += 1) {
        if (tex_refs[i] > 0) {
            textures[i].deinit();
            tex_refs[i] = 0;
        }
    }
    i = 0;
    while (i < manifest.fonts.len) : (i += 1) {
        if (font_refs[i] > 0) {
            fonts[i].deinit();
            font_refs[i] = 0;
        }
    }
    i = 0;
    while (i < manifest.tilemaps.len) : (i += 1) {
        if (tilemap_refs[i] > 0) {
            tilemaps[i].deinit();
            tilemap_refs[i] = 0;
        }
    }
    i = 0;
    while (i < manifest.audio.len) : (i += 1) {
        if (sound_refs[i] > 0) {
            pxl.audio.unload(sounds[i].?);
            sounds[i] = null;
            sound_refs[i] = 0;
        }
    }
    i = 0;
    while (i < manifest.atlases.len) : (i += 1) {
        if (atlas_refs[i] > 0) {
            atlas_textures[i].deinit();
            atlas_refs[i] = 0;
        }
    }
}

fn destroyTexture(tex: *Texture) void {
    var i: usize = 0;
    while (i < manifest.textures.len) : (i += 1) {
        if (tex_refs[i] == 0) continue;
        if (&textures[i] == tex) {
            tex_refs[i] -= 1;
            if (tex_refs[i] == 0) textures[i].deinit();
            return;
        }
    }
    i = 0;
    while (i < manifest.atlases.len) : (i += 1) {
        if (atlas_refs[i] == 0) continue;
        if (&atlas_textures[i] == tex) {
            atlas_refs[i] -= 1;
            if (atlas_refs[i] == 0) atlas_textures[i].deinit();
            return;
        }
    }
    @panic("pxl.assets.destroy: texture was not loaded via pxl.assets");
}

fn destroyFont(font: *BMFont) void {
    var i: usize = 0;
    while (i < manifest.fonts.len) : (i += 1) {
        if (font_refs[i] == 0) continue;
        if (&fonts[i] == font) {
            font_refs[i] -= 1;
            if (font_refs[i] == 0) fonts[i].deinit();
            return;
        }
    }
    @panic("pxl.assets.destroy: font was not loaded via pxl.assets");
}

fn destroyTilemap(map: *LDtk) void {
    var i: usize = 0;
    while (i < manifest.tilemaps.len) : (i += 1) {
        if (tilemap_refs[i] == 0) continue;
        if (&tilemaps[i] == map) {
            tilemap_refs[i] -= 1;
            if (tilemap_refs[i] == 0) tilemaps[i].deinit();
            return;
        }
    }
    @panic("pxl.assets.destroy: tilemap was not loaded via pxl.assets");
}

fn destroyAudio(sid: SoundId) void {
    var i: usize = 0;
    while (i < manifest.audio.len) : (i += 1) {
        if (sound_refs[i] == 0) continue;
        if (sounds[i].? == sid) {
            sound_refs[i] -= 1;
            if (sound_refs[i] == 0) {
                pxl.audio.unload(sid);
                sounds[i] = null;
            }
            return;
        }
    }
    @panic("pxl.assets.destroy: sound was not loaded via pxl.assets");
}
