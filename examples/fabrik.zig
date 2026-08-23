const std = @import("std");
const pxl = @import("pxl");
const api = pxl.api;
const Vec2 = pxl.math.Vec2;
const Color = pxl.math.Color;

/// A single FABRIK tentacle: `node_count` nodes joined by fixed-length segments.
/// `nodes[0]` is the fixed root/anchor; `nodes[node_count - 1]` is the end
/// effector (the part that reaches for the target).
///
/// FABRIK = Forward And Backward Reaching Inverse Kinematics. Each iteration
/// runs two passes:
///   1) Backward pass: pin the tip to the target, then walk toward the root
///      re-positioning every node so it sits `segment_length` from the next one.
///   2) Forward pass: pin the root back to its anchor, then walk toward the tip
///      re-positioning every node so it sits `segment_length` from the previous.
/// Repeating these converges the whole chain to the target (fully solved once
/// iterations >= node_count).
const FabrikChain = struct {
    const max_nodes = 16;
    nodes: [max_nodes]Vec2 = undefined,
    node_count: usize,
    segment_length: f32,
    root: Vec2,
    color: Color,
    node_radius: f32,
    thickness: f32,

    fn init(root: Vec2, node_count: usize, segment_length: f32, direction: Vec2, color: Color, node_radius: f32) FabrikChain {
        const dir = direction.norm();
        var self = FabrikChain{
            .node_count = node_count,
            .segment_length = segment_length,
            .root = root,
            .color = color,
            .node_radius = node_radius,
            .thickness = node_radius * 1.8,
        };
        // Lay the chain out straight along `direction` as a starting pose.
        var i: usize = 0;
        while (i < node_count) : (i += 1) {
            self.nodes[i] = root.add(dir.scale(@as(f32, @floatFromInt(i)) * segment_length));
        }
        return self;
    }

    fn solve(self: *FabrikChain, target_pos: Vec2, iterations: u32) void {
        var iter: u32 = 0;
        while (iter < iterations) : (iter += 1) {
            // Backward pass: pin the tip to the target and walk toward the root.
            self.nodes[self.node_count - 1] = target_pos;
            var i: usize = self.node_count - 1;
            while (i > 0) : (i -= 1) {
                const dir = self.nodes[i - 1].sub(self.nodes[i]).norm();
                self.nodes[i - 1] = self.nodes[i].add(dir.scale(self.segment_length));
            }

            // Forward pass: pin the root back to its anchor and walk to the tip.
            self.nodes[0] = self.root;
            var j: usize = 1;
            while (j < self.node_count) : (j += 1) {
                const dir = self.nodes[j].sub(self.nodes[j - 1]).norm();
                self.nodes[j] = self.nodes[j - 1].add(dir.scale(self.segment_length));
            }
        }
    }

    fn tip(self: *const FabrikChain) Vec2 {
        return self.nodes[self.node_count - 1];
    }

    fn draw(self: *const FabrikChain) void {
        // Body segments.
        var i: usize = 0;
        while (i + 1 < self.node_count) : (i += 1) {
            api.drawLine(self.nodes[i], self.nodes[i + 1], self.thickness, self.color);
        }

        // Joints.
        for (self.nodes[0..self.node_count]) |n| {
            api.drawCircle(n, self.node_radius, 12, self.color);
            api.drawCircleOutline(n, self.node_radius - 1.5, 1.2, 12, Color.fromRgba(0, 0, 0, 0.35));
        }

        // Anchor pad showing where the tentacle is planted.
        api.drawRectEx(self.root, .init(26, 18), .center, self.color);
        api.drawCircle(self.root, self.node_radius - 1, 12, Color.white);
    }
};

var chains: [3]FabrikChain = undefined;
var target: Vec2 = .zero; // smoothed target both tentacles chase
var actual_target: Vec2 = .zero; // raw target: mouse (shift) or screen center

pub fn config() pxl.Config {
    return .{
        .gfx = .{ .clear_color = Color.fromBytes(10, 12, 18, 255) },
    };
}

pub fn setup() !void {
    const w = pxl.window.renderWidthf();
    const h = pxl.window.renderHeightf();

    target = .init(w * 0.5, h * 0.5);
    actual_target = target;

    // Tentacle 1: planted in the floor, reaches upward.
    chains[0] = FabrikChain.init(.init(w * 0.32, h - 22), 10, 34, .init(0, -1), Color.sky_blue, 9);
    // Tentacle 2: planted on the left wall, reaches rightward.
    chains[1] = FabrikChain.init(.init(22, h * 0.68), 9, 34, .init(1, 0), Color.pink, 9);
    chains[2] = FabrikChain.init(.init(w - 22, h * 0.68), 15, 34, .init(-1, 0), Color.aya, 4);
}

pub fn update() !void {
    const w = pxl.window.renderWidthf();
    const h = pxl.window.renderHeightf();
    const mouse = pxl.input.mousePos();
    const shift_held = pxl.input.keyDown(.left_shift) or pxl.input.keyDown(.right_shift);

    actual_target = if (shift_held) mouse else .init(w * 0.5, h * 0.5);

    // Exponentially ease the smoothed target toward the actual one so the
    // tentacles visibly "chase" instead of teleporting when the target moves.
    const dt = pxl.time.dt();
    const blend = 1.0 - std.math.exp(-10.0 * dt);
    target = target.add(actual_target.sub(target).scale(blend));

    for (&chains) |*chain| chain.solve(target, 12);
}

pub fn render() !void {
    pxl.beginPass(.{ .clear_color = Color.fromBytes(10, 12, 18, 255) });
    const w = pxl.window.renderWidthf();
    const h = pxl.window.renderHeightf();

    // World fixtures the tentacles are planted into.
    api.drawLine(.init(0, h - 22), .init(w, h - 22), 4, Color.fromRgb(0.27, 0.33, 0.45));
    api.drawLine(.init(22, 0), .init(22, h), 4, Color.fromRgb(0.27, 0.33, 0.45));

    // Faint lines from each tip toward the current target.
    for (&chains) |chain| {
        api.drawLine(chain.tip(), target, 1, Color.fromRgba(1, 1, 1, 0.15));
    }

    for (&chains) |chain| chain.draw();

    // Target reticle.
    api.drawCircleOutline(target, 8, 1.5, 16, Color.white);
    api.drawLine(target.sub(.init(0, 14)), target.add(.init(0, 14)), 1.5, Color.white);
    api.drawLine(target.sub(.init(14, 0)), target.add(.init(14, 0)), 1.5, Color.white);

    const hud = "FABRIK inverse kinematics: HOLD SHIFT to reach for the mouse, release to return to center";
    api.drawText(null, .init(12, 12), hud, Color.light_gray);

    pxl.endPass();
}
