const pxl = @import("pxl");
const c_api = @import("c_api.zig");

// Force the C API symbols to be emitted. The exports in c_api.zig are marked
// `export`, so simply importing the file is enough — the linker sees them.
comptime {
    _ = c_api;
    _ = pxl;
}