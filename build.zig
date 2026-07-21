const std = @import("std");
const Build = std.Build;
const OptimizeMode = std.builtin.OptimizeMode;
const ResolvedTarget = Build.ResolvedTarget;
const Dependency = Build.Dependency;

const stb = @import("stb");
const sokol_builder = @import("sokol_builder");
const sokol = sokol_builder.sokol;
const shdc = sokol.shdc;

const examples = [_]Example{
    .{ .name = "check" },
    .{ .name = "base" },
    .{ .name = "empty", .has_shader = true },
    .{ .name = "bunnymark" },
};

const shaders = struct {
    const engine_shader_dir = "shaders/";
    const engine_shader_output_dir = "shaders/bare";
    const engine_shaders = .{"all_shaders.glsl"};

    const examples_shader_dir = "";
    const examples_shader_output_dir = "";
    const examples_shaders = .{ "", "" };

    const slang = "metal_macos"; // glsl300es:glsl430:wgsl:metal_macos:hlsl4
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
    mod_main: *Build.Module,
    dep_sokol: *Build.Dependency,
    opt_imgui: bool = false,
    dep_cimgui: *Build.Dependency,
    cimgui_clib_name: []const u8,
};

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

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
    const mod_sokol = dep_sokol.module("sokol");
    const mod_painter = dep_sokol_builder.module("painter");

    // for now add all shaders in one module
    const mod_shader = try compileShaderModule(b, dep_sokol, shaders.engine_shader_dir ++ shaders.engine_shaders[0]);

    const mod_pxl = b.addModule("pxl", .{
        .root_source_file = b.path("src/pxl.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "sokol", .module = mod_sokol },
            .{ .name = "gamepad", .module = dep_gamepad.module("gamepad") },
            .{ .name = "stb", .module = dep_stb.module("stb") },
            .{ .name = "painter", .module = mod_painter },
            .{ .name = "shaders", .module = mod_shader },
        },
    });

    // const mod_pacman = b.createModule(.{
    //     .root_source_file = b.path("src/pacman.zig"),
    //     .target = target,
    //     .optimize = optimize,
    //     .imports = &.{
    //         .{ .name = "sokol", .module = dep_sokol.module("sokol") },
    //         .{ .name = cimgui_conf.module_name, .module = dep_cimgui.module(cimgui_conf.module_name) },
    //         .{ .name = "shader", .module = try createShaderModule(b, dep_sokol) },
    //     },
    // });

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
            .mod_main = mod_pxl,
            // .dep = dep_sokol_builder,
            .dep_sokol = dep_sokol,
            .dep_cimgui = undefined,
            .cimgui_clib_name = undefined,
        });
    } else {
        try buildNative(b, .{
            .target = target,
            .optimize = optimize,
            .mod_gg = mod_pxl,
            .dep_sokol = dep_sokol,
        });
    }

    // special case handling for native vs web build
    // const opts = Options{ .mod = mod_pacman, .dep_sokol = dep_sokol };
    // if (target.result.cpu.arch.isWasm()) {
    //     try buildWeb(b, .{
    //         .mod_main = mod_pacman,
    //         .dep_sokol = dep_sokol,
    //         .dep_cimgui = dep_cimgui,
    //         .cimgui_clib_name = cimgui_conf.clib_name,
    //     });
    // } else {
    //     try buildNative(b, opts);
    // }

    // add an emsdk install step
    const emsdk_install_step = sokol.emSdkInstallStep(b, dep_sokol.builder.dependency("emsdk", .{}), .{});
    b.step("install-emsdk", "Install Emscripten SDK in zig-pkg").dependOn(emsdk_install_step);
}

const ExeConfig = struct {
    target: ?std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    mod_gg: *std.Build.Module,
    dep_sokol: *Dependency,
};

// this is the regular build for all native platforms, nothing surprising here
fn buildNative(b: *Build, opts: ExeConfig) !void {
    inline for (examples) |example| {
        const is_check = std.mem.eql(u8, example.name, "check");

        const exe = b.addExecutable(.{
            .name = example.name,
            .root_module = b.createModule(.{
                .root_source_file = b.path(try std.fmt.allocPrint(b.allocator, "examples/{s}.zig", .{example.name})),
                .target = opts.target,
                .optimize = opts.optimize,
                .imports = &.{
                    .{ .name = "gg", .module = opts.mod_gg },
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

    // need to inject the Emscripten system header include path into
    // the cimgui C library otherwise the C/C++ code won't find C stdlib headers
    if (opts.opt_imgui) {
        const emsdk_incl_path = dep_emsdk.path("upstream/emscripten/cache/sysroot/include");
        opts.dep_cimgui.artifact(opts.cimgui_clib_name).root_module.addSystemIncludePath(emsdk_incl_path);
    }

    const lib = b.addLibrary(.{
        .name = "pacman",
        .root_module = opts.mod_main,
    });

    // create a build step which invokes the Emscripten linker
    const emsdk = opts.dep_sokol.builder.dependency("emsdk", .{});
    const link_step = try sokol.emLinkStep(b, .{
        .lib_main = lib,
        .target = opts.mod_main.resolved_target.?,
        .optimize = opts.mod_main.optimize.?,
        .emsdk = emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .use_filesystem = true,
        .shell_file_path = opts.dep_sokol.path("src/sokol/web/shell.html"),
    });

    // attach Emscripten linker output to default install step
    b.getInstallStep().dependOn(&link_step.step);

    // ...and a special run step to start the web build output via 'emrun'
    const run = sokol.emRunStep(b, .{ .name = "pacman", .emsdk = emsdk });
    run.step.dependOn(&link_step.step);
    b.step("run", "Run pacman").dependOn(&run.step);
}

/// build shaders and compiles them into a module
fn compileShaderModule(b: *Build, dep_sokol: *Build.Dependency, shader_file: []const u8) !*Build.Module {
    const mod_sokol = dep_sokol.module("sokol");
    const dep_shdc = dep_sokol.builder.dependency("shdc", .{});

    return shdc.createModule(b, "shader_module", mod_sokol, .{
        .shdc_dep = dep_shdc,
        .input = shader_file,
        .output = "shader.zig",
        .reflection = false,
        .bytecode = false,
        .no_log_cmdline = false,
        .slang = .{
            .metal_macos = true,
            .hlsl5 = false,
        },
    });
}
