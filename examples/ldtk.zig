const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;
const mu = pxl.mu;
const input = pxl.input;

const LDtk = pxl.tilemap.LDtk;
const Color = pxl.math.Color;

var map: *LDtk = undefined;
var player: pxl.tilemap.Player = .{};
var camera: pxl.Camera = .{
    .position = .init(160, 90),
    .zoom = 1.0,
    .rotation = 0,
};


/// Renders "yes" when a collision-state bool is set, otherwise "-".
fn stateMark(b: bool) []const u8 {
    return if (b) "yes" else "-";
}

pub fn config() pxl.Config {
    return .{
        .win = .{
            .width = 640 * 2,
            .height = 360 * 2,
        },
        .gfx = .{
            .design_width = 640,
            .design_height = 360,
            .resolution_policy = .show_all_pixel_perfect,
        },
    };
}

pub fn setup() !void {
    map = try pxl.assets.loadTilemap(.tiny_tiles);

    const grid_size: f32 = @floatFromInt(map.root.defs.?.tilesets[0].tileGridSize);
    player.rect.w = grid_size;
    player.rect.h = grid_size;
    player.layer = map.root.levels[0].layerInstances.?[1];

    input.addBinding("left", .key(.left));
    input.addBinding("left", .key(.a));
    input.addBinding("left", .gamepadButton(.dpad_left));
    input.addBinding("left", .gamepadAxis(.left_stick_left));

    input.addBinding("right", .key(.right));
    input.addBinding("right", .key(.d));
    input.addBinding("right", .gamepadButton(.dpad_right));
    input.addBinding("right", .gamepadAxis(.left_stick_right));

    input.addBinding("up", .key(.up));
    input.addBinding("up", .key(.w));
    input.addBinding("up", .gamepadButton(.dpad_up));
    input.addBinding("up", .gamepadAxis(.left_stick_up));

    input.addBinding("down", .key(.down));
    input.addBinding("down", .key(.s));
    input.addBinding("down", .gamepadButton(.dpad_down));
    input.addBinding("down", .gamepadAxis(.left_stick_down));
}

pub fn update() !void {
    // `.square` keeps the fractional analog magnitude (unlike `.digital`, which
    // would snap everything to 1.0 and throw away sub-pixel joystick input).
    const move = input.getVector("left", "right", "up", "down", .square);
    player.move(map, move);

    if (mu.beginWindowEx("Camera Controls", .{ .x = 10, .y = 10, .w = 220, .h = 300 }, .{ .align_center = false })) {
        mu.layoutRow(2, &[_]c_int{ 95, -1 }, 0);

        mu.label("Pos X:");
        _ = mu.slider(&camera.position.x, 0, 700, 1);

        mu.label("Pos Y:");
        _ = mu.slider(&camera.position.y, -175, 500, 1);

        mu.label("Zoom:");
        _ = mu.slider(&camera.zoom, 0.5, 4.0, 0.1);

        mu.label("Pixel Perfect:");
        _ = mu.checkbox("Pixel Perfect", &player.state.pixel_perfect);

        mu.label("Speed:");
        _ = mu.slider(&player.speed, 10, 400, 1);

        // --- Collision state ---
        mu.layoutRow(1, &[_]c_int{ -1, -1 }, 0);
        var st_buf: [24]u8 = undefined;

        mu.label((std.fmt.bufPrintZ(&st_buf, "right   {s}", .{stateMark(player.state.right)}) catch unreachable).ptr);
        mu.label((std.fmt.bufPrintZ(&st_buf, "left    {s}", .{stateMark(player.state.left)}) catch unreachable).ptr);
        mu.label((std.fmt.bufPrintZ(&st_buf, "below   {s}", .{stateMark(player.state.below)}) catch unreachable).ptr);
        mu.label((std.fmt.bufPrintZ(&st_buf, "above   {s}", .{stateMark(player.state.above)}) catch unreachable).ptr);
        mu.label((std.fmt.bufPrintZ(&st_buf, "wasGround  {s}", .{stateMark(player.state.was_grounded_last_frame)}) catch unreachable).ptr);
        mu.label((std.fmt.bufPrintZ(&st_buf, "justLanded {s}", .{stateMark(player.state.became_grounded_this_frame)}) catch unreachable).ptr);

        mu.endWindow();
    }
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = Color.aya, .camera = camera });
    for (map.root.levels) |level| pxl.tilemap.renderLevel(map, level, true);
    api.drawRect(player.rect.pos(), player.rect.size(), Color.orange);
    pxl.endPass();
}

pub fn shutdown() !void {
    pxl.assets.destroy(map);
}
