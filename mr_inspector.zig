//! Uses Dear ImGUI and Zig's comptime reflection to automatically generate UIs for Zig types.
//! Intended for creating inspectors for game engines or other productivity tools, but may be
//! generally useful.
//!
//! See `README.md` for additional info and example usage.
//!
//! ## Terminology
//! * Property: A label paired with a control. May have child properties.
//! * Label: The text displaying the name of a property.
//! * Control: The UI displaying the value of a property, potentially allowing for edits.


const std = @import("std");
const im = @import("dear_imgui");
const assert = std.debug.assert;

const mr_inspector = @This();

const dbg_grid = false;

/// You may use this from the thread issuing Dear ImGUI calls to format strings. Note though that
/// you shouldn't use it for anything recursive, such as labels, as the drawing of other controls
/// may clobber it!
pub var str_buf: [128:0]u8 = undefined;

/// Prints a null terminated string, or "[truncated]" if the result can't fit. The whole string is
/// replaced rather than printing a partial string or returning an error for easy of use, and to
/// avoid printing garbage when reflecting a struct that contains a large byte buffer.
pub fn bufPrintZ(buf: []u8, comptime fmt: []const u8, args: anytype) [:0]u8 {
    return std.fmt.bufPrintSentinel(buf, fmt, args, 0) catch
        return std.fmt.bufPrintSentinel(&str_buf, "[truncated]", .{}, 0) catch
            unreachable;
}

/// A table of properties.
pub const Table = struct {
    /// Begin a property table.
    pub fn begin(id: [:0]const u8) ?@This() {
        const result = im.beginTable(id, 2, .{
            .borders_inner_h = dbg_grid,
            .borders_outer_h = dbg_grid,
            .borders_inner_v = dbg_grid,
            .borders_outer_v = dbg_grid,
            .row_bg = dbg_grid,
            .no_saved_settings = true,
        });
        if (result) {
            im.tableSetupColumn("Label", .{});
            im.tableSetupColumn("Control", .{});
        }
        return if (result) .{} else null;
    }

    /// End the current property table.
    pub fn end(_: @This()) void {
        im.endTable();
    }
};

/// Options for UI generation. See `DefaultCtx`.
pub const Options = struct {
    /// Structs with more than this many fields are drawn with `drawUnknown`.
    ///
    /// Dear ImGUI is plenty fast, but putting a limit on this value prevents the compiler from
    /// instantiating lots unnecessary information.
    ///
    /// For example, the motivating use case for adding this flag was to avoid generating code to
    /// reflect every field of a vtable containing a massive number of Vulkan functions, as this
    /// slightly slowed down incremental compilation.
    max_fields: usize = 64,
    /// Array or slices with more than this many items are drawn with `drawUnknown`.
    ///
    /// Dear ImGUI is plenty fast, but putting a limit on this value decreases the chance of
    /// rendering nonhuman readable buffers into this UI when reflecting arbitrary structs.
    max_items: usize = 16,
    /// Strings with more than this many bytes are drawn as `"[truncated]"`.
    ///
    /// Dear ImGUI is plenty fast, but putting a limit on this value decreases the chance of
    /// rendering byte buffers to the UI when reflecting arbitrary structs.
    max_str_len: usize = 64,
};

/// A default implementation of the property context. You may create your own context with
/// additional fields and a modified `drawProperty` to override how different types are
/// reflected to the UI.
pub const DefaultCtx = struct {
    /// The context must provide a public options constant with this signature.
    pub const options: Options = .{};

    /// The context must have a public method with this signature.
    pub fn drawProperty(ctx: @This(), Ptr: type, prop: *Property(@This(), Ptr)) void {
        // Calling `prop.drawDefault` invokes the default handling for this type. In your own
        // implementation, you may want to first switch on `Property(Ptr).T` or its type
        // info. See `drawDefault` as an example of this.
        //
        // When designing custom controls, allowing the value to affect the height of the control
        // is strongly discouraged as it disrupts the user's scrolling experience.
        return prop.drawDefault(ctx);
    }

    /// Returns the default value or a type.
    pub fn defaultValue(T: type, opt: DefaultValueOptions) ?T {
        return mr_inspector.defaultValue(@This(), T, opt);
    }
};

/// Options for `defaultValue`.
pub const DefaultValueOptions = struct {
    /// Don't return null default value for options. Useful for checkboxes that toggle optionals.
    non_null: bool = false,
};

/// The default implementation of `defaultValue` for a type. Not meant to be called directly outside
/// of a context implementation, see `DeafaultCtx`.
pub fn defaultValue(Ctx: type, T: type, opt: DefaultValueOptions) ?T {
    switch (@typeInfo(T)) {
        // All numbers default to 0
        .type => return null,
        .void => return {},
        .bool => return false,
        .int, .float, .comptime_float, .comptime_int => {
            return 0;
        },
        .@"enum" => {
            if (std.enums.fromInt(T, 0)) |zero| {
                return zero;
            }
            const values = std.enums.values(T);
            if (values.len == 0) return null;
            return values[0];
        },
        .array => |info| {
            return @splat(Ctx.defaultValue(info.child, .{}) orelse return null);
        },
        .@"struct" => |info| {
            var result: T = undefined;
            inline for (info.field_names, info.field_types, info.field_attrs) |name, F, attrs| {
                @field(result, name) = b: {
                    if (attrs.defaultValue(F)) |default| break :b default;
                    if (Ctx.defaultValue(F, .{})) |default| break :b default;
                    return null;
                };
            }
            return result;
        },
        .@"union" => |info| {
            inline for (info.field_names, info.field_types) |name, F| {
                if (Ctx.defaultValue(F, .{})) |default| {
                    return @unionInit(T, name, default);
                }
            }
            return null;
        },
        .null => return null,
        .optional => |info| if (opt.non_null) {
            return Ctx.defaultValue(info.child, .{});
        } else {
            return @as(T, null);
        },
        .vector => |info| return @splat(Ctx.defaultValue(info.child, .{}) orelse return null),
        .pointer,
        .noreturn,
        .undefined,
        .error_union,
        .error_set,
        .@"fn",
        .@"opaque",
        .frame,
        .@"anyframe",
        .enum_literal,
        .spirv,
        => return null,
    }
}

/// Draws a property, returning true if it was modified.
pub fn property(
    /// User context type, or a pointer to the user context type. See `DefaultCtx`.
    Ctx: type,
    /// The user context instance. See `DefaultCtx` for an example/reasonable default.
    ctx: Ctx,
    /// The type of the pointer to the property value.
    Ptr: type,
    /// A pointer to the data, or `null` to draw the property without any data. This can be useful
    /// to avoid changing the height of the UI when content is added/removed.
    ptr: ?Ptr,
    /// Runtime options.
    options: Property(Ctx, Ptr).InitOptions,
) bool {
    var prop: Property(Ctx, Ptr) = .init(ptr, options);
    return prop.draw(ctx);
}

/// See `property`.
pub fn Property(Ctx: type, Ptr: type) type {
    return struct {
        /// Whether or not the pointer is optional.
        pub const is_optional = @typeInfo(@typeInfo(Ptr).pointer.child) == .optional;

        /// The non-optional value type.
        pub const Value = switch (@typeInfo(@typeInfo(Ptr).pointer.child)) {
            .optional => |info| info.child,
            else => @typeInfo(Ptr).pointer.child,
        };

        /// See `InitOptions`.
        want_inline: bool,
        /// See `InitOptions`.
        label: [:0]const u8,
        /// See `property`.
        ptr: ?Ptr,
        /// See `InitOptions`.
        default_value_ptr: ?*const @typeInfo(Ptr).pointer.child,
        /// See `InitOptions`.
        default_open_depth: usize,
        /// Set to true if the user modified this property.
        modified: bool,

        /// Options for `init`.
        pub const InitOptions = struct {
            /// The property label. Has no effect when inlined.
            label: [:0]const u8,
            /// Requests that the label row be elided if supported by the property type. This will,
            /// for example, render structs as a list of children rather than a tree node containing
            /// a list of children. Useful if you've already created the parent node e.g. via
            /// `header`.
            want_inline: bool = false,
            /// The default value pointer, if any. If this property points to an optional, this
            /// value is filled in by default if the user checks the optional.
            default_value_ptr: ?*const @typeInfo(Ptr).pointer.child,
            /// How many levels deep to auto open tree nodes. The UI can tolerate recursion, but in
            /// the event of recursion, setting this limit too high will eventually overflow your
            /// stack.
            default_open_depth: usize = 0,
        };

        /// Creates a new property. See also `property`.
        pub fn init(ptr: ?Ptr, options: InitOptions) @This() {
            return .{
                .ptr = ptr,
                .label = options.label,
                .want_inline = options.want_inline,
                .default_value_ptr = options.default_value_ptr,
                .default_open_depth = options.default_open_depth,
                .modified = false,
            };
        }

        /// Draws the property, returning `true` if it was modified.
        pub fn draw(self: *@This(), ctx: Ctx) bool {
            comptime assert(@TypeOf(Ctx.options) == Options);
            ctx.drawProperty(Ptr, self);
            return self.modified;
        }

        /// The default implementation for `drawProperty`. Your custom override may call into
        /// this function to draw any types it doesn't want to override.
        pub fn drawDefault(prop: *@This(), ctx: Ctx) void {
            const options: Options = Ctx.options;
            switch (@typeInfo(Value)) {
                .int => |info| if (prop.beginLeaf()) |draw_prop| {
                    defer draw_prop.end();
                    const pot = comptime std.math.ceilPowerOfTwoAssert(u16, @max(info.bits, 8));
                    const CType = @Int(info.signedness, pot);
                    const ty: im.DataType = switch (pot) {
                        8 => if (info.signedness == .unsigned) .u8 else .s8,
                        16 => if (info.signedness == .unsigned) .u16 else .s16,
                        32 => if (info.signedness == .unsigned) .u32 else .s32,
                        64 => if (info.signedness == .unsigned) .u64 else .s64,
                        else => {
                            const str = bufPrintZ(&str_buf, "{}", .{prop.orDefault(0)});

                            im.beginDisabled(true);
                            defer im.endDisabled();
                            im.setNextItemWidth(-1);
                            _ = im.inputText(
                                "##text",
                                @ptrCast(str),
                                str.len + 1,
                                .{
                                    .read_only = true,
                                    .auto_select_all = true,
                                },
                            );
                            return;
                        },
                    };
                    var val: CType = prop.orDefault(0);
                    im.setNextItemWidth(-1);
                    if (im.dragScalarEx(
                        "##number",
                        ty,
                        &val,
                        1,
                        &@as(CType, std.math.minInt(Value)),
                        &@as(CType, std.math.maxInt(Value)),
                        null,
                        .{
                            .clamp_on_input = true,
                            .clamp_zero_range = true,
                        },
                    )) {
                        prop.set(@intCast(val));
                    }
                },
                .float => |info| if (prop.beginLeaf()) |draw_prop| {
                    defer draw_prop.end();
                    const CType, const ty = if (info.bits <= 32)
                        .{ f32, .float }
                    else
                        .{ f64, .double };
                    var val: CType = @floatCast(prop.orDefault(0));
                    im.setNextItemWidth(-1);
                    if (im.dragScalarEx(
                        "##number",
                        ty,
                        &val,
                        1,
                        null,
                        null,
                        null,
                        .{
                            .clamp_on_input = true,
                            .clamp_zero_range = true,
                        },
                    )) {
                        prop.set(@floatCast(val));
                    }
                },
                .bool => if (prop.beginLeaf()) |draw_prop| {
                    defer draw_prop.end();
                    var checked = prop.orDefault(false);
                    if (im.checkbox("##bool", &checked)) {
                        prop.set(checked);
                    }
                },
                .array => |info| {
                    if (info.len > options.max_items) return prop.drawUnknown();
                    const draw_prop = prop.begin(.{ .children = .fixed(info.len) });
                    defer draw_prop.end();
                    if (draw_prop.beginChildren()) |draw_children| {
                        defer draw_children.end();
                        for (0..info.len) |idx| {
                            // Use a stack buffer here since we're going to recurse, the formatter
                            // gracefully handles if it's too short
                            var label_buf: [32]u8 = undefined;
                            prop.drawItem(ctx, &label_buf, idx);
                        }
                    }
                },
                .@"enum" => |info| if (prop.beginLeaf()) |draw_prop| {
                    defer draw_prop.end();
                    const current_str = if (prop.getVal()) |e|
                        std.enums.tagName(Value, e.*) orelse bufPrintZ(
                            &str_buf,
                            "0x{x}",
                            .{@intFromEnum(e.*)},
                        )
                    else
                        "";
                    im.setNextItemWidth(-1);
                    if (im.beginCombo("##enum", current_str, .{})) {
                        defer im.endCombo();
                        inline for (info.field_names, info.field_values) |field_name, field_value| {
                            im.beginDisabled(prop.getVal() == null);
                            defer im.endDisabled();
                            const is_selected = if (prop.getVal()) |e|
                                @intFromEnum(e.*) == field_value
                            else
                                false;
                            if (im.selectableEx(
                                field_name,
                                is_selected,
                                .{},
                                .{ .x = 0, .y = 0 },
                            )) {
                                prop.set(@enumFromInt(field_value));
                            }
                            if (is_selected) {
                                im.setItemDefaultFocus();
                            }
                        }
                    }
                },
                .pointer => |info| {
                    switch (@typeInfo(info.child)) {
                        .@"fn", .@"opaque" => return prop.drawUnknown(),
                        else => {},
                    }
                    switch (info.size) {
                        .one => if (prop.beginLeaf()) |draw_prop| {
                            defer draw_prop.end();
                            const child = if (prop.getVal()) |child| child.* else null;
                            const Child = @TypeOf(prop.getVal().?.*);
                            prop.drawChild(property(Ctx, ctx, Child, child, .{
                                .label = "ptr",
                                .want_inline = prop.want_inline,
                                .default_value_ptr = null,
                                .default_open_depth = prop.default_open_depth -| 1,
                            }));
                        },
                        .slice => if (info.child == u8) {
                            if (prop.beginLeaf()) |draw_prop| {
                                defer draw_prop.end();
                                if (prop.getVal()) |p| {
                                    const truncated = p.len > options.max_str_len;
                                    const str: []const u8 = if (truncated)
                                        "[truncated]"
                                    else
                                        @ptrCast(p.*);
                                    im.beginDisabled(truncated);
                                    defer im.endDisabled();
                                    if (info.sentinel() == 0) {
                                        im.beginDisabled(true);
                                        defer im.endDisabled();
                                        im.setNextItemWidth(-1);
                                        _ = im.inputText(
                                            "##text",
                                            @ptrCast(@constCast(str)),
                                            str.len + 1,
                                            .{
                                                .read_only = true,
                                                .auto_select_all = true,
                                            },
                                        );
                                    } else {
                                        im.textUnformattedEx(str.ptr, str.ptr + str.len);
                                    }
                                }
                            }
                        } else {
                            if (prop.getVal()) |p| {
                                if (p.len > options.max_items) {
                                    return prop.drawUnknown();
                                }
                            }
                            const draw_prop = prop.begin(.{ .children = .dynamic });
                            defer draw_prop.end();
                            if (draw_prop.beginChildren()) |draw_children| {
                                defer draw_children.end();
                                if (prop.getVal()) |p| {
                                    for (p.*, 0..) |*item_ptr, idx| {
                                        const item_label = bufPrintZ(&str_buf, "{}", .{idx});
                                        prop.drawChild(property(
                                            Ctx,
                                            ctx,
                                            @TypeOf(item_ptr),
                                            item_ptr,
                                            .{
                                                .label = item_label,
                                                .default_value_ptr = null,
                                                .default_open_depth = prop.default_open_depth -| 1,
                                            },
                                        ));
                                    }
                                }
                            }
                        },
                        .many, .c => if (prop.beginLeaf()) |draw_prop| {
                            defer draw_prop.end();
                            if (prop.getVal()) |p| {
                                const str = bufPrintZ(&str_buf, "{}", .{p});
                                im.textUnformattedEx(str.ptr, str.ptr + str.len);
                            }
                        },
                    }
                },
                inline .@"struct", .@"union" => |info| {
                    if (@typeInfo(Value) == .@"union" and info.tag_type == null) {
                        return prop.drawUnknown();
                    }
                    if (info.field_names.len > options.max_fields) {
                        return prop.drawUnknown();
                    }

                    const draw_prop = prop.begin(.{
                        .children = .fixed(info.field_names.len),
                        .no_inline = @typeInfo(Value) == .@"union",
                    });
                    defer draw_prop.end();
                    if (@typeInfo(Value) == .@"union") {
                        if (draw_prop.beginControl()) |draw_control| {
                            defer draw_control.end();
                            if (info.tag_type) |Tag| {
                                const tag_info = @typeInfo(Tag).@"enum";
                                const current_str = if (prop.getVal()) |p| @tagName(p.*) else "";
                                im.setNextItemWidth(-1);
                                if (im.beginCombo("##enum", current_str, .{})) {
                                    defer im.endCombo();
                                    inline for (
                                        tag_info.field_names,
                                        tag_info.field_values,
                                    ) |name, value| {
                                        const F = @FieldType(Value, name);
                                        const is_selected = if (prop.getVal()) |p|
                                            @intFromEnum(std.meta.activeTag(p.*)) == value
                                        else
                                            false;
                                        im.beginDisabled(!is_selected and comptime Ctx.defaultValue(F, .{}) == null);
                                        defer im.endDisabled();
                                        if (im.selectableEx(
                                            name,
                                            is_selected,
                                            .{},
                                            .{ .x = 0, .y = 0 },
                                        )) {
                                            if (!is_selected) {
                                                if (prop.ptr) |ptr| {
                                                    if (Ctx.defaultValue(F, .{})) |default| {
                                                        ptr.* = @unionInit(Value, name, default);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if (draw_prop.beginChildren()) |draw_children| {
                        defer draw_children.end();
                        inline for (info.field_names) |name| {
                            prop.drawField(ctx, name);
                        }
                    }
                },
                else => prop.drawUnknown(),
            }
        }

        /// Draw a properties type name without drawing its value. Called by `drawDefaultProperty`
        /// when it doesn't know how to draw a UI for the given type.
        pub fn drawUnknown(prop: *@This()) void {
            if (prop.beginLeaf()) |draw_prop| {
                defer draw_prop.end();
                im.beginDisabled(true);
                defer im.endDisabled();
                im.textUnformatted(@typeName(Value));
            }
        }
        /// Returns a property for the given field on this type, or null if this property is
        /// not set or this type is a union and the given field is not active. See also `drawField`.
        pub fn field(
            self: *const @This(),
            comptime name: [:0]const u8,
        ) Property(Ctx, @TypeOf(&@field(
            if (is_optional)
                self.ptr.?.*.?
            else
                self.ptr.?,
            name,
        ))) {
            const info = switch (@typeInfo(Value)) {
                inline .@"struct", .@"union" => |info| info,
                else => comptime unreachable,
            };
            const field_index = std.meta.fieldIndex(Value, name).?;
            const default_value_ptr: ?*const anyopaque = switch (@typeInfo(Value)) {
                .@"struct" => |struct_info| struct_info.field_attrs[field_index].default_value_ptr,
                else => null,
            };
            const active = switch (@typeInfo(Value)) {
                .@"struct" => true,
                .@"union" => b: {
                    if (info.tag_type == null) break :b false;
                    const ptr = self.getVal() orelse break :b false;
                    break :b std.meta.activeTag(ptr.*) == @field(std.meta.Tag(Value), name);
                },
                else => comptime unreachable,
            };
            none: {
                if (!active) break :none;
                const ptr = self.getVal() orelse break :none;
                return .init(&@field(ptr, name), .{
                    .label = name,
                    .default_value_ptr = @ptrCast(@alignCast(default_value_ptr)),
                    .default_open_depth = self.default_open_depth -| 1,
                });
            }
            return .init(null, .{
                .want_inline = false,
                .label = name,
                .default_value_ptr = @ptrCast(@alignCast(default_value_ptr)),
                .default_open_depth = self.default_open_depth -| 1,
            });
        }

        /// Draws a property for the named field. See also `field`.
        pub fn drawField(
            self: *@This(),
            ctx: Ctx,
            comptime name: [:0]const u8,
        ) void {
            var field_prop = self.field(name);
            self.drawChild(field_prop.draw(ctx));
        }

        /// Returns a property for the given item index. See also `drawItem`.
        pub fn item(self: *const @This(), label_buf: []u8, idx: usize) Property(Ctx, @TypeOf(
            if (is_optional)
                &self.ptr.?.*.?[idx]
            else
                &self.ptr.?[idx],
        )) {
            const label = bufPrintZ(label_buf, "{}", .{idx});
            none: {
                if (@typeInfo(std.meta.Child(Value)) == .optional) {
                    const ptr = self.getVal() orelse break :none;
                    return .init(&ptr[idx], .{
                        .label = label,
                        .default_value_ptr = null,
                        .default_open_depth = self.default_open_depth -| 1,
                    });
                } else {
                    const ptr = self.getVal() orelse break :none;
                    return .init(&ptr[idx], .{
                        .label = label,
                        .default_value_ptr = null,
                        .default_open_depth = self.default_open_depth -| 1,
                    });
                }
            }
            return .init(null, .{
                .want_inline = false,
                .label = label,
                .default_value_ptr = null,
                .default_open_depth = self.default_open_depth -| 1,
            });
        }

        /// Draws the item at `idx`. See also `item`.
        pub fn drawItem(self: *@This(), ctx: Ctx, label_buf: []u8, idx: usize) void {
            var item_prop = self.item(label_buf, idx);
            self.drawChild(item_prop.draw(ctx));
        }

        /// If `modified` is `true`, sets `self.modified` to true. Intended for chaining with
        /// drawing child properties, e.g. `prop.drawChild(child.draw(ctx))`.
        pub fn drawChild(self: *@This(), modified: bool) void {
            if (modified) self.modified = true;
        }

        /// Begins a property control for a property that has no children. See also `begin`.
        pub fn beginLeaf(self: *@This()) ?DrawLeaf {
            const draw_property = self.begin(.{ .children = .zero });
            const draw_control = draw_property.beginControl() orelse {
                draw_property.end();
                return null;
            };
            return .{
                .draw_property = draw_property,
                .draw_control = draw_control,
            };
        }

        /// The leaf property being drawn.
        pub const DrawLeaf = struct {
            draw_property: DrawProperty,
            draw_control: DrawControl,

            /// End the current leaf property.
            pub fn end(self: @This()) void {
                self.draw_control.end();
                self.draw_property.end();
            }
        };

        /// Options for `begin`.
        pub const BeginOptions = struct {
            /// How many children this property has.
            children: DrawProperty.Children,
            /// If true, this property is never inlined. You may want to set this for custom
            /// controls with a required label row.
            no_inline: bool = false,
        };

        /// Begins drawing the property. Unlike `beginLeaf`, you must use `beginControl` and
        /// `beginChildren` to create scopes for drawing the control and children respectively.
        /// Intended for use by `drawDefaultPropert`, `drawProperty`, etc. Automatically draws
        /// a checkbox control if `is_optional` is true.
        pub fn begin(self: *@This(), options: BeginOptions) DrawProperty {
            // Push our label so that controls are nested in unique scopes
            im.pushIDStr(self.label, self.label.ptr + self.label.len);

            const @"inline" =
                self.want_inline and
                !is_optional and
                options.children != .zero and
                !options.no_inline;
            const label_disabled = self.ptr == null; // If we don't have a value, disable the label
            const control_disabled =
                // If the label is disabled, disable the control
                label_disabled or
                // If the pointer is const, disable the control
                @typeInfo(Ptr).pointer.attrs.@"const" or
                // If the field is optional and null, disable the control
                self.isNull() == true or
                self.ptr == null;

            if (!@"inline") {
                im.tableNextRow();
                _ = im.tableSetColumnIndex(0);
            }

            const open = if (@"inline") true else b: {
                im.pushStyleColor(.header_hovered, 0x000000);
                im.pushStyleColor(.header_active, 0x000000);
                if (label_disabled) {
                    // We just disable the label, not the whole tree node, as we want to be able
                    // to interact with the arrow still.
                    const text_disabled_color = im.getColorU32(.text_disabled);
                    im.pushStyleColor(.text, text_disabled_color);
                }
                defer im.popStyleColorEx(2 + @as(c_int, @intFromBool(label_disabled)));
                im.alignTextToFramePadding();

                break :b im.treeNodeEx(self.label.ptr, .{
                    .leaf = options.children == .zero,
                    .draw_lines_full = true,
                    .default_open = options.children != .dynamic and self.default_open_depth > 0,
                    .span_avail_width = true,
                });
            };

            if (!@"inline") {
                _ = im.tableSetColumnIndex(1);
                self.optionalCheckbox();
            }

            return .{
                .open = open,
                .@"inline" = @"inline",
                .children = options.children,
                .control_disabled = control_disabled,
            };
        }

        /// The property being drawn.
        pub const DrawProperty = struct {
            open: bool,
            @"inline": bool = false,
            children: Children,
            control_disabled: bool,

            /// The number of children a property has.
            pub const Children = enum {
                /// This node always has 0 children.
                zero,
                /// This node always has a fixed nonzero number of children.
                nonzero,
                /// This node has a dynamic number of children. Use is discouraged as dynamically
                /// changing child counts will disrupt the user's scrolling experience. To mitigate
                /// this, nodes with dynamic child counts default to closed.
                dynamic,

                pub fn fixed(comptime c: usize) @This() {
                    if (c == 0) return .zero else return .nonzero;
                }
            };

            /// End the current property.
            pub fn end(self: @This()) void {
                if (self.open and !self.@"inline") im.treePop();
                im.popID();
            }

            /// Begins drawing the property's controls.
            pub fn beginControl(self: @This()) ?DrawControl {
                im.beginDisabled(self.control_disabled);
                return .{};
            }

            /// Begins drawing the property's children.
            pub fn beginChildren(self: @This()) ?DrawChildren {
                if (!self.open) return null;
                if (self.children == .zero) return null;
                return .{};
            }
        };

        /// The control being drawn.
        pub const DrawControl = struct {
            /// End the current control.
            pub fn end(_: @This()) void {
                im.endDisabled();
            }
        };

        /// The children being drawn.
        pub const DrawChildren = struct {
            /// End the current children.
            pub fn end(_: @This()) void {}
        };

        /// Gets a pointer to this property's value, or null if the property is not set or is set to
        /// null. This pointer may be const. For setting properties, see `set`.
        pub fn getVal(
            self: *const @This(),
        ) ?@TypeOf(
            if (@typeInfo(@TypeOf(self.ptr.?.*)) == .optional)
                &self.ptr.?.*.?
            else
                &self.ptr.?.*,
        ) {
            const ptr = self.ptr orelse return null;
            return switch (@typeInfo(@TypeOf(ptr.*))) {
                .optional => if (ptr.*) |*some| some else null,
                else => ptr,
            };
        }

        /// If this property is optional, returns true if it is null and false if it is not. Returns
        /// null if this property is not optional.
        pub fn isNull(self: *const @This()) ?bool {
            if (!is_optional) return null;
            const ptr = self.ptr orelse return true;
            return ptr.* == null;
        }

        /// Returns this property's value by value, or a default value if there is no value or the
        /// value is `null`.
        pub fn orDefault(self: *const @This(), default: Value) Value {
            return if (self.getVal()) |ptr| ptr.* else default;
        }

        /// If this property is mutable, sets it to the given value. If it is constant does nothing.
        /// See also `setNull`.
        pub fn set(self: *@This(), value: Value) void {
            if (@typeInfo(Ptr).pointer.attrs.@"const") return;
            const ptr = self.ptr orelse return;
            ptr.* = value;
            self.modified = true;
        }

        /// If this property is optional, sets it to `null`. Otherwise, does nothing.
        pub fn setNull(self: *@This()) void {
            if (@typeInfo(Ptr).pointer.attrs.@"const") return;
            if (!is_optional) return;
            const ptr = self.ptr orelse return;
            ptr.* = null;
            self.modified = true;
        }

        /// If this property is optional, draws a checkbox indicating whether it is set or
        /// not. If this property has a default value this checkbox will be interactive,
        /// otherwise it will be read only.
        pub fn optionalCheckbox(self: *@This()) void {
            im.beginDisabled(is_optional and
                (self.default_value_ptr == null or self.default_value_ptr.?.* == null) and
                comptime Ctx.defaultValue(Value, .{ .non_null = true }) == null);
            defer im.endDisabled();
            _ = self.optionalCheckboxToggled();
        }

        /// Similar to `optionalCheckbox`, but will be enabled even if there is no default
        /// value. Returns true or false to indicate the checkbox state when it is toggled.
        /// This allows the caller to react to changes in state, or to implement non-default
        /// instantiation of optionals by writing to `set` when true is returned.
        pub fn optionalCheckboxToggled(self: *@This()) ?bool {
            const Child = @typeInfo(Ptr).pointer.child;
            if (@typeInfo(Child) != .optional) return null;

            im.beginDisabled(@typeInfo(Ptr).pointer.attrs.@"const");
            defer im.endDisabled();

            var checked = !(self.isNull() orelse return null);
            const clicked = im.checkbox("##optional", &checked);
            im.sameLineEx(0, im.getStyle().?.item_inner_spacing.x);

            if (!clicked) return null;
            self.modified = true;
            if (checked) {
                if (!@typeInfo(Ptr).pointer.attrs.@"const") {
                    if (self.ptr) |ptr| {
                        if (self.default_value_ptr) |default_value_ptr| {
                            ptr.* = default_value_ptr.*;
                        }
                        if (ptr.* == null) {
                            ptr.* = Ctx.defaultValue(
                                @typeInfo(Child).optional.child,
                                .{ .non_null = true },
                            );
                        }
                    }
                }
            } else {
                self.setNull();
            }
            return checked;
        }
    };
}

/// Similar to `im.collapsingHeader`, but accepts a font. Intended for drawing headers with bold
/// text.
pub fn header(label: [:0]const u8, font: ?*im.Font, options: im.TreeNodeFlags) bool {
    if (font) |f| im.pushFontFloat(f, 0);
    defer if (font != null) im.popFont();
    return im.collapsingHeader(label.ptr, options);
}
