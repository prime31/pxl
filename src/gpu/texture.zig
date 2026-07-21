const std = @import("std");
const pxl = @import("../pxl.zig");
const sg = pxl.sokol.gfx;

pub const Texture = extern struct {
    img: sg.Image = undefined,
    width: i32 = 0,
    height: i32 = 0,

    pub fn deinit(self: Texture) void {
        sg.destroyImage(self.img);
    }

    pub fn initOffscreen(width: i32, height: i32) Texture {
        var img_desc = std.mem.zeroes(sg.ImageDesc);
        img_desc.render_target = true;
        img_desc.width = width;
        img_desc.height = height;

        return .{ .width = width, .height = height, .img = sg.makeImage(&img_desc) };
    }

    pub fn initDepthStencil(width: i32, height: i32) Texture {
        var img_desc = std.mem.zeroes(sg.ImageDesc);
        img_desc.render_target = true;
        img_desc.width = width;
        img_desc.height = height;
        img_desc.pixel_format = .DEPTH_STENCIL;

        return .{ .width = width, .height = height, .img = sg.makeImage(&img_desc) };
    }

    pub fn init(width: i32, height: i32) Texture {
        var img_desc = std.mem.zeroes(sg.ImageDesc);
        img_desc.width = width;
        img_desc.height = height;
        img_desc.usage = .SG_USAGE_DYNAMIC;
        img_desc.pixel_format = .RGBA8;

        return .{ .width = width, .height = height, .img = sg.makeImage(&img_desc) };
    }

    pub fn initWithData(pixels: []u8, width: i32, height: i32) Texture {
        var img_desc = std.mem.zeroes(sg.ImageDesc);
        img_desc.width = width;
        img_desc.height = height;
        img_desc.pixel_format = .RGBA8;
        img_desc.data.mip_levels[0] = sg.asRange(pixels);
        img_desc.label = "gg-texture";

        return .{ .width = width, .height = height, .img = sg.makeImage(img_desc) };
    }

    pub fn initWithColorData(pixels: []u32, width: i32, height: i32) Texture {
        var img_desc = std.mem.zeroes(sg.ImageDesc);
        img_desc.width = width;
        img_desc.height = height;
        img_desc.pixel_format = .RGBA8;
        img_desc.data.mip_levels[0] = sg.asRange(pixels);
        img_desc.label = "gg-texture";

        return .{ .width = width, .height = height, .img = sg.makeImage(img_desc) };
    }

    pub fn initFromFile(file: [:0]const u8) !Texture {
        // const image_contents = try gg.fs.read(file, .temp);

        // var w: c_int = undefined;
        // var h: c_int = undefined;
        // var channels: c_int = undefined;
        // const load_res = gg.stb.stbi_load_from_memory(image_contents.ptr, @intCast(image_contents.len), &w, &h, &channels, 4);
        // if (load_res == null) return error.ImageLoadFailed;
        // defer gg.stb.stbi_image_free(load_res);

        var img = try pxl.stb.Image.loadFromFile(file, 4);
        defer img.deinit();
        return Texture.initWithData(img.data, @intCast(img.width), @intCast(img.height));
    }

    pub fn initCheckerboard() Texture {
        var pixels = [_]u32{
            0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, 0xFF000000,
            0xFF000000, 0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF,
            0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF, 0xFF000000,
            0xFF000000, 0xFFFFFFFF, 0xFF000000, 0xFFFFFFFF,
        };
        return initWithColorData(pixels[0..], 4, 4);
    }
};
