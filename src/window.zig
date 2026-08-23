//! Window query and control functions. Wraps `sokol.app.*` so user code never
//! needs to import sokol directly.
const sapp = @import("sokol").app;
const pxl = @import("pxl.zig");

pub fn width() i32 {
    return sapp.width();
}
pub fn height() i32 {
    return sapp.height();
}
pub fn widthf() f32 {
    return sapp.widthf();
}
pub fn heightf() f32 {
    return sapp.heightf();
}
pub fn dpiScale() f32 {
    return sapp.dpiScale();
}
pub fn isFullscreen() bool {
    return sapp.isFullscreen();
}
pub fn toggleFullscreen() void {
    sapp.toggleFullscreen();
}
pub fn showMouse(show: bool) void {
    sapp.showMouse(show);
}
pub fn mouseShown() bool {
    return sapp.mouseShown();
}
pub fn lockMouse(lock: bool) void {
    sapp.lockMouse(lock);
}
pub fn mouseLocked() bool {
    return sapp.mouseLocked();
}
pub fn requestQuit() void {
    sapp.requestQuit();
}
pub fn cancelQuit() void {
    sapp.cancelQuit();
}
pub fn quit() void {
    sapp.quit();
}
pub fn setWindowTitle(title: [:0]const u8) void {
    sapp.setWindowTitle(title);
}
pub fn setClipboardString(str: [:0]const u8) void {
    sapp.setClipboardString(str);
}
pub fn getClipboardString() [:0]const u8 {
    return sapp.getClipboardString();
}

// ── Render target ────────────────────────────────────────────────────────────

/// True when the resolution policy guarantees an integer-scaled blit of a fixed
/// design-size render target.
pub fn isPixelPerfect() bool {
    return switch (pxl.gpu.gfx_config.resolution_policy) {
        .no_border_pixel_perfect, .show_all_pixel_perfect => true,
        else => false,
    };
}

pub fn renderWidth() i32 {
    const scaler = pxl.gpu.gfx_config.resolution_policy.getScaler(
        pxl.gpu.gfx_config.design_width,
        pxl.gpu.gfx_config.design_height,
    );
    return scaler.w;
}

pub fn renderHeight() i32 {
    const scaler = pxl.gpu.gfx_config.resolution_policy.getScaler(
        pxl.gpu.gfx_config.design_width,
        pxl.gpu.gfx_config.design_height,
    );
    return scaler.h;
}

pub fn renderWidthf() f32 {
    return @floatFromInt(renderWidth());
}

pub fn renderHeightf() f32 {
    return @floatFromInt(renderHeight());
}
