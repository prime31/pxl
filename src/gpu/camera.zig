const std = @import("std");
const pxl = @import("../pxl.zig");
const Vec2 = pxl.math.Vec2;
const Mat32 = pxl.math.Mat32;

pub const Camera = struct {
    position: Vec2 = .zero,
    rotation: f32 = 0,
    zoom: f32 = 1.0,
    offset: ?Vec2 = null,

    /// Compute the view matrix (world -> render-target pixels). The camera is a pure
    /// transform: pixel snapping for low-res scenes is applied downstream in the
    /// batcher (see `Pass.pixel_snap`), so this stays fractional when the camera is
    /// mid-lerp and the batcher rounds the result onto the pixel grid.
    pub fn getView(self: Camera, screen_width: f32, screen_height: f32) Mat32 {
        const off = self.offset orelse Vec2.init(screen_width * 0.5, screen_height * 0.5);
        const zoom_val = if (self.zoom == 0) 1.0 else self.zoom;

        return Mat32.fromTranslation(off.x, off.y)
            .mul(Mat32.fromRotation(-self.rotation))
            .mul(Mat32.fromScale(zoom_val, zoom_val))
            .mul(Mat32.fromTranslation(-self.position.x, -self.position.y));
    }

    /// Compute the combined view-projection matrix for this camera given target dimensions
    pub fn getMatrix(self: Camera, screen_width: f32, screen_height: f32) Mat32 {
        const projection = Mat32.orthographic(screen_width, screen_height);
        return projection.mul(self.getView(screen_width, screen_height));
    }

    /// Convert design render-target coordinates (or screen coordinates if using default policy) to world space
    pub fn screenToWorld(self: Camera, screen_pos: Vec2) Vec2 {
        const target_w = pxl.window.renderWidthf();
        const target_h = pxl.window.renderHeightf();
        const off = self.offset orelse Vec2.init(target_w * 0.5, target_h * 0.5);
        const zoom_val = if (self.zoom == 0) 1.0 else self.zoom;

        const rel = screen_pos.sub(off);
        const rot_mat = Mat32.fromRotation(self.rotation);
        const unrotated = rot_mat.transformVec2(rel);
        const unscaled = unrotated.scale(1.0 / zoom_val);
        return unscaled.add(self.position);
    }

    /// Convert world space coordinates to design render-target coordinates
    pub fn worldToScreen(self: Camera, world_pos: Vec2) Vec2 {
        const target_w = pxl.window.renderWidthf();
        const target_h = pxl.window.renderHeightf();
        const off = self.offset orelse Vec2.init(target_w * 0.5, target_h * 0.5);
        const zoom_val = if (self.zoom == 0) 1.0 else self.zoom;

        const rel = world_pos.sub(self.position);
        const scaled = rel.scale(zoom_val);
        const rot_mat = Mat32.fromRotation(-self.rotation);
        const rotated = rot_mat.transformVec2(scaled);
        return rotated.add(off);
    }

    /// Convert raw window pixel coordinates (e.g. from mouse) to world space, taking into account ResolutionPolicy scaling and letterboxing
    pub fn windowToWorld(self: Camera, window_pos: Vec2) Vec2 {
        const scaler = pxl.gpu.gfx_config.resolution_policy.getScaler(pxl.gpu.gfx_config.design_width, pxl.gpu.gfx_config.design_height);
        const scale_val = if (scaler.scale == 0) 1.0 else scaler.scale;
        const design_x = (window_pos.x - @as(f32, @floatFromInt(scaler.x))) / scale_val;
        const design_y = (window_pos.y - @as(f32, @floatFromInt(scaler.y))) / scale_val;
        return self.screenToWorld(.init(design_x, design_y));
    }

    /// Convert world space coordinates to raw window pixel coordinates, taking into account ResolutionPolicy scaling and letterboxing
    pub fn worldToWindow(self: Camera, world_pos: Vec2) Vec2 {
        const design_pos = self.worldToScreen(world_pos);
        const scaler = pxl.gpu.gfx_config.resolution_policy.getScaler(pxl.gpu.gfx_config.design_width, pxl.gpu.gfx_config.design_height);
        const win_x = design_pos.x * scaler.scale + @as(f32, @floatFromInt(scaler.x));
        const win_y = design_pos.y * scaler.scale + @as(f32, @floatFromInt(scaler.y));
        return .init(win_x, win_y);
    }
};
