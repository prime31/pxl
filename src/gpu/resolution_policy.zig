const std = @import("std");
const pxl = @import("../pxl.zig");
const cast = pxl.util.cast;

pub const ResolutionScaler = struct {
    x: i32 = 0,
    y: i32 = 0,
    w: i32,
    h: i32,
    scale: f32 = 1,

    pub fn widthf(self: ResolutionScaler) f32 {
        return cast(f32, self.w);
    }

    pub fn heightf(self: ResolutionScaler) f32 {
        return cast(f32, self.h);
    }
};

pub const ResolutionPolicy = enum {
    /// RenderTarget matches the screen size
    default,
    /// The entire application fills the specified area, without distortion but possibly with some cropping
    no_border,
    /// Pixel perfect version of NoBorder. Scaling is limited to integer values.
    no_border_pixel_perfect,
    /// The entire application is visible in the specified area without distortion while maintaining the original
    /// aspect ratio of the application. Borders can appear on two sides of the application.
    show_all,
    /// Pixel perfect version of ShowAll. Scaling is limited to integer values.
    show_all_pixel_perfect,
    /// The application takes the width and height that best fits the design resolution with optional cropping inside of the "bleed area"
    /// and possible letter/pillar boxing. Works just like ShowAll except with horizontal/vertical bleed (padding).
    best_fit,

    pub fn getScaler(self: ResolutionPolicy, design_w: i32, design_h: i32) ResolutionScaler {
        // non-default policy requires a design size
        std.debug.assert((self != .default and design_w > 0 and design_h > 0) or self == .default);

        // common config
        const win_size = struct { w: f32, h: f32 }{ .w = pxl.sapp.widthf(), .h = pxl.sapp.heightf() };

        // our render target size will be full screen for .default
        const rt_w = if (self == .default) win_size.w else cast(f32, design_w);
        const rt_h = if (self == .default) win_size.h else cast(f32, design_h);

        // scale of the screen size / render target size, used by both pixel perfect and non-pp
        const res_x = win_size.w / rt_w;
        const res_y = win_size.h / rt_h;

        var scale: i32 = 1;
        var scale_f: f32 = 1.0;
        const aspect_ratio = win_size.w / win_size.h;
        const rt_aspect_ratio = rt_w / rt_h;

        if (self != .default) {
            scale_f = if (rt_aspect_ratio > aspect_ratio) res_x else res_y;
            scale = @as(i32, @intFromFloat(@floor(scale_f)));

            if (scale < 1) scale = 1;
        }

        switch (self) {
            .default => {
                const win_scale = pxl.sapp.dpiScale();
                const width = @as(i32, @intFromFloat(win_size.w / win_scale));
                const height = @as(i32, @intFromFloat(win_size.h / win_scale));
                return ResolutionScaler{
                    .x = 0,
                    .y = 0,
                    .w = width,
                    .h = height,
                    .scale = win_scale,
                };
            },
            .no_border, .show_all => {
                // go for the highest scale value if we can crop (No_Border) or
                // go for the lowest scale value so everything fits properly (Show_All)
                const res_scale = if (self == .no_border) @max(res_x, res_y) else @min(res_x, res_y);

                const x = (win_size.w - rt_w * res_scale) / 2.0;
                const y = (win_size.h - rt_h * res_scale) / 2.0;

                return ResolutionScaler{
                    .x = cast(i32, x),
                    .y = cast(i32, y),
                    .w = cast(i32, rt_w),
                    .h = cast(i32, rt_h),
                    .scale = res_scale,
                };
            },
            .no_border_pixel_perfect, .show_all_pixel_perfect => {
                // the only difference is that no_border rounds up (instead of down) and crops. Because
                // of the round up, we flip the compare of the rt aspect ratio vs the screen aspect ratio.
                if (self == .no_border_pixel_perfect) {
                    scale_f = if (rt_aspect_ratio < aspect_ratio) res_x else res_y;
                    scale = @as(i32, @intFromFloat(@ceil(scale_f)));
                }

                const x = @divTrunc(cast(i32, win_size.w - rt_w * cast(f32, scale)), 2);
                const y = @divTrunc(cast(i32, win_size.h - rt_h * cast(f32, scale)), 2);
                return ResolutionScaler{
                    .x = x,
                    .y = y,
                    .w = cast(i32, rt_w),
                    .h = cast(i32, rt_h),
                    .scale = @as(f32, @floatFromInt(scale)),
                };
            },
            .best_fit => {
                const bleed_x: f32 = 0;
                const bleed_y: f32 = 0;
                const safe_sx = win_size.w / rt_w - bleed_x;
                const safe_sy = win_size.h / rt_h - bleed_y;

                const res_scale = @max(res_x, res_y);
                const safe_scale = @min(safe_sx, safe_sy);
                const final_scale = @min(res_scale, safe_scale);

                const x = win_size.w - (rt_w * final_scale) / 2.0;
                const y = win_size.h - (rt_h * final_scale) / 2.0;

                return ResolutionScaler{
                    .x = cast(i32, x),
                    .y = cast(i32, y),
                    .w = cast(i32, rt_w),
                    .h = cast(i32, rt_h),
                    .scale = final_scale,
                };
            },
        }
    }
};
