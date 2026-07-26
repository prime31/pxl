const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;
const mu = pxl.mu;
const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;

var ps: pxl.ParticleSystem = undefined;

var emitter: pxl.EmitterParams = .{
    .position = .init(512, 500),
    .spawn_area = .init(10, 0),
    .lifetime_min = 0.8,
    .lifetime_max = 1.6,
    .speed_min = 80,
    .speed_max = 200,
    .angle_min = -std.math.pi * 0.65,
    .angle_max = -std.math.pi * 0.35,
    .accel = .init(0, 120), // gravity
    .size_start_min = 6.0,
    .size_start_max = 12.0,
    .size_end_min = 0.0,
    .size_end_max = 2.0,
    .color_start = Color.gold,
    .color_end = Color.fromRgba(1.0, 0.1, 0.1, 0.0),
    .blend_mode = .add,
};

var is_fountain_active: bool = true;

pub fn main(init: std.process.Init) !void {
    try pxl.run(init, .{
        .setup = setup,
        .update = update,
        .render = render,
        .shutdown = shutdown,
        .gfx = .{
            .clear_color = Color.dark_gray,
        },
    });
}

fn setup() !void {
    ps = pxl.ParticleSystem.init(5000);
}

fn shutdown() !void {
    ps.deinit();
}

fn update() !void {
    const dt = pxl.time.dt();

    // Continuous emitter
    if (is_fountain_active) {
        ps.emit(emitter, 8);
    }

    // Spawn explosion burst on mouse click
    if (pxl.input.mousePressed(.left)) { // and !mu.isMouseCaptured()
        const mouse = pxl.input.mousePosVec();
        const explosion: pxl.EmitterParams = .{
            .position = mouse,
            .lifetime_min = 0.4,
            .lifetime_max = 1.0,
            .speed_min = 100,
            .speed_max = 350,
            .angle_min = 0,
            .angle_max = std.math.tau,
            .size_start_min = 5.0,
            .size_start_max = 10.0,
            .size_end_min = 0.0,
            .size_end_max = 1.0,
            .color_start = Color.sky_blue,
            .color_end = Color.fromRgba(0.8, 0.2, 1.0, 0.0),
            .blend_mode = .add,
        };
        ps.emit(explosion, 120);
    }

    // Update particle simulation
    ps.update(dt);

    // MicroUI Control Window
    if (mu.beginWindowEx("Particle Controls", .{ .x = 10, .y = 10, .w = 260, .h = 280 }, .{ .align_center = false })) {
        mu.layoutRow(2, &[_]c_int{ 100, -1 }, 0);

        mu.label("Fountain On:");
        _ = mu.checkbox("", &is_fountain_active);

        mu.label("Speed Min:");
        _ = mu.sliderEx(&emitter.speed_min, 10, 300, 5, "%.0f", .{});

        mu.label("Speed Max:");
        _ = mu.sliderEx(&emitter.speed_max, 50, 600, 5, "%.0f", .{});

        mu.label("Life Min:");
        _ = mu.sliderEx(&emitter.lifetime_min, 0.1, 3.0, 0.1, "%.1f", .{});

        mu.label("Life Max:");
        _ = mu.sliderEx(&emitter.lifetime_max, 0.2, 5.0, 0.1, "%.1f", .{});

        mu.label("Gravity:");
        _ = mu.sliderEx(&emitter.accel.y, -200, 400, 10, "%.0f", .{});

        mu.label("Active Count:");
        var buf: [32]u8 = undefined;
        const count_str = std.fmt.bufPrintZ(&buf, "{d}", .{ps.active_count}) catch "0";
        mu.label(count_str);

        if (mu.buttonEx("Burst (500)", .none, .{})) {
            var burst = emitter;
            burst.speed_min = 150;
            burst.speed_max = 400;
            ps.emit(burst, 500);
        }

        mu.endWindow();
    }
}

fn render() !void {
    pxl.beginPass(.{
        .clear_color = Color.fromBytes(20, 20, 30, 255),
    });

    // Draw background grid lines
    var x: f32 = 0;
    while (x <= pxl.sapp.widthf()) : (x += 40) {
        api.drawLine(.init(x, 0), .init(x, pxl.sapp.heightf()), 1, Color.fromRgba(0.2, 0.2, 0.25, 1));
    }
    var y: f32 = 0;
    while (y <= pxl.sapp.heightf()) : (y += 40) {
        api.drawLine(.init(0, y), .init(pxl.sapp.widthf(), y), 1, Color.fromRgba(0.2, 0.2, 0.25, 1));
    }

    // Draw particle system
    ps.draw();

    pxl.endPass();
}
