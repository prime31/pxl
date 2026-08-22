//! Window query and control functions. Wraps `sokol.app.*` so user code never
//! needs to import sokol directly.
const sapp = @import("sokol").app;

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