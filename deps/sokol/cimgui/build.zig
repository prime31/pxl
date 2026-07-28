const std = @import("std");
const Build = std.Build;
const builtin = @import("builtin");

const imgui_sources = [_][]const u8{
    "cimgui.cpp",
    "cimgui_internal.cpp",
    "imgui_demo.cpp",
    "imgui_draw.cpp",
    "imgui_tables.cpp",
    "imgui_widgets.cpp",
    "imgui.cpp",
};

// returned by the getConfig() helper function to get a matching
// set of module name, C header path and C library name for
// vanilla imgui vs imgui docking branch (because mismatches
// may appear to build but then cause hilarious runtime bugs)
pub const Config = struct {
    module_name: []const u8, // cimgui or cimgui_docking
    include_dir: []const u8, // src or src-docking
    clib_name: []const u8, // cimgui_clib or cimgui_docking_clib
};

// helper function to return a matching set of Zig module name,
// C header search path and C library name for docking vs non-docking
pub fn getConfig(docking: bool) Config {
    if (docking) {
        return .{
            .module_name = "cimgui_docking",
            .include_dir = "src-docking",
            .clib_name = "cimgui_docking_clib",
        };
    } else {
        return .{
            .module_name = "cimgui",
            .include_dir = "src",
            .clib_name = "cimgui_clib",
        };
    }
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("cimgui_docking", .{
        .root_source_file = b.path("cimgui_docking.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .link_libcpp = true,
    });

    mod.addObjectFile(b.path("libcimgui_docking_clib.a"));
}
