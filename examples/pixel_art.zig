const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;
const mu = pxl.mu;

var ferris: pxl.gpu.Texture = undefined;
var camera: pxl.Camera = .{
    .position = .init(160, 90),
    .zoom = 1.0,
    .rotation = 0,
};

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        .update = update,
        .render = render,
        .shutdown = shutdown,
        .gfx = .{
            .design_width = 320,
            .design_height = 180,
            .resolution_policy = .show_all_pixel_perfect,
        },
    });
}

fn setup() !void {
    ferris = try pxl.gpu.Texture.initFromFile("examples/assets/ferris_smol.png");
}

fn shutdown() !void {
    ferris.deinit();
}

fn update() !void {
    if (mu.beginWindowEx("Camera Controls", .{ .x = 10, .y = 10, .w = 200, .h = 160 }, .{ .align_center = false })) {
        mu.layoutRow(2, &[_]c_int{ 75, -1 }, 0);

        mu.label("Pos X:");
        _ = mu.sliderEx(&camera.position.x, 0, 320, 1, "%.0f", .{});

        mu.label("Pos Y:");
        _ = mu.sliderEx(&camera.position.y, 0, 180, 1, "%.0f", .{});

        mu.label("Zoom:");
        _ = mu.sliderEx(&camera.zoom, 0.5, 4.0, 0.1, "%.1f", .{});

        mu.label("Rotation:");
        _ = mu.sliderEx(&camera.rotation, -3.14, 3.14, 0.05, "%.2f", .{});

        mu.endWindow();
    }
}

fn render() !void {
    pxl.beginPass(.{
        .action = .clear,
        .camera = camera,
    });

    // Draw background grid lines
    var x: f32 = 0;
    while (x <= 320) : (x += 20) {
        api.drawLine(.init(x, 0), .init(x, 180), 1, pxl.math.Color.fromRgba(0.25, 0.25, 0.25, 1));
    }
    var y: f32 = 0;
    while (y <= 180) : (y += 20) {
        api.drawLine(.init(0, y), .init(320, y), 1, pxl.math.Color.fromRgba(0.25, 0.25, 0.25, 1));
    }

    // Draw center rect & pixel art ferris
    api.drawRect(.init(160, 90), .init(40, 40), pxl.math.Color.sky_blue);
    api.drawSprite(.{
        .texture = ferris,
        .transform = .{
            .pos = .init(160, 90),
            .origin = .center,
        },
    });

    // Draw a point in world space under mouse cursor using screenToWorld
    const mouse_design = pxl.input.mousePosScaledVec();
    const mouse_world = camera.screenToWorld(mouse_design);
    api.drawPoint(mouse_world, pxl.math.Color.lime, 4);

    pxl.endPass();
}
