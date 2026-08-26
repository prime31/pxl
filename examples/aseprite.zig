const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;

const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const Rect = pxl.math.Rect;

var atlas: *pxl.gpu.Texture = undefined;
var meta: *const pxl.assets.AsepriteMeta = undefined;

var player: pxl.AnimationPlayer = .{};
var current_name: []const u8 = "";

// Bound tag ids: `*_loop` tags loop, everything else plays once.
var walk_anim: pxl.AnimationId = .none;
var run_anim: pxl.AnimationId = .none;
var attack_anim: pxl.AnimationId = .none;

// ---- editable polygon mesh (second robot) ----
// A quad with two extra verts mid-way down the left/right edges, so the mesh can
// be pinched/warped while still covering the same screen area as a plain quad.
const edit_vert_count = 6;
const edit_scale: f32 = 0.6;
const robot_gap: f32 = 30; // vertical gap between the two rendered robots
const drag_radius: f32 = 18; // how close a click must be to grab a handle
const drag_limit: f32 = 50; // max drag distance from a vert's default position

const edit_indices = [_]u16{ 0, 1, 4, 1, 5, 4, 4, 5, 3, 5, 2, 3 };

var edit_origin = Vec2.zero; // world-space top-left of the mesh
var edit_w: f32 = 0;
var edit_h: f32 = 0;
var edit_verts: [edit_vert_count]pxl.gpu.Vertex = undefined;
var edit_defaults: [edit_vert_count]Vec2 = undefined; // un-deformed positions, for clamping/reset
var edit_mesh: pxl.gpu.Mesh = undefined;
var dragging: ?usize = null;

fn anchorMesh(frame: pxl.gpu.animation.Frame) void {
    const fx = pxl.window.renderWidthf() * 0.5 - frame.source.w * edit_scale * 0.5;
    const fy = 40 + frame.source.h * edit_scale + robot_gap;
    edit_origin = .init(fx, fy);
    edit_w = frame.source.w * edit_scale;
    edit_h = frame.source.h * edit_scale;

    // vert order: TL, TR, BR, BL, mid-left, mid-right
    const positions = [edit_vert_count]Vec2{
        .init(edit_origin.x, edit_origin.y),
        .init(edit_origin.x + edit_w, edit_origin.y),
        .init(edit_origin.x + edit_w, edit_origin.y + edit_h),
        .init(edit_origin.x, edit_origin.y + edit_h),
        .init(edit_origin.x, edit_origin.y + edit_h * 0.5),
        .init(edit_origin.x + edit_w, edit_origin.y + edit_h * 0.5),
    };
    for (positions, 0..) |p, i| {
        edit_defaults[i] = p;
        edit_verts[i] = .{ .pos = p, .uv = Vec2.zero, .col = Color.white };
    }
}

/// Refresh the per-frame UVs (and texture) for the current animation frame.
/// Positions are kept, so a mid-drag deformation survives frame changes.
fn syncMeshUvs(src: Rect, tex: pxl.gpu.Texture) void {
    const tw: f32 = @floatFromInt(tex.width);
    const th: f32 = @floatFromInt(tex.height);
    const ul = (src.x + 0.5) / tw;
    const vt = (src.y + 0.5) / th;
    const ur = (src.x + src.w - 0.5) / tw;
    const vb = (src.y + src.h - 0.5) / th;
    const vm = (vt + vb) * 0.5;
    edit_verts[0].uv = .init(ul, vt);
    edit_verts[1].uv = .init(ur, vt);
    edit_verts[2].uv = .init(ur, vb);
    edit_verts[3].uv = .init(ul, vb);
    edit_verts[4].uv = .init(ul, vm);
    edit_verts[5].uv = .init(ur, vm);
    edit_mesh.texture = tex;
}

fn resetMesh() void {
    for (&edit_verts, 0..) |*v, i| v.pos = edit_defaults[i];
}

pub fn config() pxl.Config {
    return .{
        .win = .{
            .width = 720 * 2,
            .height = 400 * 2,
        },
        .gfx = .{
            .design_width = 720,
            .design_height = 400,
            .resolution_policy = .show_all_pixel_perfect,
        },
    };
}

pub fn setup() !void {
    atlas = try pxl.assets.loadAseprite(.character_robot);
    meta = pxl.assets.asepriteMeta(.character_robot);

    walk_anim = pxl.assets.animation(.character_robot_walk);
    run_anim = pxl.assets.animation(.character_robot_run);
    attack_anim = pxl.assets.animation(.character_robot_attack);

    player.playId(walk_anim);
    current_name = "walk (loop)";

    edit_mesh = .{
        .verts = &edit_verts,
        .indices = &edit_indices,
    };
    const frame = player.frame();
    anchorMesh(frame);
    syncMeshUvs(frame.source, frame.texture);
}

pub fn update() !void {
    if (pxl.input.keyPressed(.w)) {
        player.playId(walk_anim);
        current_name = "walk (loop)";
    } else if (pxl.input.keyPressed(.r)) {
        player.playId(run_anim);
        current_name = "run (loop)";
    } else if (pxl.input.keyPressed(.space)) {
        player.playId(attack_anim);
        current_name = "attack (once)";
    }

    player.update();
    if (player.finished()) {
        player.playId(walk_anim);
        current_name = "walk (loop)";
    }

    const frame = player.frame();
    syncMeshUvs(frame.source, frame.texture);

    if (pxl.input.keyPressed(.x)) resetMesh();

    // Click a handle to start dragging it; release to let go.
    const mouse = pxl.input.mousePosScaled();
    if (pxl.input.mousePressed(.left)) {
        dragging = null;
        var best_dist = drag_radius * drag_radius;
        for (edit_verts, 0..) |v, i| {
            const dx = mouse.x - v.pos.x;
            const dy = mouse.y - v.pos.y;
            const d2 = dx * dx + dy * dy;
            if (d2 < best_dist) {
                best_dist = d2;
                dragging = i;
            }
        }
    } else if (!pxl.input.mouseDown(.left)) {
        dragging = null;
    }

    if (dragging) |i| {
        const d = edit_defaults[i];
        edit_verts[i].pos = .init(
            std.math.clamp(mouse.x, d.x - drag_limit, d.x + drag_limit),
            std.math.clamp(mouse.y, d.y - drag_limit, d.y + drag_limit),
        );
    }
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = Color.fromBytes(11, 15, 22, 255) });

    const frame = player.frame();
    const scale: f32 = 0.6;
    const frame_x = pxl.window.renderWidthf() * 0.5 - frame.source.w * scale * 0.5;
    const frame_y: f32 = 40;
    api.drawTexturedRect(frame.texture, .{
        .x = frame_x,
        .y = frame_y,
        .w = frame.source.w * scale,
        .h = frame.source.h * scale,
    }, frame.source, Color.white);

    // Slice bounds are in sprite-canvas space, so scale them onto the drawn frame.
    for (meta.slices) |slice| {
        for (slice.keys) |key| {
            const pos = Vec2.init(
                frame_x + @as(f32, @floatFromInt(key.x)) * scale,
                frame_y + @as(f32, @floatFromInt(key.y)) * scale,
            );
            const size = Vec2.init(
                @as(f32, @floatFromInt(key.w)) * scale,
                @as(f32, @floatFromInt(key.h)) * scale,
            );
            api.drawRectOutline(pos, size, 2, Color.red);
            if (key.has_pivot) {
                const pivot = Vec2.init(
                    frame_x + key.pivot_x * scale,
                    frame_y + key.pivot_y * scale,
                );
                api.drawRect(Vec2.init(pivot.x - 3, pivot.y - 3), Vec2.init(6, 6), Color.yellow);
            }
        }
    }

    // Second robot: a custom 6-vert polygon pushed through a locally stored Mesh
    // instead of drawTexturedRect. Each vert can be dragged (clamped to ±50px).
    api.pushMesh(edit_mesh);

    // Circle-outline handles for every vert; the active one is highlighted.
    for (edit_verts, 0..) |v, i| {
        const col = if (dragging != null and dragging.? == i) Color.yellow else Color.green;
        api.drawCircleOutline(v.pos, 5, 1, 10, col);
    }

    // Full exported sheet, thumbnailed in the corner.
    api.drawTexturedRect(atlas.*, .{
        .x = 8,
        .y = 8,
        .w = @as(f32, @floatFromInt(meta.size_w)) / 8,
        .h = @as(f32, @floatFromInt(meta.size_h)) / 8,
    }, Rect.init(0, 0, @floatFromInt(atlas.width), @floatFromInt(atlas.height)), Color.white);

    var y: f32 = 8;
    var buf: [256]u8 = undefined;

    const info = std.fmt.bufPrint(&buf, "playing: {s}   tags: {d}   frames: {d}\n   layers: {d}   slices: {d}", .{
        current_name, meta.tags.len, meta.frames.len, meta.layers.len, meta.slices.len,
    }) catch unreachable;
    api.drawText(null, Vec2.init(pxl.window.renderWidthf() * 0.5 + 40, y), info, Color.white);
    y += 40;
    api.drawText(null, Vec2.init(10, y), "W walk, R run, SPACE attack, X reset mesh, drag handles", Color.white);

    pxl.endPass();
}
