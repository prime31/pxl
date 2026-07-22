const std = @import("std");
const pxl = @import("../pxl.zig");
const sg = pxl.sokol.gfx;

const Vec2 = pxl.math.Vec2;

// https://snowb.org/

/// The 5 block types in a BMFont binary file
pub const BlockType = enum(u8) {
    info = 1,
    common = 2,
    pages = 3,
    chars = 4,
    kerning = 5,
};

pub const FontInfo = struct {
    size: i16,
    bit_field: u8,
    char_set: u8,
    stretch_h: u16,
    anti_aliasing: u8,
    padding_up: u8,
    padding_right: u8,
    padding_down: u8,
    padding_left: u8,
    spacing_horiz: u8,
    spacing_vert: u8,
    outline: u8,
    font_name: []const u8,
};

pub const FontCommon = struct {
    line_height: u16,
    base: u16,
    scale_w: u16,
    scale_h: u16,
    pages: u16,
    bit_field: u8,
    alpha_chnl: u8,
    red_chnl: u8,
    green_chnl: u8,
    blue_chnl: u8,
};

pub const FontChar = struct {
    id: u32,
    x: u16,
    y: u16,
    width: u16,
    height: u16,
    xoffset: i16,
    yoffset: i16,
    xadvance: i16,
    page: u8,
    chnl: u8,
};

pub const FontKerning = struct {
    first: u32,
    second: u32,
    amount: i16,
};

pub const BMFontParser = struct {
    buffer: []const u8,
    texture: pxl.gpu.Texture,
    info: FontInfo = undefined,
    common: FontCommon = undefined,
    pages: []const u8 = &[_]u8{},

    // Store raw packed bytes directly to avoid array pointer alignment crashes
    chars_raw: []const u8 = &[_]u8{},
    kernings_raw: []const u8 = &[_]u8{},
    chars_count: usize = 0,
    kernings_count: usize = 0,

    pub fn init(file: []const u8) !BMFontParser {
        // load the texture
        const texture_file = pxl.mem.dupeZ(u8, file, .temp);
        @memcpy(texture_file[texture_file.len - 3 ..].ptr, "png");
        const texture = try pxl.gpu.Texture.initFromFile(texture_file);

        // load the BMFont
        const buffer = try pxl.fs.read(file, .persistent);
        if (buffer.len < 4) return error.InvalidHeader;

        if (!std.mem.eql(u8, buffer[0..3], "BMF")) return error.InvalidMagicNumber;
        if (buffer[3] != 3) return error.UnsupportedVersion;

        var parser = BMFontParser{ .buffer = buffer, .texture = texture };
        var index: usize = 4;

        while (index < buffer.len) {
            if (index + 5 > buffer.len) return error.UnexpectedEof;

            const block_type_raw = buffer[index];
            const block_size = std.mem.readInt(u32, buffer[index + 1 .. index + 5][0..4], .little);
            index += 5;

            if (index + block_size > buffer.len) return error.UnexpectedEof;
            const block_data = buffer[index .. index + block_size];
            index += block_size;

            const block_id: BlockType = @enumFromInt(block_type_raw);
            switch (block_id) {
                .info => {
                    if (block_data.len < 14) return error.MalformedBlock;
                    parser.info = .{
                        .size = std.mem.readInt(i16, block_data[0..2][0..2], .little),
                        .bit_field = block_data[2],
                        .char_set = block_data[3],
                        .stretch_h = std.mem.readInt(u16, block_data[4..6][0..2], .little),
                        .anti_aliasing = block_data[6],
                        .padding_up = block_data[7],
                        .padding_right = block_data[8],
                        .padding_down = block_data[9],
                        .padding_left = block_data[10],
                        .spacing_horiz = block_data[11],
                        .spacing_vert = block_data[12],
                        .outline = block_data[13],
                        .font_name = block_data[14..],
                    };
                },
                .common => {
                    // Safe Hardcoded Size Validation matching AngelCode's spec (exactly 15 bytes)
                    if (block_data.len < 15) return error.MalformedBlock;
                    parser.common = .{
                        .line_height = std.mem.readInt(u16, block_data[0..2][0..2], .little),
                        .base = std.mem.readInt(u16, block_data[2..4][0..2], .little),
                        .scale_w = std.mem.readInt(u16, block_data[4..6][0..2], .little),
                        .scale_h = std.mem.readInt(u16, block_data[6..8][0..2], .little),
                        .pages = std.mem.readInt(u16, block_data[8..10][0..2], .little),
                        .bit_field = block_data[10],
                        .alpha_chnl = block_data[11],
                        .red_chnl = block_data[12],
                        .green_chnl = block_data[13],
                        .blue_chnl = block_data[14],
                    };
                },
                .pages => {
                    parser.pages = block_data;
                },
                .chars => {
                    // Each glyph is exactly 20 bytes long
                    parser.chars_raw = block_data;
                    parser.chars_count = block_data.len / 20;
                },
                .kerning => {
                    // Each kerning pair is exactly 10 bytes long
                    parser.kernings_raw = block_data;
                    parser.kernings_count = block_data.len / 10;
                },
            }
        }
        return parser;
    }

    pub fn deinit(self: *BMFontParser) void {
        pxl.mem.free(self.buffer);
        self.texture.deinit();
    }

    /// Safe inline getter that reads character elements out of unaligned data memory
    pub inline fn getChar(self: BMFontParser, idx: usize) FontChar {
        const offset = idx * 20;
        const b = self.chars_raw[offset .. offset + 20];
        return .{
            .id = std.mem.readInt(u32, b[0..4][0..4], .little),
            .x = std.mem.readInt(u16, b[4..6][0..2], .little),
            .y = std.mem.readInt(u16, b[6..8][0..2], .little),
            .width = std.mem.readInt(u16, b[8..10][0..2], .little),
            .height = std.mem.readInt(u16, b[10..12][0..2], .little),
            .xoffset = std.mem.readInt(i16, b[12..14][0..2], .little),
            .yoffset = std.mem.readInt(i16, b[14..16][0..2], .little),
            .xadvance = std.mem.readInt(i16, b[16..18][0..2], .little),
            .page = b[18],
            .chnl = b[19],
        };
    }

    /// Safe inline getter that reads kerning elements out of unaligned data memory
    pub inline fn getKerning(self: BMFontParser, idx: usize) FontKerning {
        const offset = idx * 10;
        const b = self.kernings_raw[offset .. offset + 10];
        return .{
            .first = std.mem.readInt(u32, b[0..4][0..4], .little),
            .second = std.mem.readInt(u32, b[4..8][0..4], .little),
            .amount = std.mem.readInt(i16, b[8..10][0..2], .little),
        };
    }

    /// TODO: replace with a HashMap?
    /// Finds a glyph's index by its character ID using binary search
    pub fn findCharIndex(self: BMFontParser, char_id: u32) ?usize {
        if (self.chars_count == 0) return null;

        var low: usize = 0;
        var high: usize = self.chars_count;

        while (low < high) {
            const mid = low + (high - low) / 2;
            const glyph = self.getChar(mid);

            if (glyph.id == char_id) {
                return mid;
            } else if (glyph.id < char_id) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return null;
    }

    /// Looks up the kerning adjustment between two characters
    pub fn getKerningAmount(self: BMFontParser, first_id: u32, second_id: u32) i16 {
        if (self.kernings_count == 0) return 0;

        var low: usize = 0;
        var high: usize = self.kernings_count;

        while (low < high) {
            const mid = low + (high - low) / 2;
            const kern = self.getKerning(mid);

            // Match both characters
            if (kern.first == first_id and kern.second == second_id) {
                return kern.amount;
            }

            // BMFont kernings are typically sorted by 'first' then 'second'
            if (kern.first < first_id or (kern.first == first_id and kern.second < second_id)) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return 0;
    }

    /// Draws text by walking through the unified layout iterator
    pub fn drawString(self: BMFontParser, text: []const u8, start_pos: Vec2) void {
        var layout = TextLayoutIterator.init(self, text, start_pos);

        while (layout.next()) |item| {
            const w = @as(f32, @floatFromInt(item.glyph.width));
            const h = @as(f32, @floatFromInt(item.glyph.height));

            pxl.sgp.draw_textured_rect(
                0,
                .{ .x = item.render_x, .y = item.render_y, .w = w, .h = h },
                .{ .x = @as(f32, @floatFromInt(item.glyph.x)), .y = @as(f32, @floatFromInt(item.glyph.y)), .w = w, .h = h },
            );
        }
    }

    /// Measures text by inspecting the layout pen's final coordinates
    pub fn measureString(self: BMFontParser, text: []const u8) Vec2 {
        if (text.len == 0) return .{ .x = 0, .y = 0 };

        var layout = TextLayoutIterator.init(self, text, .{ .x = 0, .y = 0 });
        var max_width: f32 = 0;

        // We just drain the iterator to advance the internal pen_x and pen_y coordinates
        while (layout.next()) |_| {
            if (layout.pen_x > max_width) {
                max_width = layout.pen_x;
            }
        }

        // Capture final trailing layout edge
        if (layout.pen_x > max_width) {
            max_width = layout.pen_x;
        }

        // Calculate total height based on pen vertical progress
        const base_height = @as(f32, @floatFromInt(self.common.line_height));
        const total_height = layout.pen_y + base_height;

        return .{
            .x = max_width,
            .y = total_height,
        };
    }
};

pub const LayoutItem = struct {
    /// The character's glyph data from the font file
    glyph: FontChar,
    /// Absolute calculated drawing position on screen
    render_x: f32,
    render_y: f32,
};

pub const TextLayoutIterator = struct {
    font: BMFontParser,
    text: []const u8,
    index: usize = 0,
    pen_x: f32,
    pen_y: f32,
    start_x: f32,
    prev_char_id: ?u32 = null,

    pub fn init(font: BMFontParser, text: []const u8, start_pos: Vec2) TextLayoutIterator {
        return .{
            .font = font,
            .text = text,
            .pen_x = start_pos.x,
            .pen_y = start_pos.y,
            .start_x = start_pos.x,
        };
    }

    /// Evaluates the next displayable character. Returns null when finished.
    pub fn next(self: *TextLayoutIterator) ?LayoutItem {
        while (self.index < self.text.len) {
            const c = self.text[self.index];
            self.index += 1;

            // Process Newlines and update state machine
            if (c == '\n') {
                self.pen_x = self.start_x;
                self.pen_y += @as(f32, @floatFromInt(self.font.common.line_height));
                self.prev_char_id = null;
                continue;
            }

            const char_id = @as(u32, c);

            // 1. Compute Kerning Offset
            if (self.prev_char_id) |prev_id| {
                const k = self.font.getKerningAmount(prev_id, char_id);
                self.pen_x += @as(f32, @floatFromInt(k));
            }

            // 2. Fetch Glyph Information
            const glyph_idx = self.font.findCharIndex(char_id) orelse {
                self.prev_char_id = null;
                continue; // Skip unrecognized glyphs
            };
            const glyph = self.font.getChar(glyph_idx);

            // 3. Extrapolate Final Rendering Coordinates
            const item = LayoutItem{
                .glyph = glyph,
                .render_x = self.pen_x + @as(f32, @floatFromInt(glyph.xoffset)),
                .render_y = self.pen_y + @as(f32, @floatFromInt(glyph.yoffset)),
            };

            // 4. Step the layout pen forward for the subsequent character
            self.pen_x += @as(f32, @floatFromInt(glyph.xadvance));
            self.prev_char_id = char_id;

            return item;
        }
        return null;
    }
};
