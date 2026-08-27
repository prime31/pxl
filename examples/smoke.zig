// Smoke — a GPU compute-shader fluid simulation.
//
// Port of Sebastian Lague's Smoke Simulation (github.com/SebLague/Smoke-Simulation)
// to a single sokol compute pass (see shaders/fluid.glsl): a staggered (MAC)
// velocity grid, red-black SOR pressure solve, semi-Lagrangian advection,
// buoyancy, obstacle edge masking and a wind source, all on one 320x180 cell
// grid that maps 1:1 onto the design-resolution screen (like running the fluid
// unscaled at 320x180, the same trick Split82's game uses).
//
// The player walks through the tiny_tiles maze; its body heats the air, drags
// it along and leaves a smoke trail. The mouse is a second brush (left = blow,
// right = add smoke). Everything is tunable live through the microui panel.

const std = @import("std");
const pxl = @import("pxl");
const fluid = @import("fluid_shaders");

const api = pxl.api;
const mu = pxl.mu;
const input = pxl.input;
const sg = pxl.sg;

const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;
const Map = pxl.tilemap.Map;
const Texture = pxl.gpu.Texture;

// The fluid runs 1:1 with the visible design resolution (320x180), exactly like
// the reference game ("the game is rendered in 320x180, so I run the whole
// fluid simulation without scaling it down"). Each sim cell is one design pixel,
// upscaled 3x with nearest-neighbour sampling for the crisp pixel look.
const DESIGN_W = 320;
const DESIGN_H = 180;
const SIM_W = 320;
const SIM_H = 180;
const SIM_SCALE = @as(f32, SIM_W) / @as(f32, DESIGN_W); // design px -> sim px
const PX_PER_CELL = @as(f32, DESIGN_W) / @as(f32, SIM_W); // sim px -> design px

const PHASE_CLEAR = 0;
const PHASE_SEED = 1;
const PHASE_FORCES = 2;
const PHASE_BUOYANCY = 3;
const PHASE_INTERACTION = 4;
const PHASE_PRESSURE_PREP = 5;
const PHASE_PRESSURE_SOLVE = 6;
const PHASE_PRESSURE_APPLY = 7;
const PHASE_SMOKE_ADVECT = 8;
const PHASE_SMOKE_DIFFUSE = 9;
const PHASE_VEL_ADVECT = 10;
const PHASE_VEL_READBACK = 11;
const PHASE_DISPLAY = 12;
const PHASE_GRAVITY = 13;

var map: *Map = undefined;
var collision: pxl.tilemap.Layer = undefined;
var camera: pxl.Camera = .{ .position = .init(@floatFromInt(DESIGN_W / 2), @floatFromInt(DESIGN_H / 2)), .zoom = 1.0, .rotation = 0 };
var player: pxl.tilemap.Player = .{};
var player_prev: Vec2 = .{};

// ---- simulation tuning (live-editable) ----
const SimConfig = struct {
    paused: bool = false,
    step_rate: f32 = 60, // fixed sim steps per second
    time_scale: f32 = 1,
    pressure_iters: f32 = 40, // red-black passes (2 per iteration)
    max_velocity: f32 = 200,
    gravity: f32 = 40, // downward acceleration; +y is down on screen
    buoyancy_temp: f32 = 0.0,
    buoyancy_smoke: f32 = 1.0, // smoke weight multiplier for downward settling
    surface_slide: f32 = 1.0,
    wind: f32 = 0,
    smoke_decay: f32 = 0.08,
    temp_decay: f32 = 0.08,
    smoke_diffusion: f32 = 0.04,
    temp_diffusion: f32 = 0.4,
    ambient: f32 = 20,
    temp_rate: f32 = 3, // keep surface smoke from becoming a rising hot plume
    player_temp: f32 = 20, // surface smoke is ambient-temperature and should fall
    emit: f32 = 0.0, // tile edges are the only continuous smoke source
    brush_radius: f32 = 22,
    brush_strength: f32 = 3.2,
    brush_smoke: f32 = 4.0, // smoke density per second while right-dragging
    player_radius: f32 = 12,
    player_push: f32 = 2.0,
    disp_mode: i32 = 0, // 0 smoke, 1 temperature, 2 velocity, 3 divergence, 4 pressure
    show_panel: bool = false,
    vent_strength: f32 = 0.0, // tilemap edges are the primary smoke source
};

// Steam vents (design px): x, y, radius, smoke emission per second. Hot plumes
// rise off these spots, drift with the wind and curl around the maze walls.
const vents = [_][4]f32{
    .{ 60, 84, 16, 1.5 },
    .{ 240, 36, 16, 1.5 },
    .{ 36, 156, 16, 1.5 },
};

var cfg: SimConfig = .{};

// ---- GPU resources ----
const FieldId = enum(usize) { vel = 0, vel_adv, smoke, smoke_adv, pressure, disp };
const field_count = @typeInfo(FieldId).@"enum".fields.len;

var field_imgs: [field_count]sg.Image = @splat(.{});
var field_views: [field_count]sg.View = @splat(.{}); // storage-image views
var obstacle_tex: Texture = undefined;
var obstacle_view: sg.View = .{};
var obstacle_smp: sg.Sampler = .{};
var fluid_pip: sg.Pipeline = .{};
var compute_bind: sg.Bindings = .{};
var sim_u: fluid.SimUb = undefined;
var ctl_u: fluid.CtlUb = undefined;
var ctl2_u: fluid.Ctl2Ub = undefined;
var sim_time: f32 = 0;
var accumulator: f64 = 0;
var frame: i32 = 0;
var mouse_prev: Vec2 = .{};

pub fn config() pxl.Config {
    return .{
        .win = .{
            .width = DESIGN_W * 3,
            .height = DESIGN_H * 3,
        },
        .gfx = .{
            .design_width = DESIGN_W,
            .design_height = DESIGN_H,
            .resolution_policy = .show_all_pixel_perfect,
        },
    };
}

fn makeField(comptime id: FieldId) void {
    // Must mirror the layout() format qualifiers in shaders/fluid.glsl.
    const format: sg.PixelFormat = if (id == .disp) .RGBA8 else .RGBA32F;
    const img = sg.makeImage(.{
        .usage = .{ .storage_image = true },
        .width = SIM_W,
        .height = SIM_H,
        .pixel_format = format,
        .label = @tagName(id),
    });
    const view = sg.makeView(.{ .storage_image = .{ .image = img } });
    field_imgs[@intFromEnum(id)] = img;
    field_views[@intFromEnum(id)] = view;
}

// Edge directions, must match shaders/fluid.glsl.
const EDGE_LEFT = 0;
const EDGE_RIGHT = 1;
const EDGE_TOP = 2;
const EDGE_BOTTOM = 3;

/// Rasterize the IntGrid collision layer into a 1px-per-sim-cell obstacle mask.
/// r = solid, g = packed 4-bit edge case (bit n set = edge n is blocked).
/// The domain border is open on the top and right (like the reference's
/// openRightEdge/openTopEdge) so smoke flows out of the scene instead of
/// recirculating against the walls; left and bottom stay solid. Each sim cell
/// covers a PX_PER_CELL x PX_PER_CELL block of design pixels; a cell is solid
/// if any design pixel in its block is a wall.
fn buildObstacleMask() []u8 {
    const pixels = pxl.mem.alloc(u8, SIM_W * SIM_H * 4, .temp);
    @memset(pixels, 0);
    const solid = pxl.mem.alloc(u8, SIM_W * SIM_H, .temp);
    @memset(solid, 0);
    const tile: i32 = @intCast(map.tileSize());
    const cell_px: i32 = @intFromFloat(PX_PER_CELL);
    var solid_cells: usize = 0;

    var y: i32 = 0;
    while (y < SIM_H) : (y += 1) {
        var x: i32 = 0;
        while (x < SIM_W) : (x += 1) {
            const on_border = x == 0 or y == SIM_H - 1; // open top (y=0) + right (x=W-1)
            var is_wall = false;
            var dy: i32 = 0;
            while (dy < cell_px and !is_wall) : (dy += 1) {
                var dx: i32 = 0;
                while (dx < cell_px and !is_wall) : (dx += 1) {
                    const dpx = x * cell_px + dx;
                    const dpy = y * cell_px + dy;
                    const cx: u32 = @intCast(@divFloor(dpx, tile));
                    const cy: u32 = @intCast(@divFloor(dpy, tile));
                    if (collision.isCellSolid(cx, cy)) is_wall = true;
                }
            }
            if (on_border or is_wall) {
                solid[@as(usize, @intCast(y)) * SIM_W + @as(usize, @intCast(x))] = 1;
                solid_cells += 1;
            }
        }
    }

    var i: usize = 0;
    while (i < SIM_W * SIM_H) : (i += 1) {
        const x: i32 = @intCast(i % SIM_W);
        const cy: i32 = @intCast(i / SIM_W);
        const self = solid[i];
        const w = solid[@as(usize, @intCast(cy)) * SIM_W + @as(usize, @intCast(std.math.clamp(x - 1, 0, SIM_W - 1)))];
        const e = solid[@as(usize, @intCast(cy)) * SIM_W + @as(usize, @intCast(std.math.clamp(x + 1, 0, SIM_W - 1)))];
        const top = solid[@as(usize, @intCast(std.math.clamp(cy - 1, 0, SIM_H - 1))) * SIM_W + @as(usize, @intCast(x))];
        const bottom = solid[@as(usize, @intCast(std.math.clamp(cy + 1, 0, SIM_H - 1))) * SIM_W + @as(usize, @intCast(x))];
        const edge_case: u8 = (self | w) | ((self | e) << EDGE_RIGHT) |
            ((self | top) << EDGE_TOP) | ((self | bottom) << EDGE_BOTTOM);

        const px = i * 4;
        pixels[px] = self * 255;
        pixels[px + 1] = edge_case;
        pixels[px + 2] = 0;
        pixels[px + 3] = 255;
    }
    std.log.debug("obstacle mask: {d}/{d} px solid (layer {d}x{d} cells, tile {d})", .{ solid_cells, SIM_W * SIM_H, collision.width, collision.height, tile });
    return pixels;
}

pub fn setup() !void {
    map = try pxl.assets.loadTilemap(.tiny_tiles);
    collision = (map.findLayer("IntGrid") orelse return error.MissingCollisionLayer).*;

    player.rect = .{ .x = 140, .y = 90, .w = 10, .h = 10 };
    player.layer = collision;
    player.speed = 70;
    player_prev = player.rect.center();
    mouse_prev = input.mousePosScaled();

    // Same binding layout as the ldtk example: keys + gamepad.
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

    // GPU fields.
    inline for (@typeInfo(FieldId).@"enum".fields) |f| makeField(@enumFromInt(f.value));

    // Obstacle mask from the tilemap (walls + domain border, with edge cases).
    const mask = buildObstacleMask();
    obstacle_tex = Texture.initWithData(mask, SIM_W, SIM_H);
    obstacle_view = sg.makeView(.{ .texture = .{ .image = obstacle_tex.img } });
    obstacle_smp = sg.makeSampler(.{
        .min_filter = .NEAREST,
        .mag_filter = .NEAREST,
        .wrap_u = .CLAMP_TO_EDGE,
        .wrap_v = .CLAMP_TO_EDGE,
    });

    fluid_pip = sg.makePipeline(.{
        .compute = true,
        .shader = sg.makeShader(fluid.fluidShaderDesc(sg.queryBackend())),
        .label = "fluid-compute",
    });

    compute_bind = .{};
    compute_bind.views[fluid.VIEW_u_vel] = field_views[@intFromEnum(FieldId.vel)];
    compute_bind.views[fluid.VIEW_u_vel_adv] = field_views[@intFromEnum(FieldId.vel_adv)];
    compute_bind.views[fluid.VIEW_u_smoke] = field_views[@intFromEnum(FieldId.smoke)];
    compute_bind.views[fluid.VIEW_u_smoke_adv] = field_views[@intFromEnum(FieldId.smoke_adv)];
    compute_bind.views[fluid.VIEW_u_pressure] = field_views[@intFromEnum(FieldId.pressure)];
    compute_bind.views[fluid.VIEW_u_disp] = field_views[@intFromEnum(FieldId.disp)];
    compute_bind.views[fluid.VIEW_u_obstacle_tex] = obstacle_view;
    compute_bind.samplers[fluid.SMP_u_obstacle_smp] = obstacle_smp;

    // Uniform blocks (extern structs, so every field gets an explicit value).
    sim_u = .{
        .u_resolution = .init(SIM_W, SIM_H),
        .u_dt = 0,
        .u_time = 0,
        .u_gravity = cfg.gravity,
        .u_ambient = cfg.ambient,
        .u_temperature_diffusion = cfg.temp_diffusion,
        .u_temperature_decay = cfg.temp_decay,
        .u_temperature_rate = cfg.temp_rate,
        .u_smoke_diffusion = cfg.smoke_diffusion,
        .u_smoke_decay = cfg.smoke_decay,
        .u_buoyancy_temperature = cfg.buoyancy_temp,
        .u_buoyancy_smoke = cfg.buoyancy_smoke,
        .u_surface_slide = cfg.surface_slide,
        .u_edge_emission = 0.75,
        .u_wind_x = cfg.wind,
    };
    ctl_u = .{
        .u_smoke_r = 0.35,
        .u_smoke_g = 0.55,
        .u_smoke_b = 0.9,
        .u_max_velocity = cfg.max_velocity,
        .u_brush_centre = .{},
        .u_brush_delta = .{},
        .u_brush_radius = 0,
        .u_brush_strength = cfg.brush_strength,
        .u_brush_smoke = cfg.brush_smoke,
        .u_brush_add_smoke = 0,
        .u_brush_set_velocities = 0,
        .u_phase = PHASE_CLEAR,
        .u_pass_index = 0,
        .u_clear_pressure = 0, // warm-start the pressure solve from the previous frame
        .u_disp_mode = cfg.disp_mode,
        .u_player_on = 0,
    };
    ctl2_u = .{
        .u_player_pos = player.rect.center().scale(SIM_SCALE),
        .u_player_delta = .{},
        .u_player_radius = cfg.player_radius * SIM_SCALE,
        .u_player_push = cfg.player_push,
        .u_emit = 0,
        .u_player_temp = cfg.player_temp,
        .u_vent_temp = 27,
        .u_vents = .{ .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 }, .{ 0, 0, 0, 0 } },
    };

    dispatch(PHASE_CLEAR);
}

fn dispatch(phase: i32) void {
    ctl_u.u_phase = phase;
    sg.beginPass(.{ .compute = true });
    sg.applyPipeline(fluid_pip);
    sg.applyBindings(compute_bind);
    sg.applyUniforms(fluid.UB_sim_ub, sg.asRange(&sim_u));
    sg.applyUniforms(fluid.UB_ctl_ub, sg.asRange(&ctl_u));
    sg.applyUniforms(fluid.UB_ctl2_ub, sg.asRange(&ctl2_u));
    sg.dispatch(@divTrunc(SIM_W + 7, 8), @divTrunc(SIM_H + 7, 8), 1);
    sg.endPass();
}

fn clearSim() void {
    dispatch(PHASE_CLEAR);
}

/// One fixed-timestep simulation update.
fn runStep(dt: f32) void {
    sim_u.u_dt = dt;
    sim_time += dt;
    sim_u.u_time = sim_time;
    sim_u.u_gravity = cfg.gravity;
    sim_u.u_ambient = cfg.ambient;
    sim_u.u_temperature_diffusion = cfg.temp_diffusion;
    sim_u.u_temperature_decay = cfg.temp_decay;
    sim_u.u_temperature_rate = cfg.temp_rate;
    sim_u.u_smoke_diffusion = cfg.smoke_diffusion;
    sim_u.u_smoke_decay = cfg.smoke_decay;
    sim_u.u_buoyancy_temperature = cfg.buoyancy_temp;
    sim_u.u_buoyancy_smoke = cfg.buoyancy_smoke;
    sim_u.u_surface_slide = cfg.surface_slide;
    sim_u.u_edge_emission = 0.75;
    sim_u.u_wind_x = cfg.wind;
    ctl_u.u_max_velocity = cfg.max_velocity;

    // Player interaction (design px -> sim px, y-down).
    const pos = player.rect.center();
    const delta = pos.sub(player_prev);
    ctl2_u.u_player_pos = pos.scale(SIM_SCALE);
    ctl2_u.u_player_delta = delta.scale(cfg.player_push * SIM_SCALE);
    ctl2_u.u_player_radius = cfg.player_radius * SIM_SCALE;
    ctl_u.u_player_on = 1;
    const speed = delta.len() / @max(dt, 0.0001);
    ctl2_u.u_emit = cfg.emit * std.math.clamp(speed / 40.0, 0, 1.5);
    player_prev = pos;

    // Steam vents (position/radius fixed, strength tunable).
    for (vents, 0..) |v, i| {
        ctl2_u.u_vents[i] = .{ v[0] * SIM_SCALE, v[1] * SIM_SCALE, v[2] * SIM_SCALE, v[3] * cfg.vent_strength };
    }
    ctl2_u.u_vent_temp = 27;

    // Mouse brush (left = push, right = add smoke), design px -> sim px.
    const mouse = input.mousePosScaled();
    ctl_u.u_brush_centre = mouse.scale(SIM_SCALE);
    ctl_u.u_brush_delta = mouse.sub(mouse_prev).scale(cfg.brush_strength * SIM_SCALE);
    const brushing = input.mouseDown(.left) or input.mouseDown(.right);
    ctl_u.u_brush_radius = if (brushing) cfg.brush_radius * SIM_SCALE else 0;
    ctl_u.u_brush_add_smoke = if (input.mouseDown(.right)) 1 else 0;
    ctl_u.u_brush_set_velocities = if (input.mouseDown(.left)) 1 else 0;
    mouse_prev = mouse;

    dispatch(PHASE_FORCES);
    dispatch(PHASE_BUOYANCY);
    dispatch(PHASE_INTERACTION);

    // Pressure projection: precompute, then red-black Gauss-Seidel passes.
    dispatch(PHASE_PRESSURE_PREP);
    var pass_index: i32 = 0;
    const total_passes: i32 = @as(i32, @intFromFloat(cfg.pressure_iters)) * 2;
    while (pass_index < total_passes) : (pass_index += 1) {
        ctl_u.u_pass_index = pass_index;
        dispatch(PHASE_PRESSURE_SOLVE);
    }
    dispatch(PHASE_PRESSURE_APPLY);

    // Advection (smoke then velocity), diffusion, readback.
    dispatch(PHASE_SMOKE_ADVECT);
    dispatch(PHASE_SMOKE_DIFFUSE);
    dispatch(PHASE_VEL_ADVECT);
    dispatch(PHASE_VEL_READBACK);
}

fn drawPlayer() void {
    const r = player.rect;
    api.drawRect(.init(r.x, r.y), .init(r.w, r.h), Color.fromBytes(240, 170, 60, 255));
    api.drawRectOutline(.init(r.x, r.y), .init(r.w, r.h), 1, Color.fromBytes(30, 24, 18, 255));
    // little eyes so it reads as a creature
    api.drawRect(.init(r.x + 2, r.y + 3), .init(2, 2), Color.fromBytes(30, 24, 18, 255));
    api.drawRect(.init(r.x + r.w - 4, r.y + 3), .init(2, 2), Color.fromBytes(30, 24, 18, 255));
}

pub fn update() !void {
    frame += 1;

    // Movement (keys + gamepad), same binding layout as the ldtk example.
    const move = input.getVector("left", "right", "up", "down", .square);
    player.move(map, move);

    // Keep the player inside the visible viewport.
    player.rect.x = std.math.clamp(player.rect.x, 1, DESIGN_W - 1 - player.rect.w);
    player.rect.y = std.math.clamp(player.rect.y, 1, DESIGN_H - 1 - player.rect.h);

    if (input.keyPressed(.c)) clearSim();
    if (input.keyPressed(.space)) cfg.paused = !cfg.paused;
    if (input.keyPressed(.tab)) cfg.disp_mode = @mod(cfg.disp_mode + 1, 5);
    if (input.keyPressed(.f1)) cfg.show_panel = !cfg.show_panel;

    // Fixed-step accumulation: the sim always advances at `step_rate` Hz.
    const fixed_dt = 1.0 / @max(cfg.step_rate, 1);
    if (!cfg.paused) {
        accumulator += pxl.time.dt() * cfg.time_scale;
        var steps: u32 = 0;
        while (accumulator >= fixed_dt and steps < 4) : (steps += 1) {
            accumulator -= fixed_dt;
            runStep(fixed_dt);
        }
        if (accumulator > 0.25) accumulator = 0; // hitch guard
    }

    ctl_u.u_disp_mode = cfg.disp_mode;
    dispatch(PHASE_DISPLAY);

    if (cfg.show_panel) controlsWindow();
}

fn controlsWindow() void {
    if (!mu.beginWindowEx("Fluid Controls", .{ .x = 336, .y = 8, .w = 250, .h = 460 }, .{ .align_center = false }))
        return;
    defer mu.endWindow();

    mu.layoutRow(2, &[_]c_int{ 105, -1 }, 0);

    mu.label("Paused:");
    _ = mu.checkbox("paused", &cfg.paused);

    mu.label("View:");
    const modes = [_][]const u8{ "smoke", "temperature", "velocity", "divergence", "pressure" };
    var view_buf: [24]u8 = undefined;
    const view_str = std.fmt.bufPrintZ(&view_buf, "{s} (Tab)", .{modes[@intCast(@mod(cfg.disp_mode, 5))]}) catch "smoke";
    mu.label(view_str.ptr);

    mu.label("Time Scale:");
    _ = mu.slider(&cfg.time_scale, 0, 3, 0.05);

    mu.label("Pressure Iters:");
    _ = mu.slider(&cfg.pressure_iters, 1, 80, 1);

    mu.label("Max Velocity:");
    _ = mu.slider(&cfg.max_velocity, 20, 600, 5);

    mu.label("Gravity:");
    _ = mu.slider(&cfg.gravity, 0, 80, 1);

    mu.label("Buoyancy Temp:");
    _ = mu.slider(&cfg.buoyancy_temp, 0, 0.5, 0.01);

    mu.label("Negative Buoyancy:");
    _ = mu.slider(&cfg.buoyancy_smoke, 0, 1.5, 0.01);

    mu.label("Surface Slide:");
    _ = mu.slider(&cfg.surface_slide, 0, 2, 0.01);

    mu.label("Wind:");
    _ = mu.slider(&cfg.wind, 0, 60, 1);

    mu.label("Smoke Decay:");
    _ = mu.slider(&cfg.smoke_decay, 0, 1.5, 0.01);

    mu.label("Temp Decay:");
    _ = mu.slider(&cfg.temp_decay, 0, 2, 0.01);

    mu.label("Smoke Diff:");
    _ = mu.slider(&cfg.smoke_diffusion, 0, 2, 0.01);

    mu.label("Temp Diff:");
    _ = mu.slider(&cfg.temp_diffusion, 0, 2, 0.01);

    mu.label("Emission:");
    _ = mu.slider(&cfg.emit, 0, 10, 0.05);

    mu.label("Vent Strength:");
    _ = mu.slider(&cfg.vent_strength, 0, 4, 0.05);

    mu.label("Brush Radius:");
    _ = mu.slider(&cfg.brush_radius, 2, 60, 1);

    mu.label("Brush Power:");
    _ = mu.slider(&cfg.brush_strength, 0.2, 12, 0.1);

    mu.label("Brush Smoke:");
    _ = mu.slider(&cfg.brush_smoke, 0, 12, 0.1);

    mu.label("Player Radius:");
    _ = mu.slider(&cfg.player_radius, 2, 40, 1);

    mu.label("Player Push:");
    _ = mu.slider(&cfg.player_push, 0, 20, 0.1);

    mu.layoutRow(1, &[_]c_int{-1}, 12);
    if (mu.buttonEx("Clear (C)", .none, .{})) clearSim();
    if (mu.buttonEx("Pause (Space)", .none, .{})) cfg.paused = !cfg.paused;

    mu.layoutRow(2, &[_]c_int{ 105, -1 }, 0);
    var fps_buf: [32]u8 = undefined;
    const fps_str = std.fmt.bufPrintZ(&fps_buf, "{d} fps", .{pxl.time.fps()}) catch "";
    mu.label(fps_str.ptr);
    mu.label("");
}

pub fn render() !void {
    pxl.beginPass(.{ .camera = camera, .clear_color = Color.fromBytes(5, 7, 18, 255) });

    // Smoke first: the tone-mapped GPU output covers the viewport, upscaled 2x
    // with nearest sampling so each sim cell is a chunky pixel.
    api.drawTextureEx(
        .{ .img = field_imgs[@intFromEnum(FieldId.disp)], .width = SIM_W, .height = SIM_H },
        .{ .pos = .{}, .origin = .top_left, .scale = .init(PX_PER_CELL, PX_PER_CELL) },
        Color.white,
    );

    // ...then the maze walls sit on top of the drifting smoke, then the player.
    // (entities stay hidden — this scene has none we care about)
    for (map.levels) |level| pxl.tilemap.renderLevel(map, level, false);
    drawPlayer();

    api.drawText(null, .init(4, DESIGN_H - 24), "wasd move + stir smoke · hold mouse to blow", Color.aya);
    api.drawText(null, .init(4, DESIGN_H - 12), "tab view · c clear · space pause · f1 settings", Color.aya);

    pxl.endPass();
}

pub fn shutdown() !void {
    sg.destroyPipeline(fluid_pip);
    sg.destroySampler(obstacle_smp);
    sg.destroyView(obstacle_view);
    obstacle_tex.deinit();
    for (field_imgs) |img| sg.destroyImage(img);
    for (field_views) |view| sg.destroyView(view);
    pxl.assets.destroy(map);
}
