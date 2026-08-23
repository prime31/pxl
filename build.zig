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
const asset_build = @import("tools/build_assets.zig");

const examples = [_]Example{
    .{ .name = "check" },
    .{ .name = "web" },
    .{ .name = "audio" },
    .{ .name = "audio_manager" },
    .{ .name = "vorbis" },
    .{ .name = "text" },
    .{ .name = "animation" },
    .{ .name = "aseprite" },
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
    const engine_shaders = .{"all_shaders.glsl"};
};

const Example = struct {
    name: []const u8,
    has_shader: bool = false,
    needs_compute: bool = false,
};

const BuildWasmOptions = struct {
    mod_pxl: *Build.Module,
    dep_sokol: *Build.Dependency,
    opt_imgui: bool = false,
    dep_cimgui: *Build.Dependency,
    cimgui_clib_name: []const u8,
    prepared_asset_validation: *Build.Step,
};

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    try asset_build.addPreparationStep(b);
    const prepared_asset_validation = try asset_build.addValidationStep(b);

    // Android check first — early return to keep the native/wasm path clean.
    const android_targets = android_build.standardTargets(b, target);
    if (android_targets.len > 0) {
        const manifest = try asset_build.addManifest(b);
        try buildAndroid(b, optimize, android_targets, manifest.zig_source, prepared_asset_validation);
        return;
    }

    const manifest = try asset_build.addManifest(b);

    const opt_docking = b.option(bool, "docking", "Build with docking support") orelse true;
    const opt_imgui = b.option(bool, "imgui", "Build with Dear ImGui support") orelse false;

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
        const dep_emsdk = dep_sokol.builder.dependency("emsdk", .{});
        dep_stb.module("stb").addSystemIncludePath(dep_emsdk.path("upstream/emscripten/cache/sysroot/include"));
    }

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
    mod_pxl.addImport("asset_manifest", b.createModule(.{ .root_source_file = manifest.zig_source }));

    if (opt_imgui)
        mod_pxl.addImport("cimgui", dep_sokol_builder.module("cimgui"));

    const mod_options = b.addOptions();
    mod_options.addOption(bool, "imgui", opt_imgui);
    mod_options.addOption(bool, "docking", opt_docking);
    mod_pxl.addOptions("build_options", mod_options);

    if (target.result.cpu.arch.isWasm()) {
        try buildWeb(b, .{
            .prepared_asset_validation = prepared_asset_validation,
            .mod_pxl = mod_pxl,
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
            .prepared_asset_validation = prepared_asset_validation,
        });
    }

    if (!target.result.cpu.arch.isWasm()) {
        const pxl_tests = b.addTest(.{ .root_module = mod_pxl });
        pxl_tests.step.dependOn(prepared_asset_validation);
        const test_step = b.step("test", "Run pxl unit tests");
        test_step.dependOn(&b.addRunArtifact(pxl_tests).step);

        const mod_c_root = b.createModule(.{
            .root_source_file = b.path("src/c_entrypoint.zig"),
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
        mod_c_root.addImport("asset_manifest", b.createModule(.{ .root_source_file = manifest.zig_source }));
        mod_c_root.addImport("pxl", mod_pxl);

        const mod_c_options = b.addOptions();
        mod_c_options.addOption(bool, "imgui", opt_imgui);
        mod_c_options.addOption(bool, "docking", opt_docking);
        mod_c_root.addOptions("build_options", mod_c_options);
        if (opt_imgui)
            mod_c_root.addImport("cimgui", dep_sokol_builder.module("cimgui"));

        const lib = b.addLibrary(.{
            .linkage = .static,
            .name = "pxl",
            .root_module = mod_c_root,
        });
        lib.bundle_compiler_rt = true;
        dep_sokol.artifact("sokol_clib").root_module.sanitize_c = .off;
        const install_lib = b.addInstallArtifact(lib, .{});
        const install_sokol = b.addInstallArtifact(dep_sokol.artifact("sokol_clib"), .{});
        const install_h = b.addInstallFile(b.path("pxl.h"), "include/pxl.h");
        const install_assets_h = b.addInstallFile(manifest.c_header, "include/pxl_assets.h");

        const lib_step = b.step("lib", "Build libpxl.a + C headers");
        lib_step.dependOn(prepared_asset_validation);
        lib_step.dependOn(&install_lib.step);
        lib_step.dependOn(&install_sokol.step);
        lib_step.dependOn(&install_h.step);
        lib_step.dependOn(&install_assets_h.step);
    }

    const emsdk_install_step = sokol.emSdkInstallStep(b, dep_sokol.builder.dependency("emsdk", .{}), .{});
    b.step("install-emsdk", "Install Emscripten SDK in zig-pkg").dependOn(emsdk_install_step);
}

const ExeConfig = struct {
    target: ?std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    mod_pxl: *std.Build.Module,
    dep_sokol: *Dependency,
    prepared_asset_validation: *Build.Step,
};

fn buildNative(b: *Build, opts: ExeConfig) !void {
    inline for (examples) |example| {
        const is_check = std.mem.eql(u8, example.name, "check");
        const mod_example = b.createModule(.{
            .root_source_file = b.path(try std.fmt.allocPrint(b.allocator, "examples/{s}.zig", .{example.name})),
            .target = opts.target,
            .optimize = opts.optimize,
            .imports = &.{.{ .name = "pxl", .module = opts.mod_pxl }},
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
        exe.step.dependOn(opts.prepared_asset_validation);
        if (!is_check) {
            b.installArtifact(exe);
            const step_name = try std.fmt.allocPrint(b.allocator, "run {s}", .{example.name});
            b.step(example.name, step_name).dependOn(&b.addRunArtifact(exe).step);
        } else {
            const exe_check = b.addExecutable(.{ .name = "check", .root_module = exe.root_module });
            exe_check.step.dependOn(opts.prepared_asset_validation);
            const check = b.step("check", "Check if foo compiles");
            check.dependOn(&exe_check.step);
        }
    }
}

fn buildWeb(b: *Build, opts: BuildWasmOptions) !void {
    const dep_emsdk = opts.dep_sokol.builder.dependency("emsdk", .{});
    setupEmsdkPython(b, dep_emsdk);
    if (opts.opt_imgui) {
        const emsdk_incl_path = dep_emsdk.path("upstream/emscripten/cache/sysroot/include");
        opts.dep_cimgui.artifact(opts.cimgui_clib_name).root_module.addSystemIncludePath(emsdk_incl_path);
    }

    const mod_app = b.createModule(.{
        .root_source_file = b.path("examples/lazr.zig"),
        .target = opts.mod_pxl.resolved_target,
        .optimize = opts.mod_pxl.optimize,
        .imports = &.{.{ .name = "pxl", .module = opts.mod_pxl }},
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
    const lib = b.addLibrary(.{ .name = "web", .root_module = mod_entry });
    lib.step.dependOn(opts.prepared_asset_validation);

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
        .extra_args = &.{},
    });
    b.getInstallStep().dependOn(&link_step.step);
    const run = sokol.emRunStep(b, .{ .name = "web", .emsdk = emsdk });
    run.step.dependOn(&link_step.step);
    b.step("run", "Run web sample").dependOn(&run.step);
}

fn buildAndroid(b: *Build, optimize: OptimizeMode, android_targets: []ResolvedTarget, assets_gen: Build.LazyPath, prepared_asset_validation: *Build.Step) !void {
    const first_target = android_targets[0];
    const dep_sb_for_shdc = b.dependency("sokol_builder", .{
        .target = first_target,
        .optimize = optimize,
        .imgui = false,
        .dont_link_system_libs = true,
    });
    const shader_zig_path = try compileShaderPath(b, dep_sb_for_shdc.builder.dependency("sokol", .{
        .target = first_target,
        .optimize = optimize,
        .with_sokol_imgui = false,
        .dont_link_system_libs = true,
    }), shaders.engine_shader_dir ++ shaders.engine_shaders[0]);
    const android_sdk = android_build.Sdk.create(b, .{});

    for (examples) |example| {
        if (std.mem.eql(u8, example.name, "check")) continue;
        const apk = android_sdk.createApk(.{
            .name = example.name,
            .api_level = .android15,
            .min_sdk_version = .android8,
            .build_tools_version = "35.0.1",
            .ndk_version = "30.0.15729638",
        });
        apk.setKeyStore(android_sdk.createKeyStore(.example));
        apk.setAndroidManifest(b.path("deps/android/AndroidManifest.xml"));
        apk.addResourceDirectory(b.path("deps/android/res"));
        apk.addAssetDirectory(b.path("assets"));

        for (android_targets) |android_target| {
            const dep_sb = b.dependency("sokol_builder", .{
                .target = android_target,
                .optimize = optimize,
                .imgui = false,
                .dont_link_system_libs = true,
            });
            const dep_gamepad = b.dependency("gamepad", .{ .target = android_target, .optimize = optimize });
            const dep_stb = b.dependency("stb", .{ .target = android_target, .optimize = optimize });
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
                .imports = &.{.{ .name = "pxl", .module = mod_pxl }},
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
            lib.step.dependOn(prepared_asset_validation);
            lib.root_module.linkSystemLibrary("GLESv3", .{});
            lib.root_module.linkSystemLibrary("EGL", .{});
            lib.root_module.linkSystemLibrary("android", .{});
            lib.root_module.linkSystemLibrary("log", .{});
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
        b.graph.environ_map.put("EMSDK_PYTHON", b.fmt("{s}{s}", .{ root, rel })) catch {};
        break;
    }
}

fn compileShaderPath(b: *Build, dep_sokol: *Build.Dependency, shader_file: []const u8) !Build.LazyPath {
    const dep_shdc = dep_sokol.builder.dependency("shdc", .{});
    return shdc.compile(b, .{
        .shdc_dep = dep_shdc,
        .input = shader_file,
        .output = "shader.zig",
        .reflection = false,
        .bytecode = false,
        .no_log_cmdline = false,
        .slang = .{ .metal_macos = true, .glsl300es = true },
        .genver = b.fmt("{b}", .{std.Io.Clock.now(.awake, b.graph.io).toNanoseconds()}),
    });
}
