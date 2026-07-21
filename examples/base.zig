const std = @import("std");

const pxl = @import("pxl");
const has_imgui = pxl.has_imgui;
const has_imgui_docking = pxl.has_imgui_docking;
const ig = pxl.ig;

const sokol = pxl.sokol;
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sgl = sokol.gl;
const sglue = sokol.glue;
const simgui = sokol.imgui;

const state = struct {
    const offscreen = struct {
        var pass_action: sg.PassAction = .{};
        var attachments: sg.Attachments = .{};
        var img: sg.Image = .{};
        var view: sg.View = .{};
        var smp: sg.Sampler = .{};
    };

    var pass_action: sg.PassAction = .{};
    var show_first_window: bool = true;
    var show_second_window: bool = true;
};

const offscreen_width = 1024;
const offscreen_height = 768;

export fn init() void {
    // initialize sokol-gfx
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });
    sgl.setup(.{
        .color_format = pxl.gpu.offscreen_pixel_format,
        .depth_format = .DEPTH_STENCIL,
        .sample_count = pxl.gpu.offscreen_sample_count,
        .logger = .{ .func = slog.func },
    });

    // initialize sokol-imgui
    if (has_imgui) {
        simgui.setup(.{
            .logger = .{ .func = slog.func },
        });

        if (has_imgui_docking)
            ig.igGetIO().*.ConfigFlags |= ig.ImGuiConfigFlags_DockingEnable;
    }

    // create an offscreen render target texture, pass-attachments object and pass-action
    state.offscreen.img = sg.makeImage(.{
        // .usage = .{ .render_attachment = true },
        .width = offscreen_width,
        .height = offscreen_height,
        .pixel_format = pxl.gpu.offscreen_pixel_format,
        .sample_count = pxl.gpu.offscreen_sample_count,
    });
    state.offscreen.view = sg.makeView(.{
        .color_attachment = .{ .image = state.offscreen.img },
    });

    // sampler for sampling the offscreen render target
    state.offscreen.smp = sg.makeSampler(.{
        .min_filter = .LINEAR,
        .mag_filter = .LINEAR,
        .wrap_u = .REPEAT,
        .wrap_v = .REPEAT,
    });

    // var atts_desc = sg.AttachmentsDesc{};
    // atts_desc.colors[0].image = state.offscreen.img;
    // atts_desc.depth_stencil.image = sg.makeImage(.{
    //     .usage = .{ .render_attachment = true },
    //     .width = offscreen_width,
    //     .height = offscreen_height,
    //     .pixel_format = .DEPTH_STENCIL,
    //     .sample_count = gg.gpu.offscreen_sample_count,
    // });
    // state.offscreen.attachments = sg.makeAttachments(atts_desc);

    state.offscreen.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 1, .g = 0.5, .b = 0, .a = 1 },
    };

    // initial clear color
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.5, .b = 1.0, .a = 1.0 },
    };

    std.debug.print("---- fuck: {s}\n", .{pxl.shaders.quadShaderDesc(sokol.gfx.queryBackend()).label});
}

export fn frame() void {
    if (has_imgui) {
        // call simgui.newFrame() before any ImGui calls
        simgui.newFrame(.{
            .width = sapp.width(),
            .height = sapp.height(),
            .delta_time = sapp.frameDuration(),
            .dpi_scale = sapp.dpiScale(),
        });

        const texid = sokol.imgui.imtextureidWithSampler(state.offscreen.view, state.offscreen.smp);
        ig.igImage(.{ ._TexID = texid, ._TexData = texid }, .{ .x = 400, .y = 400 });

        const backendName: [*c]const u8 = switch (sg.queryBackend()) {
            .D3D11 => "Direct3D11",
            .GLCORE => "OpenGL",
            .GLES3 => "OpenGLES3",
            .METAL_IOS => "Metal iOS",
            .METAL_MACOS => "Metal macOS",
            .METAL_SIMULATOR => "Metal Simulator",
            .WGPU => "WebGPU",
            .VULKAN => "VULKAN",
            .DUMMY => "Dummy",
        };

        //=== UI CODE STARTS HERE
        ig.igSetNextWindowPos(.{ .x = 10, .y = 10 }, ig.ImGuiCond_Once);
        ig.igSetNextWindowSize(.{ .x = 400, .y = 100 }, ig.ImGuiCond_Once);
        if (ig.igBegin("Hello Dear ImGui!", &state.show_first_window, ig.ImGuiWindowFlags_None)) {
            _ = ig.igColorEdit3("Background", &state.pass_action.colors[0].clear_value.r, ig.ImGuiColorEditFlags_None);
            _ = ig.igText("Dear ImGui Version: %s", ig.IMGUI_VERSION);
        }
        ig.igEnd();

        ig.igSetNextWindowPos(.{ .x = 50, .y = 120 }, ig.ImGuiCond_Once);
        ig.igSetNextWindowSize(.{ .x = 400, .y = 100 }, ig.ImGuiCond_Once);
        if (ig.igBegin("Another Window", &state.show_second_window, ig.ImGuiWindowFlags_None)) {
            _ = ig.igText("Sokol Backend: %s", backendName);
        }

        if (ig.igButton("Gamepad Test"))
            std.debug.print("getMaxSupportedGamepads {d}\n", .{pxl.gamepad.getMaxSupportedGamepads()});

        ig.igEnd();
        //=== UI CODE ENDS HERE
    }

    sgl.defaults();
    sgl.beginPoints();

    const angle: f32 = @floatFromInt(sapp.frameCount() % 360);
    var psize: f32 = 5;
    for (0..300) |i| {
        const a = sgl.asRadians(angle + @as(f32, @floatFromInt(i)));
        // const color = computeColor(@as(f32, @floatFromInt((sapp.frameCount() + i) % 300)) / 300);
        const r = @sin(a * 4.0);
        const s = @sin(a);
        const c = @cos(a);
        const x = s * r;
        const y = c * r;
        // sgl.c3f(color.r, color.g, color.b);
        sgl.c3f(1, 0.5, 0.3);
        sgl.c3f(r, s, c);
        sgl.pointSize(psize);
        sgl.v2f(x, y);
        psize *= 1.005;
    }
    sgl.end();

    // do the actual offscreen and display rendering in sokol-gfx passes
    sg.beginPass(.{ .action = state.offscreen.pass_action, .attachments = state.offscreen.attachments });
    sgl.draw();
    sg.endPass();

    // call simgui.render() inside a sokol-gfx pass
    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    if (has_imgui) simgui.render();
    sg.endPass();

    sg.commit();
}

export fn cleanup() void {
    if (has_imgui) simgui.shutdown();
    sgl.shutdown();
    sg.shutdown();
}

export fn event(ev: [*c]const sapp.Event) void {
    // forward input events to sokol-imgui
    if (has_imgui) _ = simgui.handleEvent(ev.*);
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .window_title = "Base Sokol Test",
        .width = 1024,
        .height = 768,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = slog.func },
    });
}
