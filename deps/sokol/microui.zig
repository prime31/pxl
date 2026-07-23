const std = @import("std");
const sg = @import("sokol").app;

// render methods
pub extern var mu_ctx: mu_Context;

pub fn setup() void {
    r_init();
}

pub fn handleEvent(ev: [*c]const sg.Event) void {
    r_event(ev);
}

pub fn render() void {
    r_frame();
}

extern fn r_init() void;
extern fn r_event(ev: [*c]const sg.Event) void;
extern fn r_frame() void;

// microui
const __root = @This();
pub const MU_CLIP_PART: c_int = 1;
pub const MU_CLIP_ALL: c_int = 2;
const enum_unnamed_1 = c_uint;
pub const MU_COMMAND_JUMP: c_int = 1;
pub const MU_COMMAND_CLIP: c_int = 2;
pub const MU_COMMAND_RECT: c_int = 3;
pub const MU_COMMAND_TEXT: c_int = 4;
pub const MU_COMMAND_ICON: c_int = 5;
pub const MU_COMMAND_MAX: c_int = 6;
const enum_unnamed_2 = c_uint;
pub const MU_COLOR_TEXT: c_int = 0;
pub const MU_COLOR_BORDER: c_int = 1;
pub const MU_COLOR_WINDOWBG: c_int = 2;
pub const MU_COLOR_TITLEBG: c_int = 3;
pub const MU_COLOR_TITLETEXT: c_int = 4;
pub const MU_COLOR_PANELBG: c_int = 5;
pub const MU_COLOR_BUTTON: c_int = 6;
pub const MU_COLOR_BUTTONHOVER: c_int = 7;
pub const MU_COLOR_BUTTONFOCUS: c_int = 8;
pub const MU_COLOR_BASE: c_int = 9;
pub const MU_COLOR_BASEHOVER: c_int = 10;
pub const MU_COLOR_BASEFOCUS: c_int = 11;
pub const MU_COLOR_SCROLLBASE: c_int = 12;
pub const MU_COLOR_SCROLLTHUMB: c_int = 13;
pub const MU_COLOR_MAX: c_int = 14;
const enum_unnamed_3 = c_uint;
pub const MU_ICON_CLOSE: c_int = 1;
pub const MU_ICON_CHECK: c_int = 2;
pub const MU_ICON_COLLAPSED: c_int = 3;
pub const MU_ICON_EXPANDED: c_int = 4;
pub const MU_ICON_MAX: c_int = 5;
const enum_unnamed_4 = c_uint;
pub const MU_RES_ACTIVE: c_int = 1;
pub const MU_RES_SUBMIT: c_int = 2;
pub const MU_RES_CHANGE: c_int = 4;
const enum_unnamed_5 = c_uint;
pub const MU_OPT_ALIGNCENTER: c_int = 1;
pub const MU_OPT_ALIGNRIGHT: c_int = 2;
pub const MU_OPT_NOINTERACT: c_int = 4;
pub const MU_OPT_NOFRAME: c_int = 8;
pub const MU_OPT_NORESIZE: c_int = 16;
pub const MU_OPT_NOSCROLL: c_int = 32;
pub const MU_OPT_NOCLOSE: c_int = 64;
pub const MU_OPT_NOTITLE: c_int = 128;
pub const MU_OPT_HOLDFOCUS: c_int = 256;
pub const MU_OPT_AUTOSIZE: c_int = 512;
pub const MU_OPT_POPUP: c_int = 1024;
pub const MU_OPT_CLOSED: c_int = 2048;
pub const MU_OPT_EXPANDED: c_int = 4096;
const enum_unnamed_6 = c_uint;
pub const MU_MOUSE_LEFT: c_int = 1;
pub const MU_MOUSE_RIGHT: c_int = 2;
pub const MU_MOUSE_MIDDLE: c_int = 4;
const enum_unnamed_7 = c_uint;
pub const MU_KEY_SHIFT: c_int = 1;
pub const MU_KEY_CTRL: c_int = 2;
pub const MU_KEY_ALT: c_int = 4;
pub const MU_KEY_BACKSPACE: c_int = 8;
pub const MU_KEY_RETURN: c_int = 16;
const enum_unnamed_8 = c_uint;
pub const mu_Font = ?*anyopaque;
pub const mu_Context = struct_mu_Context;
pub const mu_Id = c_uint;
const struct_unnamed_9 = extern struct {
    idx: c_int = 0,
    items: [262144]u8 = @import("std").mem.zeroes([262144]u8),
};
const struct_unnamed_10 = extern struct {
    idx: c_int = 0,
    items: [32][*c]mu_Container = @import("std").mem.zeroes([32][*c]mu_Container),
};
const struct_unnamed_11 = extern struct {
    idx: c_int = 0,
    items: [32][*c]mu_Container = @import("std").mem.zeroes([32][*c]mu_Container),
};
const struct_unnamed_12 = extern struct {
    idx: c_int = 0,
    items: [32]mu_Rect = @import("std").mem.zeroes([32]mu_Rect),
};
const struct_unnamed_13 = extern struct {
    idx: c_int = 0,
    items: [32]mu_Id = @import("std").mem.zeroes([32]mu_Id),
};
const struct_unnamed_14 = extern struct {
    idx: c_int = 0,
    items: [16]mu_Layout = @import("std").mem.zeroes([16]mu_Layout),
};
pub const struct_mu_Context = extern struct {
    text_width: ?*const fn (font: mu_Font, str: [*c]const u8, len: c_int) callconv(.c) c_int = null,
    text_height: ?*const fn (font: mu_Font) callconv(.c) c_int = null,
    draw_frame: ?*const fn (ctx: [*c]mu_Context, rect: mu_Rect, colorid: c_int) callconv(.c) void = null,
    _style: mu_Style = @import("std").mem.zeroes(mu_Style),
    style: [*c]mu_Style = null,
    hover: mu_Id = 0,
    focus: mu_Id = 0,
    last_id: mu_Id = 0,
    last_rect: mu_Rect = @import("std").mem.zeroes(mu_Rect),
    last_zindex: c_int = 0,
    updated_focus: c_int = 0,
    frame: c_int = 0,
    hover_root: [*c]mu_Container = null,
    next_hover_root: [*c]mu_Container = null,
    scroll_target: [*c]mu_Container = null,
    number_edit_buf: [127]u8 = @import("std").mem.zeroes([127]u8),
    number_edit: mu_Id = 0,
    command_list: struct_unnamed_9 = @import("std").mem.zeroes(struct_unnamed_9),
    root_list: struct_unnamed_10 = @import("std").mem.zeroes(struct_unnamed_10),
    container_stack: struct_unnamed_11 = @import("std").mem.zeroes(struct_unnamed_11),
    clip_stack: struct_unnamed_12 = @import("std").mem.zeroes(struct_unnamed_12),
    id_stack: struct_unnamed_13 = @import("std").mem.zeroes(struct_unnamed_13),
    layout_stack: struct_unnamed_14 = @import("std").mem.zeroes(struct_unnamed_14),
    container_pool: [48]mu_PoolItem = @import("std").mem.zeroes([48]mu_PoolItem),
    containers: [48]mu_Container = @import("std").mem.zeroes([48]mu_Container),
    treenode_pool: [48]mu_PoolItem = @import("std").mem.zeroes([48]mu_PoolItem),
    mouse_pos: mu_Vec2 = @import("std").mem.zeroes(mu_Vec2),
    last_mouse_pos: mu_Vec2 = @import("std").mem.zeroes(mu_Vec2),
    mouse_delta: mu_Vec2 = @import("std").mem.zeroes(mu_Vec2),
    scroll_delta: mu_Vec2 = @import("std").mem.zeroes(mu_Vec2),
    mouse_down: c_int = 0,
    mouse_pressed: c_int = 0,
    key_down: c_int = 0,
    key_pressed: c_int = 0,
    input_text: [32]u8 = @import("std").mem.zeroes([32]u8),
    pub const mu_init = __root.mu_init;
    pub const mu_begin = __root.mu_begin;
    pub const mu_end = __root.mu_end;
    pub const mu_set_focus = __root.mu_set_focus;
    pub const mu_get_id = __root.mu_get_id;
    pub const mu_push_id = __root.mu_push_id;
    pub const mu_pop_id = __root.mu_pop_id;
    pub const mu_push_clip_rect = __root.mu_push_clip_rect;
    pub const mu_pop_clip_rect = __root.mu_pop_clip_rect;
    pub const mu_get_clip_rect = __root.mu_get_clip_rect;
    pub const mu_check_clip = __root.mu_check_clip;
    pub const mu_get_current_container = __root.mu_get_current_container;
    pub const mu_get_container = __root.mu_get_container;
    pub const mu_bring_to_front = __root.mu_bring_to_front;
    pub const mu_pool_init = __root.mu_pool_init;
    pub const mu_pool_get = __root.mu_pool_get;
    pub const mu_pool_update = __root.mu_pool_update;
    pub const mu_input_mousemove = __root.mu_input_mousemove;
    pub const mu_input_mousedown = __root.mu_input_mousedown;
    pub const mu_input_mouseup = __root.mu_input_mouseup;
    pub const mu_input_scroll = __root.mu_input_scroll;
    pub const mu_input_keydown = __root.mu_input_keydown;
    pub const mu_input_keyup = __root.mu_input_keyup;
    pub const mu_input_text = __root.mu_input_text;
    pub const mu_push_command = __root.mu_push_command;
    pub const mu_next_command = __root.mu_next_command;
    pub const mu_set_clip = __root.mu_set_clip;
    pub const mu_draw_rect = __root.mu_draw_rect;
    pub const mu_draw_box = __root.mu_draw_box;
    pub const mu_draw_text = __root.mu_draw_text;
    pub const mu_draw_icon = __root.mu_draw_icon;
    pub const mu_layout_row = __root.mu_layout_row;
    pub const mu_layout_width = __root.mu_layout_width;
    pub const mu_layout_height = __root.mu_layout_height;
    pub const mu_layout_begin_column = __root.mu_layout_begin_column;
    pub const mu_layout_end_column = __root.mu_layout_end_column;
    pub const mu_layout_set_next = __root.mu_layout_set_next;
    pub const mu_layout_next = __root.mu_layout_next;
    pub const mu_draw_control_frame = __root.mu_draw_control_frame;
    pub const mu_draw_control_text = __root.mu_draw_control_text;
    pub const mu_mouse_over = __root.mu_mouse_over;
    pub const mu_update_control = __root.mu_update_control;
    pub const mu_text = __root.mu_text;
    pub const mu_label = __root.mu_label;
    pub const mu_button_ex = __root.mu_button_ex;
    pub const mu_checkbox = __root.mu_checkbox;
    pub const mu_textbox_raw = __root.mu_textbox_raw;
    pub const mu_textbox_ex = __root.mu_textbox_ex;
    pub const mu_slider_ex = __root.mu_slider_ex;
    pub const mu_number_ex = __root.mu_number_ex;
    pub const mu_header_ex = __root.mu_header_ex;
    pub const mu_begin_treenode_ex = __root.mu_begin_treenode_ex;
    pub const mu_end_treenode = __root.mu_end_treenode;
    pub const mu_begin_window_ex = __root.mu_begin_window_ex;
    pub const mu_end_window = __root.mu_end_window;
    pub const mu_open_popup = __root.mu_open_popup;
    pub const mu_begin_popup = __root.mu_begin_popup;
    pub const mu_end_popup = __root.mu_end_popup;
    pub const mu_begin_panel_ex = __root.mu_begin_panel_ex;
    pub const mu_end_panel = __root.mu_end_panel;
    pub const init = __root.mu_init;
    pub const begin = __root.mu_begin;
    pub const end = __root.mu_end;
    pub const id = __root.mu_get_id;
    pub const rect = __root.mu_push_clip_rect;
    pub const clip = __root.mu_check_clip;
    pub const container = __root.mu_get_current_container;
    pub const front = __root.mu_bring_to_front;
    pub const get = __root.mu_pool_get;
    pub const update = __root.mu_pool_update;
    pub const mousemove = __root.mu_input_mousemove;
    pub const mousedown = __root.mu_input_mousedown;
    pub const mouseup = __root.mu_input_mouseup;
    pub const scroll = __root.mu_input_scroll;
    pub const keydown = __root.mu_input_keydown;
    pub const keyup = __root.mu_input_keyup;
    pub const text = __root.mu_input_text;
    pub const command = __root.mu_push_command;
    pub const box = __root.mu_draw_box;
    pub const icon = __root.mu_draw_icon;
    pub const row = __root.mu_layout_row;
    pub const width = __root.mu_layout_width;
    pub const height = __root.mu_layout_height;
    pub const column = __root.mu_layout_begin_column;
    pub const next = __root.mu_layout_set_next;
    pub const over = __root.mu_mouse_over;
    pub const control = __root.mu_update_control;
    pub const label = __root.mu_label;
    pub const ex = __root.mu_button_ex;
    pub const checkbox = __root.mu_checkbox;
    pub const raw = __root.mu_textbox_raw;
    pub const treenode = __root.mu_end_treenode;
    pub const window = __root.mu_end_window;
    pub const popup = __root.mu_open_popup;
    pub const panel = __root.mu_end_panel;
};
pub const mu_Real = f32;
pub const mu_Vec2 = extern struct {
    x: c_int = 0,
    y: c_int = 0,
};
pub const mu_Rect = extern struct {
    x: c_int = 0,
    y: c_int = 0,
    w: c_int = 0,
    h: c_int = 0,
};
pub const mu_Color = extern struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 0,
};
pub const mu_PoolItem = extern struct {
    id: mu_Id = 0,
    last_update: c_int = 0,
};
pub const mu_BaseCommand = extern struct {
    type: c_int = 0,
    size: c_int = 0,
};
pub const mu_JumpCommand = extern struct {
    base: mu_BaseCommand = @import("std").mem.zeroes(mu_BaseCommand),
    dst: ?*anyopaque = null,
};
pub const mu_ClipCommand = extern struct {
    base: mu_BaseCommand = @import("std").mem.zeroes(mu_BaseCommand),
    rect: mu_Rect = @import("std").mem.zeroes(mu_Rect),
};
pub const mu_RectCommand = extern struct {
    base: mu_BaseCommand = @import("std").mem.zeroes(mu_BaseCommand),
    rect: mu_Rect = @import("std").mem.zeroes(mu_Rect),
    color: mu_Color = @import("std").mem.zeroes(mu_Color),
};
pub const mu_TextCommand = extern struct {
    base: mu_BaseCommand = @import("std").mem.zeroes(mu_BaseCommand),
    font: mu_Font = null,
    pos: mu_Vec2 = @import("std").mem.zeroes(mu_Vec2),
    color: mu_Color = @import("std").mem.zeroes(mu_Color),
    str: [1]u8 = @import("std").mem.zeroes([1]u8),
};
pub const mu_IconCommand = extern struct {
    base: mu_BaseCommand = @import("std").mem.zeroes(mu_BaseCommand),
    rect: mu_Rect = @import("std").mem.zeroes(mu_Rect),
    id: c_int = 0,
    color: mu_Color = @import("std").mem.zeroes(mu_Color),
};
pub const mu_Command = extern union {
    type: c_int,
    base: mu_BaseCommand,
    jump: mu_JumpCommand,
    clip: mu_ClipCommand,
    rect: mu_RectCommand,
    text: mu_TextCommand,
    icon: mu_IconCommand,
};
pub const mu_Layout = extern struct {
    body: mu_Rect = @import("std").mem.zeroes(mu_Rect),
    next: mu_Rect = @import("std").mem.zeroes(mu_Rect),
    position: mu_Vec2 = @import("std").mem.zeroes(mu_Vec2),
    size: mu_Vec2 = @import("std").mem.zeroes(mu_Vec2),
    max: mu_Vec2 = @import("std").mem.zeroes(mu_Vec2),
    widths: [16]c_int = @import("std").mem.zeroes([16]c_int),
    items: c_int = 0,
    item_index: c_int = 0,
    next_row: c_int = 0,
    next_type: c_int = 0,
    indent: c_int = 0,
};
pub const mu_Container = extern struct {
    head: [*c]mu_Command = null,
    tail: [*c]mu_Command = null,
    rect: mu_Rect = @import("std").mem.zeroes(mu_Rect),
    body: mu_Rect = @import("std").mem.zeroes(mu_Rect),
    content_size: mu_Vec2 = @import("std").mem.zeroes(mu_Vec2),
    scroll: mu_Vec2 = @import("std").mem.zeroes(mu_Vec2),
    zindex: c_int = 0,
    open: c_int = 0,
};
pub const mu_Style = extern struct {
    font: mu_Font = null,
    size: mu_Vec2 = @import("std").mem.zeroes(mu_Vec2),
    padding: c_int = 0,
    spacing: c_int = 0,
    indent: c_int = 0,
    title_height: c_int = 0,
    scrollbar_size: c_int = 0,
    thumb_size: c_int = 0,
    colors: [14]mu_Color = @import("std").mem.zeroes([14]mu_Color),
};

pub extern fn mu_vec2(x: c_int, y: c_int) mu_Vec2;
pub extern fn mu_rect(x: c_int, y: c_int, w: c_int, h: c_int) mu_Rect;
pub extern fn mu_color(r: c_int, g: c_int, b: c_int, a: c_int) mu_Color;

pub fn init() void {
    mu_init(&mu_ctx);
}
extern fn mu_init(ctx: [*c]mu_Context) void;

pub fn begin() void {
    mu_begin(&mu_ctx);
}
extern fn mu_begin(ctx: [*c]mu_Context) void;

pub fn end() void {
    mu_end(&mu_ctx);
}
extern fn mu_end(ctx: [*c]mu_Context) void;

pub fn setFocus(id: mu_Id) void {
    mu_set_focus(&mu_ctx, id);
}
extern fn mu_set_focus(ctx: [*c]mu_Context, id: mu_Id) void;

pub fn getId(data: ?*const anyopaque, size: c_int) mu_Id {
    return mu_get_id(&mu_ctx, data, size);
}
extern fn mu_get_id(ctx: [*c]mu_Context, data: ?*const anyopaque, size: c_int) mu_Id;

pub fn pushId(data: ?*const anyopaque, size: c_int) void {
    mu_push_id(&mu_ctx, data, size);
}
extern fn mu_push_id(ctx: [*c]mu_Context, data: ?*const anyopaque, size: c_int) void;

pub fn popId() void {
    mu_pop_id(&mu_ctx);
}
extern fn mu_pop_id(ctx: [*c]mu_Context) void;

pub fn pushClipRect(rect: mu_Rect) void {
    mu_push_clip_rect(&mu_ctx, rect);
}
extern fn mu_push_clip_rect(ctx: [*c]mu_Context, rect: mu_Rect) void;

pub fn popClipRect() void {
    mu_pop_clip_rect(&mu_ctx);
}
extern fn mu_pop_clip_rect(ctx: [*c]mu_Context) void;

pub fn getClipRect() mu_Rect {
    mu_get_clip_rect(&mu_ctx);
}
extern fn mu_get_clip_rect(ctx: [*c]mu_Context) mu_Rect;

pub fn checkClip(r: mu_Rect) bool {
    return mu_check_clip(&mu_ctx, r) == 1;
}
extern fn mu_check_clip(ctx: [*c]mu_Context, r: mu_Rect) c_int;

pub fn getCurrentContainer() [*c]mu_Container {
    return mu_get_current_container(&mu_ctx);
}
extern fn mu_get_current_container(ctx: [*c]mu_Context) [*c]mu_Container;

pub fn getContainer(name: [*c]const u8) [*c]mu_Container {
    return mu_get_container(&mu_ctx, name);
}
extern fn mu_get_container(ctx: [*c]mu_Context, name: [*c]const u8) [*c]mu_Container;

pub fn bringToFront(cnt: [*c]mu_Container) void {
    mu_bring_to_front(&mu_ctx, cnt);
}
extern fn mu_bring_to_front(ctx: [*c]mu_Context, cnt: [*c]mu_Container) void;

pub fn poolInit(items: [*c]mu_PoolItem, len: c_int, id: mu_Id) c_int {
    return mu_pool_init(&mu_ctx, items, len, id);
}
extern fn mu_pool_init(ctx: [*c]mu_Context, items: [*c]mu_PoolItem, len: c_int, id: mu_Id) c_int;

pub fn poolGet(items: [*c]mu_PoolItem, len: c_int, id: mu_Id) c_int {
    return mu_pool_get(&mu_ctx, items, len, id);
}
extern fn mu_pool_get(ctx: [*c]mu_Context, items: [*c]mu_PoolItem, len: c_int, id: mu_Id) c_int;

pub fn poolUpdate(items: [*c]mu_PoolItem, idx: c_int) void {
    mu_pool_update(&mu_ctx, items, idx);
}
extern fn mu_pool_update(ctx: [*c]mu_Context, items: [*c]mu_PoolItem, idx: c_int) void;

pub fn inputMousemove(x: c_int, y: c_int) void {
    mu_input_mousemove(&mu_ctx, x, y);
}
extern fn mu_input_mousemove(ctx: [*c]mu_Context, x: c_int, y: c_int) void;

pub fn inputMousedown(x: c_int, y: c_int, btn: c_int) void {
    mu_input_mousedown(&mu_ctx, x, y, btn);
}
extern fn mu_input_mousedown(ctx: [*c]mu_Context, x: c_int, y: c_int, btn: c_int) void;

pub fn inputMouseup(x: c_int, y: c_int, btn: c_int) void {
    mu_input_mouseup(&mu_ctx, x, y, btn);
}
extern fn mu_input_mouseup(ctx: [*c]mu_Context, x: c_int, y: c_int, btn: c_int) void;

pub fn inputScroll(x: c_int, y: c_int) void {
    mu_input_scroll(&mu_ctx, x, y);
}
extern fn mu_input_scroll(ctx: [*c]mu_Context, x: c_int, y: c_int) void;

pub fn inputKeydown(key: c_int) void {
    mu_input_keydown(&mu_ctx, key);
}
extern fn mu_input_keydown(ctx: [*c]mu_Context, key: c_int) void;

pub fn inputKeyup(key: c_int) void {
    mu_input_keyup(&mu_ctx, key);
}
extern fn mu_input_keyup(ctx: [*c]mu_Context, key: c_int) void;

pub fn inputText(txt: [*c]const u8) void {
    mu_input_text(&mu_ctx, txt);
}
extern fn mu_input_text(ctx: [*c]mu_Context, text: [*c]const u8) void;

pub fn pushCommand(@"type": c_int, size: c_int) [*c]mu_Command {
    return mu_push_command(&mu_ctx, @"type", size);
}
extern fn mu_push_command(ctx: [*c]mu_Context, @"type": c_int, size: c_int) [*c]mu_Command;

pub fn nextCommand(cmd: [*c][*c]mu_Command) c_int {
    return mu_next_command(&mu_ctx, cmd);
}
extern fn mu_next_command(ctx: [*c]mu_Context, cmd: [*c][*c]mu_Command) c_int;

pub fn setClip(rect: mu_Rect) void {
    mu_set_clip(&mu_ctx, rect);
}
extern fn mu_set_clip(ctx: [*c]mu_Context, rect: mu_Rect) void;

pub fn drawRect(rect: mu_Rect, color: mu_Color) void {
    mu_draw_rect(&mu_ctx, rect, color);
}
extern fn mu_draw_rect(ctx: [*c]mu_Context, rect: mu_Rect, color: mu_Color) void;

pub fn drawBox(rect: mu_Rect, color: mu_Color) void {
    mu_draw_box(&mu_ctx, rect, color);
}
extern fn mu_draw_box(ctx: [*c]mu_Context, rect: mu_Rect, color: mu_Color) void;

pub fn drawText(font: mu_Font, str: [*c]const u8, len: c_int, pos: mu_Vec2, color: mu_Color) void {
    mu_draw_text(&mu_ctx, font, str, len, pos, color);
}
extern fn mu_draw_text(ctx: [*c]mu_Context, font: mu_Font, str: [*c]const u8, len: c_int, pos: mu_Vec2, color: mu_Color) void;

pub fn drawIcon(id: c_int, rect: mu_Rect, color: mu_Color) void {
    mu_draw_icon(&mu_ctx, id, rect, color);
}
extern fn mu_draw_icon(ctx: [*c]mu_Context, id: c_int, rect: mu_Rect, color: mu_Color) void;

pub fn layoutRow(items: c_int, widths: [*c]const c_int, height: c_int) void {
    mu_layout_row(&mu_ctx, items, widths, height);
}
extern fn mu_layout_row(ctx: [*c]mu_Context, items: c_int, widths: [*c]const c_int, height: c_int) void;

pub fn layoutWidth(width: c_int) void {
    mu_layout_width(&mu_ctx, width);
}
extern fn mu_layout_width(ctx: [*c]mu_Context, width: c_int) void;

pub fn layoutHeight(height: c_int) void {
    mu_layout_height(&mu_ctx, height);
}
extern fn mu_layout_height(ctx: [*c]mu_Context, height: c_int) void;

pub fn layoutBeginColumn() void {
    mu_layout_begin_column(&mu_ctx);
}
extern fn mu_layout_begin_column(ctx: [*c]mu_Context) void;

pub fn layoutEndColumn() void {
    mu_layout_end_column(&mu_ctx);
}
extern fn mu_layout_end_column(ctx: [*c]mu_Context) void;

pub fn layoutSetNext(r: mu_Rect, relative: c_int) void {
    mu_layout_set_next(&mu_ctx, r, relative);
}
extern fn mu_layout_set_next(ctx: [*c]mu_Context, r: mu_Rect, relative: c_int) void;

pub fn layoutNext() mu_Rect {
    mu_layout_next(&mu_ctx);
}
extern fn mu_layout_next(ctx: [*c]mu_Context) mu_Rect;

pub fn drawControlFrame(id: mu_Id, rect: mu_Rect, colorid: c_int, opt: c_int) void {
    mu_draw_control_frame(&mu_ctx, id, rect, colorid, opt);
}
extern fn mu_draw_control_frame(ctx: [*c]mu_Context, id: mu_Id, rect: mu_Rect, colorid: c_int, opt: c_int) void;

pub fn drawControlText(str: [*c]const u8, rect: mu_Rect, colorid: c_int, opt: c_int) void {
    mu_draw_control_text(&mu_ctx, str, rect, colorid, opt);
}
extern fn mu_draw_control_text(ctx: [*c]mu_Context, str: [*c]const u8, rect: mu_Rect, colorid: c_int, opt: c_int) void;

pub fn mouseOver(rect: mu_Rect) c_int {
    mu_mouse_over(&mu_ctx, rect);
}
extern fn mu_mouse_over(ctx: [*c]mu_Context, rect: mu_Rect) c_int;

pub fn updateControl(id: mu_Id, rect: mu_Rect, opt: c_int) void {
    mu_update_control(&mu_ctx, id, rect, opt);
}
extern fn mu_update_control(ctx: [*c]mu_Context, id: mu_Id, rect: mu_Rect, opt: c_int) void;

pub fn text(txt: [*c]const u8) void {
    mu_text(&mu_ctx, txt);
}
extern fn mu_text(ctx: [*c]mu_Context, txt: [*c]const u8) void;

pub fn label(txt: [*c]const u8) void {
    mu_label(&mu_ctx, txt);
}
extern fn mu_label(ctx: [*c]mu_Context, txt: [*c]const u8) void;

pub fn buttonEx(label_txt: [*c]const u8, icon: c_int, opt: c_int) c_int {
    mu_button_ex(&mu_ctx, label_txt, icon, opt);
}
extern fn mu_button_ex(ctx: [*c]mu_Context, label_txt: [*c]const u8, icon: c_int, opt: c_int) c_int;

pub fn checkbox(label_txt: [*c]const u8, state: [*c]c_int) c_int {
    mu_checkbox(&mu_ctx, label_txt, state);
}
extern fn mu_checkbox(ctx: [*c]mu_Context, label_txt: [*c]const u8, state: [*c]c_int) c_int;

pub fn textboxRaw(buf: [*c]u8, bufsz: c_int, id: mu_Id, r: mu_Rect, opt: c_int) c_int {
    mu_textbox_raw(&mu_ctx, buf, bufsz, id, r, opt);
}
extern fn mu_textbox_raw(ctx: [*c]mu_Context, buf: [*c]u8, bufsz: c_int, id: mu_Id, r: mu_Rect, opt: c_int) c_int;

pub fn textboxEx(buf: [*c]u8, bufsz: c_int, opt: c_int) c_int {
    mu_textbox_ex(&mu_ctx, buf, bufsz, opt);
}
extern fn mu_textbox_ex(ctx: [*c]mu_Context, buf: [*c]u8, bufsz: c_int, opt: c_int) c_int;

pub fn sliderEx(value: [*c]mu_Real, low: mu_Real, high: mu_Real, step: mu_Real, fmt: [*c]const u8, opt: c_int) c_int {
    return mu_slider_ex(&mu_ctx, value, low, high, step, fmt, opt);
}
extern fn mu_slider_ex(ctx: [*c]mu_Context, value: [*c]mu_Real, low: mu_Real, high: mu_Real, step: mu_Real, fmt: [*c]const u8, opt: c_int) c_int;

pub fn numberEx(value: [*c]mu_Real, step: mu_Real, fmt: [*c]const u8, opt: c_int) c_int {
    return mu_number_ex(&mu_ctx, value, step, fmt, opt);
}
extern fn mu_number_ex(ctx: [*c]mu_Context, value: [*c]mu_Real, step: mu_Real, fmt: [*c]const u8, opt: c_int) c_int;

pub fn headerEx(label_txt: [*c]const u8, opt: c_int) bool {
    return mu_header_ex(&mu_ctx, label_txt, opt) == 1;
}
extern fn mu_header_ex(ctx: [*c]mu_Context, label_txt: [*c]const u8, opt: c_int) c_int;

pub fn beginTreenodeEx(label_txt: [*c]const u8, opt: c_int) bool {
    mu_begin_treenode_ex(&mu_ctx, label_txt, opt) == 1;
}
extern fn mu_begin_treenode_ex(ctx: [*c]mu_Context, label_txt: [*c]const u8, opt: c_int) c_int;

pub fn endTreenode() void {
    mu_end_treenode(&mu_ctx);
}
extern fn mu_end_treenode(ctx: [*c]mu_Context) void;

pub fn beginWindowEx(title: [*c]const u8, rect: mu_Rect, opt: c_int) bool {
    return mu_begin_window_ex(&mu_ctx, title, rect, opt) == 1;
}
extern fn mu_begin_window_ex(ctx: [*c]mu_Context, title: [*c]const u8, rect: mu_Rect, opt: c_int) c_int;

pub fn endWindow() void {
    mu_end_window(&mu_ctx);
}
extern fn mu_end_window(ctx: [*c]mu_Context) void;

pub fn openPopup(name: [*c]const u8) void {
    mu_open_popup(&mu_ctx, name);
}
extern fn mu_open_popup(ctx: [*c]mu_Context, name: [*c]const u8) void;

pub fn beginPopup(name: [*c]const u8) c_int {
    return mu_begin_popup(&mu_ctx, name) == 1;
}
extern fn mu_begin_popup(ctx: [*c]mu_Context, name: [*c]const u8) c_int;

pub fn endPopup() void {
    mu_end_popup(&mu_ctx);
}
extern fn mu_end_popup(ctx: [*c]mu_Context) void;

pub fn beginPanelEx(name: [*c]const u8, opt: c_int) void {
    mu_begin_panel_ex(&mu_ctx, name, opt);
}
extern fn mu_begin_panel_ex(ctx: [*c]mu_Context, name: [*c]const u8, opt: c_int) void;

pub fn endPanel() void {
    mu_end_panel(&mu_ctx);
}
extern fn mu_end_panel(ctx: [*c]mu_Context) void;
