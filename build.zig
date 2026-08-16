const std = @import("std");
const Build = std.Build;
const OptimizeMode = std.builtin.OptimizeMode;
const ResolvedTarget = Build.ResolvedTarget;
const Dependency = Build.Dependency;

const stb = @import("stb");
const sokol_builder = @import("sokol_builder");
const sokol = sokol_builder.sokol;
const shdc = sokol.shdc;
const android_build = @import("android");

const examples = [_]Example{
    .{ .name = "check" },
    .{ .name = "web" },
    .{ .name = "audio" },
    .{ .name = "audio_manager" },
    .{ .name = "vorbis" },
    .{ .name = "text" },
    .{ .name = "animation" },
    .{ .name = "ldtk" },
    .{ .name = "lazr" },
    .{ .name = "slugcat" },
    .{ .name = "microui" },
    .{ .name = "shader", .has_shader = true },
    .{ .name = "bunnymark" },
    .{ .name = "batcher" },
    .{ .name = "pixel_art" },
    .{ .name = "particle_systems" },
    .{ .name = "trail" },
    .{ .name = "bloom" },
    .{ .name = "verlet" },
    .{ .name = "fabrik" },
    .{ .name = "gamepad" },
};

const shaders = struct {
    const engine_shader_dir = "shaders/";
    const engine_shader_output_dir = "shaders/bare";
    const engine_shaders = .{"all_shaders.glsl"};

    const examples_shader_dir = "";
    const examples_shader_output_dir = "";
    const examples_shaders = .{ "", "" };

    const slang = "metal_macos:glsl300es"; // glsl300es:glsl430:wgsl:metal_macos:hlsl4
};

const Example = struct {
    name: []const u8,
    has_shader: bool = false,
    needs_compute: bool = false,
};

const Options = struct {
    mod: *Build.Module,
    dep_sokol: *Build.Dependency,
};

const BuildWasmOptions = struct {
    mod_pxl: *Build.Module,
    dep_sokol: *Build.Dependency,
    opt_imgui: bool = false,
    dep_cimgui: *Build.Dependency,
    cimgui_clib_name: []const u8,
};

const AssetKind = enum { texture, font, tilemap, audio };

const AssetEntry = struct {
    id_name: []const u8,
    kind: AssetKind,
    path: []const u8,
    atlas_path: ?[]const u8 = null,
};

/// Generates the asset manifest source and returns the WriteFile-produced
/// LazyPath, with the whole assets/ tree copied next to it so `@embedFile`
/// inside the generated file can resolve "assets/..." paths.
fn addAssetManifest(b: *Build) !Build.LazyPath {
    const source = try generateAssetManifest(b);
    const wf = b.addWriteFiles();
    _ = wf.addCopyDirectory(b.path("assets"), "assets", .{});
    return wf.add("asset_manifest.zig", source);
}

fn assetKind(rel_path: []const u8) ?AssetKind {
    const ext = std.fs.path.extension(rel_path);
    if (std.mem.eql(u8, ext, ".png")) return .texture;
    if (std.mem.eql(u8, ext, ".fnt")) return .font;
    if (std.mem.eql(u8, ext, ".ldtk")) return .tilemap;
    if (std.mem.eql(u8, ext, ".ogg")) return .audio;
    return null;
}

/// `category/path/name.ext` -> `path_name` (the top-level folder is dropped,
/// deeper folders are joined with `_`; lowercased, non-alphanumerics become `_`).
fn assetIdName(b: *Build, rel_path: []const u8) ![]u8 {
    const ext = std.fs.path.extension(rel_path);
    const stem = rel_path[0 .. rel_path.len - ext.len];
    const name_part = if (std.mem.indexOfScalar(u8, stem, std.fs.path.sep)) |slash|
        stem[slash + 1 ..]
    else
        stem;

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
    if (out.items.len > 0 and out.items[0] >= '0' and out.items[0] <= '9')
        try out.insert(b.allocator, 0, '_');
    return out.toOwnedSlice(b.allocator);
}

fn containsPath(paths: []const []const u8, needle: []const u8) bool {
    for (paths) |p| if (std.mem.eql(u8, p, needle)) return true;
    return false;
}

fn generateAssetManifest(b: *Build) ![]const u8 {
    var rel_paths = std.ArrayList([]u8).empty;
    defer {
        for (rel_paths.items) |p| b.allocator.free(p);
        rel_paths.deinit(b.allocator);
    }

    // Recursively collect every supported file under assets/.
    const assets_abs = b.pathFromRoot("assets");
    var assets_dir = try std.Io.Dir.openDirAbsolute(b.graph.io, assets_abs, .{ .iterate = true });
    defer assets_dir.close(b.graph.io);
    var walker = try std.Io.Dir.walk(assets_dir, b.allocator);
    defer walker.deinit();
    while (try walker.next(b.graph.io)) |entry| {
        if (entry.kind != .file) continue;
        if (std.mem.indexOfScalar(u8, entry.path, std.fs.path.sep) == null) {
            std.debug.print("pxl assets: '{s}' must live in a subfolder under assets/ (e.g. assets/textures/)\n", .{entry.path});
            return error.AssetNotInSubfolder;
        }
        if (assetKind(entry.path) == null) {
            std.debug.print("pxl assets: ignoring unsupported file 'assets/{s}'\n", .{entry.path});
            continue;
        }
        try rel_paths.append(b.allocator, b.dupe(entry.path));
    }

    // A .png whose stem matches a .fnt sibling is that font's atlas, not a texture.
    var font_stems = std.ArrayList([]const u8).empty;
    defer {
        for (font_stems.items) |p| b.allocator.free(p);
        font_stems.deinit(b.allocator);
    }
    for (rel_paths.items) |rel| {
        const ext = std.fs.path.extension(rel);
        if (std.mem.eql(u8, ext, ".fnt"))
            try font_stems.append(b.allocator, b.dupe(rel[0 .. rel.len - ext.len]));
    }

    var entries = std.ArrayList(AssetEntry).empty;
    defer entries.deinit(b.allocator);
    for (rel_paths.items) |rel| {
        const ext = std.fs.path.extension(rel);
        const stem = rel[0 .. rel.len - ext.len];
        if (std.mem.eql(u8, ext, ".png") and containsPath(font_stems.items, stem)) continue;

        const kind = assetKind(rel).?;
        var entry = AssetEntry{
            .id_name = try assetIdName(b, rel),
            .kind = kind,
            .path = b.fmt("assets/{s}", .{rel}),
        };
        if (kind == .font) entry.atlas_path = b.fmt("assets/{s}.png", .{stem});
        try entries.append(b.allocator, entry);
    }

    // Deterministic order, grouped by kind; each enum and its metadata array
    // must stay in lockstep, so emit both from the same sorted list.
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

    var src = std.ArrayList(u8).empty;
    errdefer src.deinit(b.allocator);
    try src.appendSlice(b.allocator,
        \\// GENERATED by build.zig — do not edit.
        \\const std = @import("std");
        \\const builtin = @import("builtin");
        \\
        \\pub const Meta = struct {
        \\    name: []const u8,
        \\    path: []const u8,
        \\    atlas_path: ?[]const u8 = null,
        \\};
        \\
    );

    const kinds = [_]struct { kind: AssetKind, id_type: []const u8, array_name: []const u8 }{
        .{ .kind = .texture, .id_type = "TextureId", .array_name = "textures" },
        .{ .kind = .font, .id_type = "FontId", .array_name = "fonts" },
        .{ .kind = .tilemap, .id_type = "TilemapId", .array_name = "tilemaps" },
        .{ .kind = .audio, .id_type = "AudioId", .array_name = "audio" },
    };

    for (kinds) |k| {
        try src.appendSlice(b.allocator, b.fmt("pub const {s} = enum {{\n", .{k.id_type}));
        for (entries.items) |e| {
            if (e.kind != k.kind) continue;
            try src.appendSlice(b.allocator, b.fmt("    {s},\n", .{e.id_name}));
        }
        try src.appendSlice(b.allocator, "};\n\n");

        try src.appendSlice(b.allocator, b.fmt("pub const {s} = [_]Meta{{\n", .{k.array_name}));
        for (entries.items) |e| {
            if (e.kind != k.kind) continue;
            if (e.atlas_path) |atlas| {
                try src.appendSlice(b.allocator, b.fmt("    .{{ .name = \"{s}\", .path = \"{s}\", .atlas_path = \"{s}\" }},\n", .{ e.id_name, e.path, atlas }));
            } else {
                try src.appendSlice(b.allocator, b.fmt("    .{{ .name = \"{s}\", .path = \"{s}\" }},\n", .{ e.id_name, e.path }));
            }
        }
        try src.appendSlice(b.allocator, "};\n\n");

        try src.appendSlice(b.allocator, b.fmt("pub fn find{s}(path: []const u8) ?{s} {{\n", .{ k.id_type, k.id_type }));
        try src.appendSlice(b.allocator, b.fmt("    for ({s}, 0..) |m, i| {{\n", .{k.array_name}));
        try src.appendSlice(b.allocator,
            \\        if (std.mem.eql(u8, m.path, path)) return @enumFromInt(i);
            \\    }
            \\    return null;
            \\}
            \\
        );
    }

    try src.appendSlice(b.allocator,
        \\pub fn embedTexture(id: TextureId) []const u8 {
        \\    if (builtin.target.cpu.arch.isWasm()) {
        \\        return switch (id) {
        \\            inline else => |tag| @embedFile(textures[@intFromEnum(tag)].path),
        \\        };
        \\    }
        \\    unreachable;
        \\}
        \\
        \\pub fn embedFont(id: FontId) []const u8 {
        \\    if (builtin.target.cpu.arch.isWasm()) {
        \\        return switch (id) {
        \\            inline else => |tag| @embedFile(fonts[@intFromEnum(tag)].path),
        \\        };
        \\    }
        \\    unreachable;
        \\}
        \\
        \\pub fn embedFontAtlas(id: FontId) []const u8 {
        \\    if (builtin.target.cpu.arch.isWasm()) {
        \\        return switch (id) {
        \\            inline else => |tag| @embedFile(fonts[@intFromEnum(tag)].atlas_path.?),
        \\        };
        \\    }
        \\    unreachable;
        \\}
        \\
        \\pub fn embedTilemap(id: TilemapId) []const u8 {
        \\    if (builtin.target.cpu.arch.isWasm()) {
        \\        return switch (id) {
        \\            inline else => |tag| @embedFile(tilemaps[@intFromEnum(tag)].path),
        \\        };
        \\    }
        \\    unreachable;
        \\}
        \\
        \\pub fn embedAudio(id: AudioId) []const u8 {
        \\    if (builtin.target.cpu.arch.isWasm()) {
        \\        return switch (id) {
        \\            inline else => |tag| @embedFile(audio[@intFromEnum(tag)].path),
        \\        };
        \\    }
        \\    unreachable;
        \\}
        \\
    );
    return src.toOwnedSlice(b.allocator);
}

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Android check first — early return to keep the native/wasm path clean
    const android_targets = android_build.standardTargets(b, target);
    if (android_targets.len > 0) {
        try buildAndroid(b, optimize, android_targets, try addAssetManifest(b));
        return;
    }

    const assets_gen = try addAssetManifest(b);

    const opt_docking = b.option(bool, "docking", "Build with docking support") orelse true;
    const opt_imgui = b.option(bool, "imgui", "Build with Dear ImGui support") orelse false;

    // note that the sokol dependency is built with `.imgui = opt_imgui` which is sent to the actual sokol dep as `.with_sokol_imgui`
    const dep_sokol_builder = b.dependency("sokol_builder", .{
        .target = target,
        .optimize = optimize,
        .imgui = opt_imgui,
    });
    const dep_gamepad = b.dependency("gamepad", .{
        .target = target,
        .optimize = optimize,
    });
    const dep_stb = b.dependency("stb", .{
        .target = target,
        .optimize = optimize,
    });
    const dep_sokol = dep_sokol_builder.builder.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
        .with_sokol_imgui = opt_imgui,
    });

    if (target.result.os.tag == .emscripten) {
        // Zig has no sysroot for wasm32-emscripten; the C stdlib headers come
        // from the Emscripten SDK (already a dependency of sokol).
        const dep_emsdk = dep_sokol.builder.dependency("emsdk", .{});
        dep_stb.module("stb").addSystemIncludePath(dep_emsdk.path("upstream/emscripten/cache/sysroot/include"));
    }

    // for now add all shaders in one module
    const shader_zig_path = try compileShaderPath(b, dep_sokol, shaders.engine_shader_dir ++ shaders.engine_shaders[0]);
    const mod_shader = b.addModule("shader_module", .{ .root_source_file = shader_zig_path });
    mod_shader.addImport("sokol", dep_sokol.module("sokol"));

    const mod_pxl = b.addModule("pxl", .{
        .root_source_file = b.path("src/pxl.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "sokol", .module = dep_sokol.module("sokol") },
            .{ .name = "gamepad", .module = dep_gamepad.module("gamepad") },
            .{ .name = "stb", .module = dep_stb.module("stb") },
            .{ .name = "microui", .module = dep_sokol_builder.module("microui") },
            .{ .name = "shaders", .module = mod_shader },
        },
    });

    mod_shader.addImport("pxl", mod_pxl);
    mod_pxl.addImport("asset_manifest", b.createModule(.{ .root_source_file = assets_gen }));

    if (opt_imgui)
        mod_pxl.addImport("cimgui", dep_sokol_builder.module("cimgui"));

    const mod_options = b.addOptions();
    mod_options.addOption(bool, "imgui", opt_imgui);
    mod_options.addOption(bool, "docking", opt_docking);
    mod_pxl.addOptions("build_options", mod_options);

    if (target.result.cpu.arch.isWasm()) {
        // currently only builds base.zig
        try buildWeb(b, .{
            // .target = target,
            // .optimize = optimize,
            .mod_pxl = mod_pxl,
            // .dep = dep_sokol_builder,
            .dep_sokol = dep_sokol,
            .dep_cimgui = undefined,
            .cimgui_clib_name = undefined,
        });
    } else {
        try buildNative(b, .{
            .target = target,
            .optimize = optimize,
            .mod_pxl = mod_pxl,
            .dep_sokol = dep_sokol,
        });
    }

    // native unit tests for the pxl module (incl. tilemap SubpixelFloat)
    if (!target.result.cpu.arch.isWasm()) {
        const pxl_tests = b.addTest(.{ .root_module = mod_pxl });
        const test_step = b.step("test", "Run pxl unit tests");
        test_step.dependOn(&b.addRunArtifact(pxl_tests).step);
    }

    // add an emsdk install step
    const emsdk_install_step = sokol.emSdkInstallStep(b, dep_sokol.builder.dependency("emsdk", .{}), .{});
    b.step("install-emsdk", "Install Emscripten SDK in zig-pkg").dependOn(emsdk_install_step);
}

const ExeConfig = struct {
    target: ?std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    mod_pxl: *std.Build.Module,
    dep_sokol: *Dependency,
};

// this is the regular build for all native platforms, nothing surprising here
fn buildNative(b: *Build, opts: ExeConfig) !void {
    inline for (examples) |example| {
        const is_check = std.mem.eql(u8, example.name, "check");

        const mod_example = b.createModule(.{
            .root_source_file = b.path(try std.fmt.allocPrint(b.allocator, "examples/{s}.zig", .{example.name})),
            .target = opts.target,
            .optimize = opts.optimize,
            .imports = &.{
                .{ .name = "pxl", .module = opts.mod_pxl },
            },
        });

        const exe = b.addExecutable(.{
            .name = example.name,
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/entrypoint.zig"),
                .target = opts.target,
                .optimize = opts.optimize,
                .imports = &.{
                    .{ .name = "pxl", .module = opts.mod_pxl },
                    .{ .name = "app", .module = mod_example },
                },
            }),
        });

        // only install the artifact for non-check examples
        if (!is_check) {
            b.installArtifact(exe);

            const step_name = try std.fmt.allocPrint(b.allocator, "run {s}", .{example.name});
            b.step(example.name, step_name).dependOn(&b.addRunArtifact(exe).step);
        } else {
            const exe_check = b.addExecutable(.{
                .name = "check",
                .root_module = exe.root_module,
            });

            // add the "check" step which will be detected by ZLS and automatically enable Build-On-Save.
            const check = b.step("check", "Check if foo compiles");
            check.dependOn(&exe_check.step);
        }
    }
}

// for web builds, the Zig code needs to be built into a library and linked with the Emscripten linker
fn buildWeb(b: *Build, opts: BuildWasmOptions) !void {
    // get the Emscripten SDK dependency from the sokol dependency
    const dep_emsdk = opts.dep_sokol.builder.dependency("emsdk", .{});
    setupEmsdkPython(b, dep_emsdk);

    // need to inject the Emscripten system header include path into
    // the cimgui C library otherwise the C/C++ code won't find C stdlib headers
    if (opts.opt_imgui) {
        const emsdk_incl_path = dep_emsdk.path("upstream/emscripten/cache/sysroot/include");
        opts.dep_cimgui.artifact(opts.cimgui_clib_name).root_module.addSystemIncludePath(emsdk_incl_path);
    }

    const mod_app = b.createModule(.{
        .root_source_file = b.path("examples/web.zig"),
        .target = opts.mod_pxl.resolved_target,
        .optimize = opts.mod_pxl.optimize,
        .imports = &.{
            .{ .name = "pxl", .module = opts.mod_pxl },
        },
    });

    const mod_entry = b.createModule(.{
        .root_source_file = b.path("src/web_entrypoint.zig"),
        .target = opts.mod_pxl.resolved_target,
        .optimize = opts.mod_pxl.optimize,
        .imports = &.{
            .{ .name = "pxl", .module = opts.mod_pxl },
            .{ .name = "app", .module = mod_app },
        },
    });

    const lib = b.addLibrary(.{
        .name = "web",
        .root_module = mod_entry,
    });

    // create a build step which invokes the Emscripten linker
    const emsdk = opts.dep_sokol.builder.dependency("emsdk", .{});
    const link_step = try sokol.emLinkStep(b, .{
        .lib_main = lib,
        .target = opts.mod_pxl.resolved_target.?,
        .optimize = opts.mod_pxl.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });

    // attach Emscripten linker output to default install step
    b.getInstallStep().dependOn(&link_step.step);

    // ...and a special run step to start the web build output via 'emrun'
    const run = sokol.emRunStep(b, .{ .name = "web", .emsdk = emsdk });
    run.step.dependOn(&link_step.step);
    b.step("run", "Run web sample").dependOn(&run.step);
}

fn buildAndroid(b: *Build, optimize: OptimizeMode, android_targets: []ResolvedTarget, assets_gen: Build.LazyPath) !void {
    // Use the first android target's sokol to reach the shdc host binary.
    // shdc always runs on the host regardless of target arch.
    const first_target = android_targets[0];
    const dep_sb_for_shdc = b.dependency("sokol_builder", .{
        .target = first_target,
        .optimize = optimize,
        .imgui = false,
        .dont_link_system_libs = true,
    });

    // Compile shaders once — glsl300es output is target-agnostic (same source for all ABIs)
    const shader_zig_path = try compileShaderPath(
        b,
        dep_sb_for_shdc.builder.dependency("sokol", .{
            .target = first_target,
            .optimize = optimize,
            .with_sokol_imgui = false,
            .dont_link_system_libs = true,
        }),
        shaders.engine_shader_dir ++ shaders.engine_shaders[0],
    );

    const android_sdk = android_build.Sdk.create(b, .{});

    for (examples) |example| {
        if (std.mem.eql(u8, example.name, "check")) continue;

        const apk = android_sdk.createApk(.{
            .name = example.name,
            .api_level = .android15,
            // sokol-audio's Android backend is AAudio, which only exists on
            // API 26+. Without a min-sdk floor aapt2 defaults to 1 and the
            // APK installs on older devices, then crashes at load with
            // "cannot locate symbol AAudio_createStreamBuilder".
            .min_sdk_version = .android8,
            .build_tools_version = "35.0.1",
            .ndk_version = "30.0.15729638",
        });
        apk.setKeyStore(android_sdk.createKeyStore(.example));
        apk.setAndroidManifest(b.path("deps/android/AndroidManifest.xml"));
        apk.addResourceDirectory(b.path("deps/android/res"));
        // Bundle the source-tree asset folder into the APK so AAssetManager can read
        // textures/fonts. pxl.fs serves these reads on Android via the asset manager.
        apk.addAssetDirectory(b.path("assets"));

        for (android_targets) |android_target| {
            // Pass dont_link_system_libs through sokol_builder so all sokol module
            // instances for this target are consistent — prevents the "file in two modules" error.
            const dep_sb = b.dependency("sokol_builder", .{
                .target = android_target,
                .optimize = optimize,
                .imgui = false,
                .dont_link_system_libs = true,
            });
            const dep_gamepad = b.dependency("gamepad", .{
                .target = android_target,
                .optimize = optimize,
            });
            const dep_stb = b.dependency("stb", .{
                .target = android_target,
                .optimize = optimize,
            });

            // Each ABI gets its own shader module pointing to the same compiled source
            // but importing the right target's sokol module
            const mod_shader = b.createModule(.{ .root_source_file = shader_zig_path });
            mod_shader.addImport("sokol", dep_sb.module("sokol"));

            const mod_pxl = b.createModule(.{
                .root_source_file = b.path("src/pxl.zig"),
                .target = android_target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "sokol", .module = dep_sb.module("sokol") },
                    .{ .name = "gamepad", .module = dep_gamepad.module("gamepad") },
                    .{ .name = "stb", .module = dep_stb.module("stb") },
                    .{ .name = "microui", .module = dep_sb.module("microui") },
                    .{ .name = "shaders", .module = mod_shader },
                },
            });
            mod_shader.addImport("pxl", mod_pxl);
            mod_pxl.addImport("asset_manifest", b.createModule(.{ .root_source_file = assets_gen }));

            const mod_options = b.addOptions();
            mod_options.addOption(bool, "imgui", false);
            mod_options.addOption(bool, "docking", false);
            mod_pxl.addOptions("build_options", mod_options);

            const mod_example = b.createModule(.{
                .root_source_file = b.path(try std.fmt.allocPrint(b.allocator, "examples/{s}.zig", .{example.name})),
                .target = android_target,
                .optimize = optimize,
                .imports = &.{
                    .{ .name = "pxl", .module = mod_pxl },
                },
            });

            const lib = b.addLibrary(.{
                .name = "main",
                .linkage = .dynamic,
                .root_module = b.createModule(.{
                    .root_source_file = b.path("src/entrypoint.zig"),
                    .target = android_target,
                    .optimize = optimize,
                    .imports = &.{
                        .{ .name = "pxl", .module = mod_pxl },
                        .{ .name = "app", .module = mod_example },
                    },
                }),
            });

            // Link Android system libraries on the final .so (not in the intermediate
            // static sokol archive, which would cause LLD warnings about .so stubs).
            lib.root_module.linkSystemLibrary("GLESv3", .{});
            lib.root_module.linkSystemLibrary("EGL", .{});
            lib.root_module.linkSystemLibrary("android", .{});
            lib.root_module.linkSystemLibrary("log", .{});
            // sokol-audio's Android backend calls the AAudio API. Without this
            // link the symbols stay undefined in libmain.so and bionic can't
            // resolve them at dlopen ("cannot locate symbol
            // AAudio_createStreamBuilder") even on API 26+ devices — DT_NEEDED
            // libaaudio.so is what makes the linker load the platform library.
            lib.root_module.linkSystemLibrary("aaudio", .{});
            apk.addArtifact(lib);
        }

        const installed_apk = apk.addInstallApk();
        b.getInstallStep().dependOn(&installed_apk.step);

        const step_name = try std.fmt.allocPrint(b.allocator, "run-{s}", .{example.name});
        const step_desc = try std.fmt.allocPrint(b.allocator, "run {s}", .{example.name});

        const run_step = b.step(step_name, step_desc);
        const adb_install = android_sdk.addAdbInstall(installed_apk.source);
        const adb_start = android_sdk.addAdbStart("com.zigpxl.bunnymark/android.app.NativeActivity");
        adb_start.step.dependOn(&adb_install.step);
        run_step.dependOn(&adb_start.step);
    }
}

/// The emcc/emrun shell wrappers resolve python via $EMSDK_PYTHON (falling back
/// to PATH), but emscripten 6.x requires Python >= 3.10. Point them at the
/// Python that the emsdk installed and activated instead of whatever `python3`
/// happens to be on PATH.
fn setupEmsdkPython(b: *Build, dep_emsdk: *Build.Dependency) void {
    const config_path = dep_emsdk.path(".emscripten").getPath2(b, null);
    const root = std.fs.path.dirname(config_path) orelse return;
    var file = std.Io.Dir.openFileAbsolute(b.graph.io, config_path, .{}) catch return;
    defer file.close(b.graph.io);
    var reader = file.reader(b.graph.io, &.{});
    const config_bytes = reader.interface.allocRemainingAlignedSentinel(b.allocator, .unlimited, .of(u8), null) catch return;
    defer b.allocator.free(config_bytes);

    var it = std.mem.splitScalar(u8, config_bytes, '\n');
    while (it.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (!std.mem.startsWith(u8, trimmed, "PYTHON =")) continue;
        const start = std.mem.indexOfScalar(u8, trimmed, '\'') orelse continue;
        const end = std.mem.lastIndexOfScalar(u8, trimmed, '\'') orelse continue;
        if (start >= end) continue;
        const rel = std.mem.trim(u8, trimmed[start + 1 .. end], " \t");
        const python_path = b.fmt("{s}{s}", .{ root, rel }); // rel starts with '/'
        b.graph.environ_map.put("EMSDK_PYTHON", python_path) catch {};
        break;
    }
}

/// Compile shaders with shdc and return the LazyPath to the generated .zig file.
/// Emits both metal_macos (native) and glsl300es (Android/GLES3) backends.
fn compileShaderPath(b: *Build, dep_sokol: *Build.Dependency, shader_file: []const u8) !Build.LazyPath {
    const dep_shdc = dep_sokol.builder.dependency("shdc", .{});
    return shdc.compile(b, .{
        .shdc_dep = dep_shdc,
        .input = shader_file,
        .output = "shader.zig",
        .reflection = false,
        .bytecode = false,
        .no_log_cmdline = false,
        .slang = .{
            .metal_macos = true,
            .glsl300es = true,
        },
        .genver = b.fmt("{b}", .{std.Io.Clock.now(.awake, b.graph.io).toNanoseconds()}),
    });
}
