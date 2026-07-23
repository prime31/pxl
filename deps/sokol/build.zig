const std = @import("std");
const Build = std.Build;

pub const sokol = @import("sokol");
pub const shdc = sokol.shdc;
pub const cimgui = @import("cimgui");

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const opt_imgui = b.option(bool, "imgui", "Build with Dear ImGui support") orelse true;
    const opt_docking = b.option(bool, "docking", "Build with docking support") orelse true;

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
        .with_sokol_imgui = opt_imgui,
    });
    const dep_cimgui = b.dependency("cimgui", .{
        .target = target,
        .optimize = optimize,
    });
    const sokol_clib = dep_sokol.artifact("sokol_clib");

    // Get the matching Zig module name, C header search path and C library for vanilla imgui vs the imgui docking branch.
    const cimgui_conf = cimgui.getConfig(opt_docking);

    if (opt_imgui) {
        // inject the cimgui header search path into the sokol C library compile step
        sokol_clib.root_module.addIncludePath(dep_cimgui.path(cimgui_conf.include_dir));
    }

    try b.modules.put(b.allocator, "cimgui", dep_cimgui.module(cimgui_conf.module_name));
    try b.modules.put(b.allocator, "sokol", dep_sokol.module("sokol"));

    // add an emsdk install step
    const emsdk_install_step = sokol.emSdkInstallStep(b, dep_sokol.builder.dependency("emsdk", .{}), .{});
    b.step("install-emsdk-fuckoff", "Install Emscripten SDK in zig-pkg").dependOn(emsdk_install_step);

    // sokol_gp aka painter
    {
        const painter_mod = b.addModule("painter", .{
            .root_source_file = b.path("painter.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });

        const painter_lib = b.addLibrary(.{
            .name = "painter_clib",
            .root_module = painter_mod,
        });

        painter_lib.root_module.addCSourceFiles(.{
            .files = &.{"src/sokol_gp.c"},
            .flags = &.{ "-O3", "-std=c99", "-fno-sanitize=undefined", "-D=IMPL", "-ObjC", resolveSokolBackend(target.result) },
        });

        painter_mod.addIncludePath(sokol_clib.getEmittedIncludeTree());

        const painter_translate_c = b.addTranslateC(.{
            .root_source_file = b.path("src/sokol_gp.c"),
            .target = target,
            .optimize = optimize,
        });
        painter_translate_c.addIncludePath(sokol_clib.getEmittedIncludeTree());
        painter_mod.addImport("c", painter_translate_c.createModule());
        painter_mod.addImport("sokol", dep_sokol.module("sokol"));

        b.installArtifact(painter_lib);
        try b.modules.put(b.allocator, "painter", painter_mod);
    }

    // microui
    {
        const microui_mod = b.addModule("microui", .{
            .root_source_file = b.path("microui.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });

        const microui_lib = b.addLibrary(.{
            .name = "microui_clib",
            .root_module = microui_mod,
        });

        microui_lib.root_module.addCSourceFiles(.{
            .files = &.{ "src/microui.c", "src/microui_renderer.c" },
            .flags = &.{ "-O3", "-std=c99", "-fno-sanitize=undefined", "-ObjC", resolveSokolBackend(target.result) },
        });

        microui_mod.addIncludePath(sokol_clib.getEmittedIncludeTree());
        microui_mod.addImport("sokol", dep_sokol.module("sokol"));

        b.installArtifact(microui_lib);
        try b.modules.put(b.allocator, "microui", microui_mod);
    }
}

fn resolveSokolBackend(target: std.Target) []const u8 {
    const sokol_backend = sokol.resolveSokolBackend(.auto, target);
    return switch (sokol_backend) {
        .d3d11 => "-DSOKOL_D3D11",
        .metal => "-DSOKOL_METAL",
        .gl => "-DSOKOL_GLCORE",
        .gles3 => "-DSOKOL_GLES3",
        .wgpu => "-DSOKOL_WGPU",
        .vulkan => "-DSOKOL_VULKAN",
        else => @panic("unknown sokol backend"),
    };
}
