const std = @import("std");
const builtin = @import("builtin");
const fs = std.fs;
const pxl = @import("pxl.zig");
const mem = pxl.mem;
const Dir = std.Io.Dir;

/// On Android the bundled assets live inside the APK and must be read through
/// the AAssetManager, not the real filesystem. Engine code refers to them with
/// a source-tree-relative prefix (e.g. "assets/..."), and the APK build packs
/// the contents of that folder at the assets root, so we strip the prefix
/// before handing the name to the asset manager.
pub const android_asset_root = "assets/";

const AndroidAssetKit = struct {
    const AAsset = opaque {};
    const AAssetManager = opaque {};

    /// ANativeActivity from <android/native_activity.h>. We only need the
    /// assetManager member; the full field order must match the NDK header.
    const NativeActivity = extern struct {
        callbacks: *const anyopaque,
        vm: ?*anyopaque,
        env: ?*anyopaque,
        clazz: ?*anyopaque,
        internal_data_path: [*:0]const u8,
        external_data_path: [*:0]const u8,
        sdk_version: i32,
        instance: ?*anyopaque,
        asset_manager: ?*AAssetManager,
        obb_path: [*:0]const u8,
    };

    extern "android" fn AAssetManager_open(mgr: ?*AAssetManager, filename: [*:0]const u8, mode: c_int) ?*AAsset;
    extern "android" fn AAsset_getLength(asset: *AAsset) i64;
    extern "android" fn AAsset_read(asset: *AAsset, buf: [*]u8, count: usize) c_int;
    extern "android" fn AAsset_getBuffer(asset: *AAsset) ?*const anyopaque;
    extern "android" fn AAsset_close(asset: *AAsset) void;

    extern "log" fn __android_log_write(prio: c_int, tag: [*:0]const u8, text: [*:0]const u8) c_int;

    /// Log a diagnostic line to logcat (Android only) so asset-load failures
    /// are visible via `adb logcat` instead of failing silently.
    fn logErr(comptime fmt: []const u8, args: anytype) void {
        var buf: [512]u8 = undefined;
        const msg = std.fmt.bufPrintZ(&buf, fmt, args) catch return;
        _ = __android_log_write(6, "pxl", msg.ptr); // ANDROID_LOG_ERROR
    }

    fn getManager() ?*AAssetManager {
        const native_activity = pxl.sapp.androidGetNativeActivity() orelse {
            logErr("pxl.fs: sapp_android_get_native_activity() returned null; cannot read APK assets", .{});
            return null;
        };
        const activity: *const NativeActivity = @ptrCast(@alignCast(native_activity));
        return activity.asset_manager;
    }

    /// Map an engine-side relative path to an APK asset path.
    fn toAssetPath(path: []const u8) []const u8 {
        if (std.mem.startsWith(u8, path, android_asset_root)) {
            return path[android_asset_root.len..];
        }
        return path;
    }

    /// Read an APK asset into `allocator`. Returns null when the asset doesn't
    /// exist or can't be read (caller then falls back to the filesystem, which
    /// will fail for the same missing file — the log above pinpoints the cause).
    fn readAlloc(path: []const u8, allocator: std.mem.Allocator) ?[]u8 {
        const mgr = getManager() orelse return null;
        const asset_path = toAssetPath(path);

        // Zero-initialized so the byte at [len] is 0: the [0..len :0] sentinel
        // slice below does a runtime check that it is, and would otherwise hit
        // a "sentinel mismatch" panic on an undefined stack buffer.
        var path_buf: [std.posix.PATH_MAX]u8 = @splat(0);
        if (asset_path.len == 0 or asset_path.len >= path_buf.len) return null;
        @memcpy(path_buf[0..asset_path.len], asset_path);
        const path_z = path_buf[0..asset_path.len :0];

        const asset = AAssetManager_open(mgr, path_z.ptr, 3) orelse { // AASSET_MODE_BUFFER
            logErr("pxl.fs: APK asset not found: '{s}' (requested '{s}')", .{ asset_path, path });
            return null;
        };
        defer AAsset_close(asset);

        const len = AAsset_getLength(asset);
        if (len <= 0) {
            logErr("pxl.fs: APK asset is empty: '{s}'", .{asset_path});
            return null;
        }

        const buf = allocator.alloc(u8, @intCast(len)) catch return null;

        // AASSET_MODE_BUFFER guarantees a contiguous memory-mapped buffer, so
        // this is a single copy with no partial-read concerns.
        if (AAsset_getBuffer(asset)) |src| {
            const src_bytes: [*]const u8 = @ptrCast(src);
            @memcpy(buf, src_bytes[0..@intCast(len)]);
            return buf;
        }

        // Fallback for modes without a buffer: read in a loop.
        var total: usize = 0;
        const total_count: usize = @intCast(len);
        while (total < total_count) {
            const n = AAsset_read(asset, buf[total..].ptr, total_count - total);
            if (n <= 0) break;
            total += @intCast(n);
        }
        if (total == 0) {
            allocator.free(buf);
            logErr("pxl.fs: failed to read APK asset: '{s}'", .{asset_path});
            return null;
        }
        return buf[0..total];
    }
};

fn pickAllocator(allocation_type: mem.AllocationType) std.mem.Allocator {
    return if (allocation_type == .temp) mem.scratch else mem.allocator;
}

/// reads the contents of a file
pub fn read(filename: []const u8, allocation_type: mem.AllocationType) ![]u8 {
    if (builtin.target.abi.isAndroid()) {
        if (AndroidAssetKit.readAlloc(filename, pickAllocator(allocation_type))) |data| return data;
    }

    const file = try Dir.cwd().openFile(pxl.io, filename, .{});
    defer file.close(pxl.io);

    const allocator = pickAllocator(allocation_type);
    var file_reader = file.reader(pxl.io, &.{});
    return try file_reader.interface.allocRemainingAlignedSentinel(allocator, .unlimited, .of(u8), null);
}

pub fn readZ(filename: []const u8, allocation_type: mem.AllocationType) ![:0]u8 {
    if (builtin.target.abi.isAndroid()) {
        const allocator = pickAllocator(allocation_type);
        if (AndroidAssetKit.readAlloc(filename, allocator)) |data| {
            defer allocator.free(data);
            const buffer = allocator.alloc(u8, data.len + 1) catch unreachable;
            @memcpy(buffer[0..data.len], data);
            buffer[data.len] = 0;
            return buffer[0..data.len :0];
        }
    }

    const file = try Dir.cwd().openFile(pxl.io, filename, .{});
    defer file.close(pxl.io);

    const file_size = try file.getEndPos();
    var buffer = mem.alloc(u8, file_size + 1, allocation_type);
    _ = try file.read(buffer);
    buffer[file_size] = 0;

    return buffer[0..file_size :0];
}

pub fn write(filename: []const u8, data: []u8) !void {
    const file = try Dir.cwd().openFile(pxl.io, filename, .{ .write = true });
    defer file.close(pxl.io);

    // const file_size = try file.getEndPos();
    try file.writeAll(data);
}

/// gets a path to `filename` in the save games directory with the temp allocator
pub fn getSaveGamesFile(app: []const u8, filename: []const u8) ![]u8 {
    const dir = try std.fs.getAppDataDir(pxl.tmp_allocator, app);
    try std.fs.cwd().makePath(dir);
    return try std.fs.path.join(mem.scratch, &[_][]const u8{ dir, filename });
}

/// saves a serializable struct to disk
pub fn savePrefs(app: []const u8, filename: []const u8, data: anytype) !void {
    const file = try getSaveGamesFile(app, filename);
    var handle = try std.fs.cwd().createFile(file, .{});
    defer handle.close(pxl.io);

    var serializer = std.io.serializer(.Little, .Byte, handle.writer());
    try serializer.serialize(data);
}

pub fn readPrefs(comptime T: type, app: []const u8, filename: []const u8) !T {
    const file = try getSaveGamesFile(app, filename);
    var handle = try Dir.cwd().openFile(pxl.io, file, .{});
    defer handle.close(pxl.io);

    var deserializer = std.io.deserializer(.Little, .Byte, handle.reader());
    return deserializer.deserialize(T);
}

pub fn savePrefsJson(app: []const u8, filename: []const u8, data: anytype) !void {
    const file = try getSaveGamesFile(app, filename);
    var handle = try std.fs.cwd().createFile(file, .{});
    defer handle.close(pxl.io);

    try std.json.stringify(data, .{ .whitespace = .{} }, handle.writer());
}

pub fn readPrefsJson(comptime T: type, app: []const u8, filename: []const u8) !T {
    const file = try getSaveGamesFile(app, filename);
    const bytes = try pxl.fs.read(pxl.tmp_allocator, file);
    var tokens = std.json.TokenStream.init(bytes);

    const options = std.json.ParseOptions{ .allocator = pxl.allocator };
    return try std.json.parse(T, &tokens, options);
}

/// for prefs loaded with `readPrefsJson` that have allocated fields, this must be called to free them
pub fn freePrefsJson(data: anytype) void {
    const options = std.json.ParseOptions{ .allocator = pxl.allocator };
    std.json.parseFree(@TypeOf(data), data, options);
}

/// returns a slice of all the files with extension. The caller owns the slice AND each path in the slice.
pub fn getAllFilesOfType(allocator: std.mem.Allocator, root_directory: []const u8, extension: []const u8, recurse: bool) [][]const u8 {
    const recursor = struct {
        fn search(directory: []const u8, recursive: bool, filelist: *std.ArrayList([]const u8), ext: []const u8) void {
            var dir = fs.cwd().openIterableDir(directory, .{ .access_sub_paths = true }) catch unreachable;
            defer dir.close(pxl.io);

            var iter = dir.iterate();
            while (iter.next() catch unreachable) |entry| {
                if (entry.kind == .file) {
                    if (std.mem.endsWith(u8, entry.name, ext)) {
                        const abs_path = fs.path.join(filelist.allocator, &[_][]const u8{ directory, entry.name }) catch unreachable;
                        filelist.append(abs_path) catch unreachable;
                    }
                } else if (entry.kind == .directory) {
                    const abs_path = fs.path.join(pxl.tmp_allocator, &[_][]const u8{ directory, entry.name }) catch unreachable;
                    search(abs_path, recursive, filelist, ext);
                }
            }
        }
    }.search;

    var list = std.ArrayList([]const u8).init(allocator);
    recursor(root_directory, recurse, &list, extension);

    return list.toOwnedSlice() catch unreachable;
}
