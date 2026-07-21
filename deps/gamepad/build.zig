const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const gamepad_mod = b.addModule("gamepad", .{
        .root_source_file = b.path(if (target.result.os.tag == .emscripten) "gamepad_wasm.zig" else "gamepad.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    if (target.result.os.tag == .emscripten) return;

    const gamepad_lib = b.addLibrary(.{
        .name = "gamepad_clib",
        .root_module = gamepad_mod,
    });

    gamepad_lib.root_module.addCSourceFiles(.{
        .files = &.{"src/sokol_gamepad.c"},
        .flags = &.{ "-O3", "-std=c99", "-fno-sanitize=undefined", "-D=IMPL", "-ObjC" },
    });

    if (target.result.os.tag == .macos) {
        gamepad_lib.root_module.linkFramework("Foundation", .{});
        gamepad_lib.root_module.linkFramework("GameController", .{});
    }

    b.installArtifact(gamepad_lib);
}

// add to build.zig.zon
// .dependencies = .{
//     .gamepad = .{
//         .path = "deps/gamepad",
//     },
// },

// build.zig
// const dep_gamepad = b.dependency("gamepad", .{});

// const mod = b.createModule(.{
//     ...
//     .imports = &.{
//         .{ .name = "gamepad", .module = dep_gamepad.module("gamepad") },
//     },
// });

// is this necessary?
// mod.linkLibrary(dep_gamepad.artifact("gamepad_clib"));
