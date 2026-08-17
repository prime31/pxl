const std = @import("std");

pub const JpgWriteSettings = struct {
    quality: u32,
};

pub const ImageWriteFormat = union(enum) {
    png,
    jpg: JpgWriteSettings,
};

pub const ImageWriteError = error{
    CouldNotWriteImage,
};

pub const Image = struct {
    data: []u8,
    width: u32,
    height: u32,
    num_components: u32,
    bytes_per_component: u32,
    bytes_per_row: u32,
    is_hdr: bool,

    pub fn info(pathname: [:0]const u8) struct {
        is_supported: bool,
        width: u32,
        height: u32,
        num_components: u32,
    } {
        var w: c_int = 0;
        var h: c_int = 0;
        var c: c_int = 0;
        const is_supported = stbi_info(pathname, &w, &h, &c);
        return .{
            .is_supported = if (is_supported == 1) true else false,
            .width = @as(u32, @intCast(w)),
            .height = @as(u32, @intCast(h)),
            .num_components = @as(u32, @intCast(c)),
        };
    }

    pub fn loadFromFile(pathname: [:0]const u8, forced_num_components: u32) !Image {
        var width: u32 = 0;
        var height: u32 = 0;
        var num_components: u32 = 0;
        var bytes_per_component: u32 = 0;
        var bytes_per_row: u32 = 0;
        var is_hdr = false;

        const data = if (isHdr(pathname)) data: {
            var x: c_int = undefined;
            var y: c_int = undefined;
            var ch: c_int = undefined;
            const ptr = stbi_loadf(
                pathname,
                &x,
                &y,
                &ch,
                @as(c_int, @intCast(forced_num_components)),
            );
            if (ptr == null) return error.ImageInitFailed;

            num_components = if (forced_num_components == 0) @as(u32, @intCast(ch)) else forced_num_components;
            width = @as(u32, @intCast(x));
            height = @as(u32, @intCast(y));
            bytes_per_component = 2;
            bytes_per_row = width * num_components * bytes_per_component;
            is_hdr = true;

            // Convert each component from f32 to f16.
            var ptr_f16 = @as([*]f16, @ptrCast(ptr.?));
            const num = width * height * num_components;
            var i: u32 = 0;
            while (i < num) : (i += 1) {
                ptr_f16[i] = @as(f16, @floatCast(ptr.?[i]));
            }
            break :data @as([*]u8, @ptrCast(ptr_f16))[0 .. height * bytes_per_row];
        } else data: {
            var x: c_int = undefined;
            var y: c_int = undefined;
            var ch: c_int = undefined;
            const is_16bit = is16bit(pathname);
            const ptr = if (is_16bit) @as(?[*]u8, @ptrCast(stbi_load_16(
                pathname,
                &x,
                &y,
                &ch,
                @as(c_int, @intCast(forced_num_components)),
            ))) else stbi_load(
                pathname,
                &x,
                &y,
                &ch,
                @as(c_int, @intCast(forced_num_components)),
            );
            if (ptr == null) return error.ImageInitFailed;

            num_components = if (forced_num_components == 0) @as(u32, @intCast(ch)) else forced_num_components;
            width = @as(u32, @intCast(x));
            height = @as(u32, @intCast(y));
            bytes_per_component = if (is_16bit) 2 else 1;
            bytes_per_row = width * num_components * bytes_per_component;
            is_hdr = false;

            break :data @as([*]u8, @ptrCast(ptr))[0 .. height * bytes_per_row];
        };

        return Image{
            .data = data,
            .width = width,
            .height = height,
            .num_components = num_components,
            .bytes_per_component = bytes_per_component,
            .bytes_per_row = bytes_per_row,
            .is_hdr = is_hdr,
        };
    }

    pub fn loadFromMemory(data: []const u8, forced_num_components: u32) !Image {
        var width: u32 = 0;
        var height: u32 = 0;
        var num_components: u32 = 0;
        var bytes_per_component: u32 = 0;
        var bytes_per_row: u32 = 0;
        var is_hdr = false;

        const image_data = if (isHdrFromMem(data)) data: {
            var x: c_int = undefined;
            var y: c_int = undefined;
            var ch: c_int = undefined;
            const ptr = stbi_loadf_from_memory(
                data.ptr,
                @as(c_int, @intCast(data.len)),
                &x,
                &y,
                &ch,
                @as(c_int, @intCast(forced_num_components)),
            );
            if (ptr == null) return error.ImageInitFailed;

            num_components = if (forced_num_components == 0) @as(u32, @intCast(ch)) else forced_num_components;
            width = @as(u32, @intCast(x));
            height = @as(u32, @intCast(y));
            bytes_per_component = 2;
            bytes_per_row = width * num_components * bytes_per_component;
            is_hdr = true;

            // Convert each component from f32 to f16.
            var ptr_f16 = @as([*]f16, @ptrCast(ptr.?));
            const num = width * height * num_components;
            var i: u32 = 0;
            while (i < num) : (i += 1) {
                ptr_f16[i] = @as(f16, @floatCast(ptr.?[i]));
            }
            break :data @as([*]u8, @ptrCast(ptr_f16))[0 .. height * bytes_per_row];
        } else data: {
            var x: c_int = undefined;
            var y: c_int = undefined;
            var ch: c_int = undefined;
            const ptr = stbi_load_from_memory(
                data.ptr,
                @as(c_int, @intCast(data.len)),
                &x,
                &y,
                &ch,
                @as(c_int, @intCast(forced_num_components)),
            );
            if (ptr == null) return error.ImageInitFailed;

            num_components = if (forced_num_components == 0) @as(u32, @intCast(ch)) else forced_num_components;
            width = @as(u32, @intCast(x));
            height = @as(u32, @intCast(y));
            bytes_per_component = 1;
            bytes_per_row = width * num_components * bytes_per_component;

            break :data @as([*]u8, @ptrCast(ptr))[0 .. height * bytes_per_row];
        };

        return Image{
            .data = image_data,
            .width = width,
            .height = height,
            .num_components = num_components,
            .bytes_per_component = bytes_per_component,
            .bytes_per_row = bytes_per_row,
            .is_hdr = is_hdr,
        };
    }

    pub fn writeToFile(
        image: Image,
        filename: [:0]const u8,
        image_format: ImageWriteFormat,
    ) ImageWriteError!void {
        const w = @as(c_int, @intCast(image.width));
        const h = @as(c_int, @intCast(image.height));
        const comp = @as(c_int, @intCast(image.num_components));
        const result = switch (image_format) {
            .png => stbi_write_png(filename.ptr, w, h, comp, image.data.ptr, 0),
            .jpg => |settings| stbi_write_jpg(
                filename.ptr,
                w,
                h,
                comp,
                image.data.ptr,
                @as(c_int, @intCast(settings.quality)),
            ),
        };
        // if the result is 0 then it means an error occured (per stb image write docs)
        if (result == 0) {
            return ImageWriteError.CouldNotWriteImage;
        }
    }

    pub fn writeToFn(
        image: Image,
        write_fn: *const fn (ctx: ?*anyopaque, data: ?*anyopaque, size: c_int) callconv(.c) void,
        context: ?*anyopaque,
        image_format: ImageWriteFormat,
    ) ImageWriteError!void {
        const w = @as(c_int, @intCast(image.width));
        const h = @as(c_int, @intCast(image.height));
        const comp = @as(c_int, @intCast(image.num_components));
        const result = switch (image_format) {
            .png => stbi_write_png_to_func(write_fn, context, w, h, comp, image.data.ptr, 0),
            .jpg => |settings| stbi_write_jpg_to_func(
                write_fn,
                context,
                w,
                h,
                comp,
                image.data.ptr,
                @as(c_int, @intCast(settings.quality)),
            ),
        };
        // if the result is 0 then it means an error occured (per stb image write docs)
        if (result == 0) {
            return ImageWriteError.CouldNotWriteImage;
        }
    }

    pub fn deinit(image: *Image) void {
        stbi_image_free(image.data.ptr);
        image.* = undefined;
    }
};

/// `pub fn setHdrToLdrScale(scale: f32) void`
pub const setHdrToLdrScale = stbi_hdr_to_ldr_scale;

/// `pub fn setHdrToLdrGamma(gamma: f32) void`
pub const setHdrToLdrGamma = stbi_hdr_to_ldr_gamma;

/// `pub fn setLdrToHdrScale(scale: f32) void`
pub const setLdrToHdrScale = stbi_ldr_to_hdr_scale;

/// `pub fn setLdrToHdrGamma(gamma: f32) void`
pub const setLdrToHdrGamma = stbi_ldr_to_hdr_gamma;

pub fn isHdr(filename: [:0]const u8) bool {
    return stbi_is_hdr(filename) != 0;
}

pub fn isHdrFromMem(buffer: []const u8) bool {
    return stbi_is_hdr_from_memory(buffer.ptr, @as(c_int, @intCast(buffer.len))) != 0;
}

pub fn is16bit(filename: [:0]const u8) bool {
    return stbi_is_16_bit(filename) != 0;
}

pub fn setFlipVerticallyOnLoad(should_flip: bool) void {
    stbi_set_flip_vertically_on_load(if (should_flip) 1 else 0);
}

pub fn setFlipVerticallyOnWrite(should_flip: bool) void {
    stbi_flip_vertically_on_write(if (should_flip) 1 else 0);
}

extern fn stbi_info(filename: [*:0]const u8, x: *c_int, y: *c_int, comp: *c_int) c_int;

extern fn stbi_load(
    filename: [*:0]const u8,
    x: *c_int,
    y: *c_int,
    channels_in_file: *c_int,
    desired_channels: c_int,
) ?[*]u8;

extern fn stbi_load_16(
    filename: [*:0]const u8,
    x: *c_int,
    y: *c_int,
    channels_in_file: *c_int,
    desired_channels: c_int,
) ?[*]u16;

extern fn stbi_loadf(
    filename: [*:0]const u8,
    x: *c_int,
    y: *c_int,
    channels_in_file: *c_int,
    desired_channels: c_int,
) ?[*]f32;

pub extern fn stbi_load_from_memory(
    buffer: [*]const u8,
    len: c_int,
    x: *c_int,
    y: *c_int,
    channels_in_file: *c_int,
    desired_channels: c_int,
) ?[*]u8;

pub extern fn stbi_loadf_from_memory(
    buffer: [*]const u8,
    len: c_int,
    x: *c_int,
    y: *c_int,
    channels_in_file: *c_int,
    desired_channels: c_int,
) ?[*]f32;

extern fn stbi_image_free(image_data: ?[*]u8) void;

extern fn stbi_hdr_to_ldr_scale(scale: f32) void;
extern fn stbi_hdr_to_ldr_gamma(gamma: f32) void;
extern fn stbi_ldr_to_hdr_scale(scale: f32) void;
extern fn stbi_ldr_to_hdr_gamma(gamma: f32) void;

extern fn stbi_is_16_bit(filename: [*:0]const u8) c_int;
extern fn stbi_is_hdr(filename: [*:0]const u8) c_int;
extern fn stbi_is_hdr_from_memory(buffer: [*]const u8, len: c_int) c_int;

extern fn stbi_set_flip_vertically_on_load(flag_true_if_should_flip: c_int) void;
extern fn stbi_flip_vertically_on_write(flag: c_int) void; // flag is non-zero to flip data vertically

extern fn stbi_write_jpg(
    filename: [*:0]const u8,
    w: c_int,
    h: c_int,
    comp: c_int,
    data: [*]const u8,
    quality: c_int,
) c_int;

extern fn stbi_write_png(
    filename: [*:0]const u8,
    w: c_int,
    h: c_int,
    comp: c_int,
    data: [*]const u8,
    stride_in_bytes: c_int,
) c_int;

extern fn stbi_write_png_to_func(
    func: *const fn (?*anyopaque, ?*anyopaque, c_int) callconv(.c) void,
    context: ?*anyopaque,
    w: c_int,
    h: c_int,
    comp: c_int,
    data: [*]const u8,
    stride_in_bytes: c_int,
) c_int;

extern fn stbi_write_jpg_to_func(
    func: *const fn (?*anyopaque, ?*anyopaque, c_int) callconv(.c) void,
    context: ?*anyopaque,
    x: c_int,
    y: c_int,
    comp: c_int,
    data: [*]const u8,
    quality: c_int,
) c_int;

/// stb_vorbis bindings. The library is compiled with
/// `STB_VORBIS_NO_INTEGER_CONVERSION` (see zstbi.c), which forces f32
/// output and compiles out the `short` decode helpers, so the API here
/// decodes directly to `f32` — matching sokol-audio's native format.
pub const vorbis = struct {
    pub const Decoded = struct {
        /// Interleaved frames: `samples[i * channels + c]` is channel `c`
        /// of frame `i`. Allocated with the allocator passed to `decodeMemory`.
        samples: []f32,
        /// Number of frames (samples per channel).
        num_samples: usize,
        channels: u32,
        sample_rate: u32,
    };

    /// Decode an entire ogg vorbis stream from memory into interleaved
    /// f32 samples. `mem` must contain the complete stream. The returned
    /// `Decoded.samples` is owned by the caller (free with the allocator).
    pub fn decodeMemory(mem: []const u8, allocator: std.mem.Allocator) !Decoded {
        var error_code: c_int = 0;
        const v = stb_vorbis_open_memory(mem.ptr, @intCast(mem.len), &error_code, null) orelse
            return error.VorbisDecodeFailed;
        defer stb_vorbis_close(v);

        const info = stb_vorbis_get_info(v);
        const channels: usize = @intCast(info.channels);
        const num_samples: usize = stb_vorbis_stream_length_in_samples(v);
        if (channels == 0 or num_samples == 0) return error.VorbisEmptyStream;

        const samples = try allocator.alloc(f32, num_samples * channels);

        // Decode in chunks; the interleaved reader returns frames per
        // channel, so a corrupt/truncated stream just yields fewer frames.
        var offset: usize = 0;
        while (offset < num_samples) {
            const n = stb_vorbis_get_samples_float_interleaved(
                v,
                @intCast(channels),
                samples.ptr + offset * channels,
                @intCast((num_samples - offset) * channels),
            );
            if (n <= 0) break;
            offset += @intCast(n);
        }

        return .{
            .samples = samples[0 .. offset * channels],
            .num_samples = offset,
            .channels = @intCast(channels),
            .sample_rate = @intCast(info.sample_rate),
        };
    }

    /// A streaming ogg vorbis decoder: open a memory stream, then pull
    /// small chunks of interleaved f32 frames on demand with `readFrames`.
    /// Memory stays bounded regardless of track length (the compressed ogg
    /// bytes + one decode chunk), so a multi-minute track costs roughly the
    /// same as a one-second one.
    pub const Stream = struct {
        handle: *stb_vorbis,
        /// Owned copy of the compressed stream (freed in `close`).
        data: []u8,
        allocator: std.mem.Allocator,
        channels: u32,
        sample_rate: u32,
        /// Total frames per channel (0 if stb can't determine it).
        num_samples: usize,
        /// Set once the decoder reports end-of-stream.
        eof: bool,

        /// Open a decoder for `mem` (a complete ogg vorbis stream). The
        /// bytes are copied, so the caller can free its own copy right away.
        pub fn open(mem: []const u8, allocator: std.mem.Allocator) !Stream {
            if (mem.len == 0) return error.VorbisEmptyStream;

            const data = try allocator.dupe(u8, mem);
            errdefer allocator.free(data);

            var error_code: c_int = 0;
            const handle = stb_vorbis_open_memory(data.ptr, @intCast(data.len), &error_code, null) orelse
                return error.VorbisDecodeFailed;

            const info = stb_vorbis_get_info(handle);
            if (info.channels <= 0 or info.sample_rate == 0) {
                stb_vorbis_close(handle);
                return error.VorbisDecodeFailed;
            }

            return .{
                .handle = handle,
                .data = data,
                .allocator = allocator,
                .channels = @intCast(info.channels),
                .sample_rate = @intCast(info.sample_rate),
                .num_samples = stb_vorbis_stream_length_in_samples(handle),
                .eof = false,
            };
        }

        /// Decode up to `out.len / channels` interleaved frames into `out`.
        /// Returns the number of frames decoded (0 at end of stream).
        pub fn readFrames(self: *Stream, out: []f32) !usize {
            if (self.eof or out.len < self.channels) return 0;
            const n = stb_vorbis_get_samples_float_interleaved(
                self.handle,
                @intCast(self.channels),
                out.ptr,
                @intCast(out.len),
            );
            if (n <= 0) {
                self.eof = true;
                return 0;
            }
            return @intCast(n);
        }

        /// Seek to an absolute frame. The next `readFrames` call resumes
        /// from there.
        pub fn seek(self: *Stream, frame: usize) !void {
            if (stb_vorbis_seek(self.handle, @intCast(frame)) == 0) return error.VorbisSeekFailed;
            self.eof = false;
        }

        pub fn close(self: *Stream) void {
            stb_vorbis_close(self.handle);
            self.allocator.free(self.data);
            self.* = undefined;
        }
    };

    const stb_vorbis = opaque {};
    // Field order/sizes must match stb_vorbis.h exactly — get_info returns
    // this struct by value.
    const stb_vorbis_info = extern struct {
        sample_rate: c_uint,
        channels: c_int,
        setup_memory_required: c_uint,
        setup_temp_memory_required: c_uint,
        temp_memory_required: c_uint,
        max_frame_size: c_int,
    };

    // alloc_buffer is only used for custom allocation; we pass null and
    // let stb_vorbis use the C allocator.
    extern fn stb_vorbis_open_memory(
        data: [*]const u8,
        len: c_int,
        error_code: *c_int,
        alloc_buffer: ?*const anyopaque,
    ) ?*stb_vorbis;
    extern fn stb_vorbis_get_info(f: ?*const stb_vorbis) stb_vorbis_info;
    extern fn stb_vorbis_stream_length_in_samples(f: ?*const stb_vorbis) c_uint;
    extern fn stb_vorbis_get_samples_float_interleaved(
        f: ?*stb_vorbis,
        channels: c_int,
        buffer: [*]f32,
        num_floats: c_int,
    ) c_int;
    extern fn stb_vorbis_seek(f: ?*stb_vorbis, sample_number: c_uint) c_int;
    extern fn stb_vorbis_close(f: ?*stb_vorbis) void;
};

