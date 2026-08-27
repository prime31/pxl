// GPU smoke/fluid simulation for the pxl smoke example.
//
// Port of Sebastian Lague's Smoke Simulation
// (github.com/SebLague/Smoke-Simulation) into a single sokol compute shader.
// The fluid uses a staggered (MAC) grid: each cell stores the x-velocity of
// its left edge and the y-velocity of its bottom edge, which keeps the
// pressure projection stable. Pressure is solved with a red-black Gauss-Seidel
// iteration with SOR over-relaxation, and obstacles (maze walls + domain
// border) are baked into a static mask with precomputed edge blocking.
//
// The domain is 1 cell per screen pixel (320x180), y-down like the screen:
//   u_vel      : xy = edge velocities (px/s)
//   u_vel_adv  : advected-velocity readback buffer
//   u_smoke    : rgb = smoke density, a = temperature
//   u_smoke_adv: advected-smoke readback buffer
//   u_pressure : r = pressure, g = packed edge-flow bits, b = velocity term
//   u_disp     : RGBA8 tone-mapped output drawn on screen
// Obstacles live in u_obstacle_tex: r = solid, g = packed 4-bit edge case
// (bit n set means the edge in direction n is blocked).

#pragma sokol @header const pxl = @import("pxl")
#pragma sokol @header const math = pxl.math
#pragma sokol @ctype vec2 math.Vec2

@cs fluid

layout(binding=0) uniform sim_ub {
    vec2  u_resolution;
    float u_dt;
    float u_time;
    float u_gravity;
    float u_ambient;
    float u_temperature_diffusion;
    float u_temperature_decay;
    float u_temperature_rate;
    float u_smoke_diffusion;
    float u_smoke_decay;
    float u_buoyancy_temperature;
    float u_buoyancy_smoke;
    float u_edge_emission;
    float u_wind_x;
};

layout(binding=1) uniform ctl_ub {
    float u_smoke_r;
    float u_smoke_g;
    float u_smoke_b;
    float u_max_velocity;
    vec2  u_brush_centre;
    vec2  u_brush_delta;
    float u_brush_radius;
    float u_brush_strength;
    float u_brush_smoke;
    int   u_brush_add_smoke;
    int   u_brush_set_velocities;
    int   u_phase;
    int   u_pass_index;
    int   u_clear_pressure;
    int   u_disp_mode;
    int   u_player_on;
};

layout(binding=2) uniform ctl2_ub {
    vec2  u_player_pos;
    vec2  u_player_delta;
    float u_player_radius;
    float u_player_push;
    float u_emit;
    float u_player_temp;
    float u_vent_temp;
    // Steam vents: xy = position, z = radius, w = smoke emission per second.
    vec4  u_vents[3];
};

layout(binding=1) uniform texture2D u_obstacle_tex;
layout(binding=1) uniform sampler u_obstacle_smp;

layout(binding=3, rgba32f) uniform image2D u_vel;
layout(binding=4, rgba32f) uniform image2D u_vel_adv;
layout(binding=5, rgba32f) uniform image2D u_smoke;
layout(binding=6, rgba32f) uniform image2D u_smoke_adv;
layout(binding=7, rgba32f) uniform image2D u_pressure;
layout(binding=8, rgba8) uniform writeonly image2D u_disp;

layout(local_size_x=8, local_size_y=8, local_size_z=1) in;

#define PHASE_CLEAR          0
#define PHASE_SEED           1
#define PHASE_FORCES         2
#define PHASE_BUOYANCY       3
#define PHASE_INTERACTION    4
#define PHASE_PRESSURE_PREP  5
#define PHASE_PRESSURE_SOLVE 6
#define PHASE_PRESSURE_APPLY 7
#define PHASE_SMOKE_ADVECT   8
#define PHASE_SMOKE_DIFFUSE  9
#define PHASE_VEL_ADVECT     10
#define PHASE_VEL_READBACK   11
#define PHASE_DISPLAY        12

#define EDGE_LEFT   0
#define EDGE_RIGHT  1
#define EDGE_BOTTOM 2
#define EDGE_TOP    3

#define SOR_WEIGHT 1.7

ivec2 dims() {
    return ivec2(int(u_resolution.x), int(u_resolution.y));
}

ivec2 clamp_coord(ivec2 p) {
    return clamp(p, ivec2(0), dims() - ivec2(1));
}

// World position helpers. World space is pixel space shifted so the domain
// centre is at the origin (cellSize = 1, y-down like the screen).
vec2 cell_centre(int x, int y) {
    return (vec2(float(x) + 0.5, float(y) + 0.5) - u_resolution * 0.5);
}
// Left edge of the cell — where the x-velocity component lives.
vec2 cell_edge_left(int x, int y) {
    return (vec2(float(x), float(y) + 0.5) - u_resolution * 0.5);
}
// Bottom edge of the cell — where the y-velocity component lives.
vec2 cell_edge_bottom(int x, int y) {
    return (vec2(float(x) + 0.5, float(y)) - u_resolution * 0.5);
}

bool is_solid(ivec2 p) {
    // Out-of-bounds cells: the domain is open on the top (y < 0) and right
    // (x >= W) edges so smoke flows out of the scene (like the reference's
    // openRightEdge/openTopEdge); left and bottom stay solid.
    if (p.x < 0) return true;
    if (p.y >= dims().y) return true;
    if (p.x >= dims().x || p.y < 0) return false;
    vec2 uv = (vec2(p) + vec2(0.5)) / u_resolution;
    return texture(sampler2D(u_obstacle_tex, u_obstacle_smp), uv).r > 0.5;
}

// Cheap hash-based 1D value noise, used to give the ambient smoke turbulent,
// billowing structure instead of a flat fill. value in [0,1].
float hash1(float n) {
    return fract(sin(n) * 43758.5453123);
}
float noise1(float x) {
    float i = floor(x);
    float f = fract(x);
    float u = f * f * (3.0 - 2.0 * f);
    return mix(hash1(i), hash1(i + 1.0), u);
}
// 2D value noise via hash of the (x,y) coordinates.
float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}
float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Packed 4-bit edge case: bit n set means the edge in direction n is blocked.
int edge_case(ivec2 p) {
    ivec2 c = clamp_coord(p);
    vec2 uv = (vec2(c) + vec2(0.5)) / u_resolution;
    return int(texture(sampler2D(u_obstacle_tex, u_obstacle_smp), uv).g * 255.0 + 0.5);
}

bool edge_blocked(ivec2 p, int edge) {
    return ((edge_case(p) >> edge) & 1) != 0;
}

// Manual bilinear sample of the velocity field (matches GPU linear filtering).
vec4 sample_bilinear_vel(vec2 p) {
    ivec2 b = ivec2(p);
    vec2 f = clamp(p - vec2(b), vec2(0.0), vec2(1.0));
    vec4 v00 = imageLoad(u_vel, clamp_coord(b));
    vec4 v10 = imageLoad(u_vel, clamp_coord(b + ivec2(1, 0)));
    vec4 v01 = imageLoad(u_vel, clamp_coord(b + ivec2(0, 1)));
    vec4 v11 = imageLoad(u_vel, clamp_coord(b + ivec2(1, 1)));
    return mix(mix(v00, v10, f.x), mix(v01, v11, f.x), f.y);
}

// Manual bilinear sample of the smoke field.
vec4 sample_bilinear_smoke(vec2 p) {
    ivec2 b = ivec2(p);
    vec2 f = clamp(p - vec2(b), vec2(0.0), vec2(1.0));
    vec4 v00 = imageLoad(u_smoke, clamp_coord(b));
    vec4 v10 = imageLoad(u_smoke, clamp_coord(b + ivec2(1, 0)));
    vec4 v01 = imageLoad(u_smoke, clamp_coord(b + ivec2(0, 1)));
    vec4 v11 = imageLoad(u_smoke, clamp_coord(b + ivec2(1, 1)));
    return mix(mix(v00, v10, f.x), mix(v01, v11, f.x), f.y);
}

// Sample the staggered x-velocity field (defined on cell left edges).
float sample_vel_x(vec2 worldPos) {
    vec2 p = vec2(worldPos.x + u_resolution.x * 0.5, worldPos.y + u_resolution.y * 0.5 - 0.5);
    return sample_bilinear_vel(p).x;
}
// Sample the staggered y-velocity field (defined on cell bottom edges).
float sample_vel_y(vec2 worldPos) {
    vec2 p = vec2(worldPos.x + u_resolution.x * 0.5 - 0.5, worldPos.y + u_resolution.y * 0.5);
    return sample_bilinear_vel(p).y;
}

vec2 get_velocity_at(vec2 worldPos) {
    return vec2(sample_vel_x(worldPos), sample_vel_y(worldPos));
}

vec2 rewind_pos(vec2 worldPos) {
    return worldPos - get_velocity_at(worldPos) * u_dt;
}

// Bilinearly sampled smoke at a world position; outside the domain returns
// empty smoke at ambient temperature.
vec4 get_smoke_at(vec2 worldPos) {
    vec2 uv = (worldPos + u_resolution * 0.5) / u_resolution;
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) return vec4(0, 0, 0, u_ambient);
    vec2 p = worldPos + u_resolution * 0.5 - vec2(0.5);
    return sample_bilinear_smoke(p);
}

float get_pressure(int x, int y) {
    ivec2 d = dims();
    if (x < 0 || y < 0 || x >= d.x || y >= d.y) return 0.0;
    return imageLoad(u_pressure, ivec2(x, y)).r;
}

vec4 get_advected_smoke(int x, int y) {
    ivec2 d = dims();
    if (x < 0 || y < 0 || x >= d.x || y >= d.y) return vec4(0, 0, 0, u_ambient);
    return imageLoad(u_smoke_adv, ivec2(x, y));
}

// 1 - dist/radius falloff used for the player body and mouse brush.
float falloff(vec2 worldPos, vec2 centre, float radius) {
    float dist2 = dot(worldPos - centre, worldPos - centre);
    float r2 = radius * radius;
    if (dist2 >= r2) return 0.0;
    return 1.0 - sqrt(dist2 / r2);
}

void main() {
    ivec2 id = ivec2(gl_GlobalInvocationID.xy);
    ivec2 d = dims();
    if (id.x >= d.x || id.y >= d.y) return;

    // ---- zero every field (setup + clear) ----
    if (u_phase == PHASE_CLEAR) {
        imageStore(u_vel, id, vec4(0));
        imageStore(u_vel_adv, id, vec4(0));
        imageStore(u_smoke, id, vec4(0, 0, 0, u_ambient));
        imageStore(u_smoke_adv, id, vec4(0, 0, 0, u_ambient));
        imageStore(u_pressure, id, vec4(0));
        imageStore(u_disp, id, vec4(0.016, 0.024, 0.06, 1.0));
        return;
    }

    // ---- seed a small puff of smoke around the player (setup only) ----
    if (u_phase == PHASE_SEED) {
        vec2 worldPos = cell_centre(id.x, id.y);
        // A modest puff so the scene opens slightly smoky without filling it.
        float k = falloff(worldPos, u_player_pos - u_resolution * 0.5, 17.0);
        if (k > 0.0) {
            vec4 sm = imageLoad(u_smoke, id);
            sm.rgb += vec3(u_smoke_r, u_smoke_g, u_smoke_b) * (0.35 + u_emit * 0.4) * k;
            sm.a = max(sm.a, u_ambient);
            imageStore(u_smoke, id, sm);
        }
        return;
    }

    // ---- smoke emitted continuously from every fluid-facing tilemap edge ----
    // Solid cells are not sources themselves: each neighboring empty cell receives
    // a small source on the side touching the wall. This makes smoke hug floors,
    // ceilings, and both sides of corridors rather than coming from the player.
    if (u_phase == PHASE_FORCES) {
        if (!is_solid(id)) {
            float edge_count = 0.0;
            if (is_solid(id + ivec2(-1, 0))) edge_count += 1.0;
            if (is_solid(id + ivec2(1, 0))) edge_count += 1.0;
            if (is_solid(id + ivec2(0, -1))) edge_count += 1.0;
            if (is_solid(id + ivec2(0, 1))) edge_count += 1.0;
            if (edge_count > 0.0) {
                vec4 sm = imageLoad(u_smoke, id);
                float edge_noise = 0.72 + 0.28 * noise2(vec2(id) * 0.17 + vec2(u_time * 0.03));
                sm.rgb += vec3(u_smoke_r, u_smoke_g, u_smoke_b)
                    * u_edge_emission * u_dt * edge_noise * min(edge_count, 2.0);
                sm.a += (u_ambient + 2.0 - sm.a) * 0.08 * u_dt * edge_count;
                imageStore(u_smoke, id, sm);
            }
        }
    }

    // ---- external forces: player body + wind, zero smoke in obstacles ----
    if (u_phase == PHASE_FORCES) {
        vec2 worldPos = cell_centre(id.x, id.y);
        vec4 smokeData = imageLoad(u_smoke, id);

        // Steam vents: hot plumes rise off fixed sources, get pushed by the wind
        // and curl around the maze walls, so the scene reads as drifting steam
        // rather than a haze that fills the whole domain.
        if (!is_solid(id)) {
            for (int i = 0; i < 3; i++) {
                vec4 v = u_vents[i];
                if (v.w <= 0.0) continue;
                float k = falloff(worldPos, v.xy - u_resolution * 0.5, v.z);
                if (k <= 0.0) continue;
                smokeData.rgb += vec3(u_smoke_r, u_smoke_g, u_smoke_b) * v.w * u_dt * k;
                smokeData.a += (u_vent_temp - smokeData.a) * u_temperature_rate * u_dt * k;
            }
        }

        // The player's body heats the air, drags it along and emits smoke.
        if (u_player_on != 0 && u_player_radius > 0.0) {
            float k = falloff(worldPos, u_player_pos - u_resolution * 0.5, u_player_radius);
            if (k > 0.0) {
                smokeData.a += (u_player_temp - smokeData.a) * u_temperature_rate * u_dt * k;
                smokeData.rgb += vec3(u_smoke_r, u_smoke_g, u_smoke_b) * u_emit * u_dt * k;
            }
        }

        if (is_solid(id)) {
            smokeData.rgb = vec3(0);
            if (id.x == 0 || id.y == 0 || id.x == d.x - 1 || id.y == d.y - 1) smokeData.a = u_ambient;
        }
        imageStore(u_smoke, id, smokeData);

        // The player drags air along as it moves (no flow through walls).
        vec2 velocity = imageLoad(u_vel, id).xy;
        if (u_player_on != 0 && u_player_radius > 0.0) {
            float k = falloff(worldPos, u_player_pos - u_resolution * 0.5, u_player_radius);
            if (k > 0.0) {
                velocity.x += u_player_delta.x * k * (edge_blocked(id, EDGE_LEFT) ? 0.0 : 1.0);
                velocity.y += u_player_delta.y * k * (edge_blocked(id, EDGE_BOTTOM) ? 0.0 : 1.0);
            }
        }

        // Divergence-free swirling eddies from curl noise, so advection stretches
        // the smoke into wisps and billows instead of carrying it as a smooth sheet.
        if (!is_solid(id)) {
            float t = u_time * 0.04;
            vec2 q = vec2(float(id.x), float(id.y)) * 0.075 + vec2(t * 0.25);
            float e = 1.5;
            float nx = noise2(q + vec2(e, 0.0)) - noise2(q - vec2(e, 0.0));
            float ny = noise2(q + vec2(0.0, e)) - noise2(q - vec2(0.0, e));
            vec2 swirl = vec2(ny, -nx); // rotated gradient ~ divergence free
            velocity += (swirl * 12.0) * u_dt;
        }

        // Wind source: a column just inside the left edge of the domain.
        if (u_wind_x != 0.0 && id.x == 1 && id.y > 0 && id.y < d.y - 1) {
            velocity.x = u_wind_x;
        }

        imageStore(u_vel, id, vec4(velocity, 0, 0));
        imageStore(u_vel_adv, id, vec4(0)); // reset readback buffer
        return;
    }

    // ---- buoyancy: hot air rises (-y), heavy smoke sinks (+y) ----
    if (u_phase == PHASE_BUOYANCY) {
        vec4 smokeData = get_smoke_at(cell_edge_bottom(id.x, id.y));
        float relativeTemperature = smokeData.a - u_ambient;
        // Screen Y grows downward. Keep temperature buoyancy separate from the
        // visible smoke: surface smoke should fall even while it is still faint.
        float buoyancyForceTemperature = -u_buoyancy_temperature * relativeTemperature * u_gravity;
        float smokeConcentration = dot(smokeData.rgb, vec3(1.0)) / 3.0;
        float smokeWeight = max(smokeConcentration, 0.12) * step(0.001, smokeConcentration);
        float buoyancyForceSmoke = u_buoyancy_smoke * smokeWeight * u_gravity;

        float mask = edge_blocked(id, EDGE_BOTTOM) ? 0.0 : 1.0;
        vec2 velocity = imageLoad(u_vel, id).xy;
        velocity.y += (buoyancyForceTemperature + buoyancyForceSmoke) * u_dt * mask;
        imageStore(u_vel, id, vec4(velocity, 0, 0));
        return;
    }

    // ---- mouse brush: add smoke (right) and push velocity (left) ----
    if (u_phase == PHASE_INTERACTION) {
        vec2 worldPos = cell_centre(id.x, id.y);
        vec2 centre = u_brush_centre - u_resolution * 0.5;
        float r2 = u_brush_radius * u_brush_radius;

        if (u_brush_add_smoke != 0 && r2 > 0.0001) {
            float dist2 = dot(worldPos - centre, worldPos - centre);
            if (dist2 < r2) {
                float weight = 1.0 - smoothstep(0.1, 0.9, dist2 / r2);
                vec4 sm = imageLoad(u_smoke, id);
                sm.rgb += vec3(u_smoke_r, u_smoke_g, u_smoke_b) * u_brush_smoke * u_dt * weight;
                imageStore(u_smoke, id, sm);
            }
        }

        if (u_brush_set_velocities != 0 && r2 > 0.0001) {
            vec2 el = cell_edge_left(id.x, id.y);
            vec2 eb = cell_edge_bottom(id.x, id.y);
            float wL = 1.0 - clamp(dot(el - centre, el - centre) / r2, 0.0, 1.0);
            float wB = 1.0 - clamp(dot(eb - centre, eb - centre) / r2, 0.0, 1.0);
            vec2 velocityAdd = u_brush_delta * vec2(wL, wB);
            velocityAdd.x *= (edge_blocked(id, EDGE_LEFT) ? 0.0 : 1.0);
            velocityAdd.y *= (edge_blocked(id, EDGE_BOTTOM) ? 0.0 : 1.0);
            vec2 velocity = imageLoad(u_vel, id).xy;
            velocity += velocityAdd;
            imageStore(u_vel, id, vec4(velocity, 0, 0));
        }
        return;
    }

    // ---- precompute velocity term + edge flow for the pressure solve ----
    if (u_phase == PHASE_PRESSURE_PREP) {
        int isSolidCell = is_solid(id) ? 1 : 0;
        int flowTop    = 1 - (isSolidCell | (is_solid(id + ivec2(0, 1)) ? 1 : 0));
        int flowLeft   = 1 - (isSolidCell | (is_solid(id - ivec2(1, 0)) ? 1 : 0));
        int flowRight  = 1 - (isSolidCell | (is_solid(id + ivec2(1, 0)) ? 1 : 0));
        int flowBottom = 1 - (isSolidCell | (is_solid(id - ivec2(0, 1)) ? 1 : 0));
        int packedEdgeFlow = flowLeft | (flowRight << EDGE_RIGHT) | (flowBottom << EDGE_BOTTOM) | (flowTop << EDGE_TOP);

        float velTop    = imageLoad(u_vel, clamp_coord(id + ivec2(0, 1))).y;
        float velRight  = imageLoad(u_vel, clamp_coord(id + ivec2(1, 0))).x;
        float velBottom = imageLoad(u_vel, id).y;
        float velLeft   = imageLoad(u_vel, id).x;

        int edgeFlowCount = flowTop + flowBottom + flowLeft + flowRight;
        float velocityTerm = 0.0;
        if (edgeFlowCount > 0) {
            velocityTerm = (velRight - velLeft + velTop - velBottom) / (float(edgeFlowCount) * max(u_dt, 0.0001));
        }

        float pressure = (u_clear_pressure != 0) ? 0.0 : imageLoad(u_pressure, id).r;
        imageStore(u_pressure, id, vec4(pressure, float(packedEdgeFlow), velocityTerm, 0.0));
        return;
    }

    // ---- red-black Gauss-Seidel pressure solve with SOR ----
    if (u_phase == PHASE_PRESSURE_SOLVE) {
        if (((id.x + id.y) & 1) != (u_pass_index & 1)) return;

        vec4 data = imageLoad(u_pressure, id);
        int edgeFlowCase = int(data.g + 0.5);
        int flowTop    = (edgeFlowCase >> EDGE_TOP) & 1;
        int flowLeft   = (edgeFlowCase >> EDGE_LEFT) & 1;
        int flowRight  = (edgeFlowCase >> EDGE_RIGHT) & 1;
        int flowBottom = (edgeFlowCase >> EDGE_BOTTOM) & 1;
        int edgeFlowCount = flowTop + flowBottom + flowLeft + flowRight;
        if (edgeFlowCount == 0) return;

        float pressureTop    = get_pressure(id.x, id.y + 1) * float(flowTop);
        float pressureLeft   = get_pressure(id.x - 1, id.y) * float(flowLeft);
        float pressureRight  = get_pressure(id.x + 1, id.y) * float(flowRight);
        float pressureBottom = get_pressure(id.x, id.y - 1) * float(flowBottom);
        float pressureTerm = (pressureLeft + pressureRight + pressureBottom + pressureTop) / float(edgeFlowCount);
        float pressureNew = pressureTerm - data.b;

        float pressureOld = data.r;
        imageStore(u_pressure, id, vec4(pressureOld + (pressureNew - pressureOld) * SOR_WEIGHT, data.g, data.b, 0.0));
        return;
    }

    // ---- subtract the pressure gradient from edge velocities ----
    if (u_phase == PHASE_PRESSURE_APPLY) {
        int canFlowL = edge_blocked(id, EDGE_LEFT) ? 0 : 1;
        int canFlowR = edge_blocked(id, EDGE_RIGHT) ? 0 : 1;
        int canFlowD = edge_blocked(id, EDGE_BOTTOM) ? 0 : 1;
        int canFlowU = edge_blocked(id, EDGE_TOP) ? 0 : 1;
        if (canFlowL + canFlowR + canFlowD + canFlowU == 0) return;

        float pressureLeft   = get_pressure(id.x - 1, id.y);
        float pressureDown   = get_pressure(id.x, id.y - 1);
        float pressureCentre = get_pressure(id.x, id.y);

        vec2 edgeVel = imageLoad(u_vel, id).xy;
        if (canFlowL != 0) edgeVel.x -= u_dt * (pressureCentre - pressureLeft);
        if (canFlowD != 0) edgeVel.y -= u_dt * (pressureCentre - pressureDown);
        imageStore(u_vel, id, vec4(edgeVel, 0, 0));
        return;
    }

    // ---- semi-Lagrangian advection of the smoke field ----
    if (u_phase == PHASE_SMOKE_ADVECT) {
        vec2 posOld = rewind_pos(cell_centre(id.x, id.y));
        imageStore(u_smoke_adv, id, get_smoke_at(posOld));
        return;
    }

    // ---- smoke / temperature diffusion + decay, read back into u_smoke ----
    if (u_phase == PHASE_SMOKE_DIFFUSE) {
        vec4 centre = get_advected_smoke(id.x, id.y);
        vec4 left   = get_advected_smoke(id.x - 1, id.y);
        vec4 right  = get_advected_smoke(id.x + 1, id.y);
        vec4 top    = get_advected_smoke(id.x, id.y + 1);
        vec4 bottom = get_advected_smoke(id.x, id.y - 1);
        vec4 laplacian = (left + right + top + bottom) - 4.0 * centre; // cellSize = 1

        float temperatureNew = centre.a + u_temperature_diffusion * u_dt * laplacian.a;
        temperatureNew = u_ambient + (temperatureNew - u_ambient) * exp(-u_dt * u_temperature_decay);

        vec3 smokeNew = centre.rgb + u_smoke_diffusion * u_dt * laplacian.rgb;
        smokeNew = max(vec3(0), smokeNew) * exp(-u_dt * u_smoke_decay);

        imageStore(u_smoke, id, vec4(smokeNew, max(temperatureNew, 0.0)));
        return;
    }

    // ---- semi-Lagrangian advection of the staggered velocity field ----
    if (u_phase == PHASE_VEL_ADVECT) {
        vec2 velAdvected = vec2(0);
        if (!edge_blocked(id, EDGE_LEFT)) {
            velAdvected.x = get_velocity_at(rewind_pos(cell_edge_left(id.x, id.y))).x;
        } else {
            velAdvected.x = imageLoad(u_vel, id).x;
        }
        if (!edge_blocked(id, EDGE_BOTTOM)) {
            velAdvected.y = get_velocity_at(rewind_pos(cell_edge_bottom(id.x, id.y))).y;
        } else {
            velAdvected.y = imageLoad(u_vel, id).y;
        }
        imageStore(u_vel_adv, id, vec4(velAdvected, 0, 0));
        return;
    }

    // ---- copy the advected velocity back (with a safety clamp) ----
    if (u_phase == PHASE_VEL_READBACK) {
        vec2 v = imageLoad(u_vel_adv, id).xy;
        v = clamp(v, vec2(-u_max_velocity), vec2(u_max_velocity));
        imageStore(u_vel, id, vec4(v, 0, 0));
        return;
    }

    // ---- tone-map the smoke into the RGBA8 display image ----
    if (u_phase == PHASE_DISPLAY) {
        vec4 sm = imageLoad(u_smoke, id);
        // Atmospheric background: deep blue-violet, dark enough for the smoke to read.
        vec3 bg = vec3(0.010, 0.014, 0.038);
        vec3 col = bg;
        if (u_disp_mode == 0) {
            // Steam look matching the reference game: a dim blue-grey smoke body
            // (lum ~16-64) drifting over a near-black scene, with light localised
            // coverage instead of a full-screen haze. A pow curve lifts the plume
            // mid-tones so the clouds read clearly, and per-cell density keeps the
            // pixel texture.
            if (!is_solid(id)) {
                float amt = (sm.r + sm.g + sm.b) / 3.0;
                float d = clamp(amt, 0.0, 1.2);
                // Blue-grey steam body (lum ~20-70) with luminous blue-white
                // cores where the plumes are densest, like the reference.
                vec3 steam = vec3(0.26, 0.36, 0.52);
                // Per-cell grain anchored to the sim grid: each cell gets a fixed
                // brightness bias, so the plume reads as chunky low-res pixels
                // (the reference's coarse-cell smoke texture) instead of a smooth
                // gradient wash.
                float grain = 0.88 + 0.24 * hash12(vec2(id) + 4.7);
                col = bg + steam * pow(d, 0.65) * 1.9 * grain;
                // Slight cool-violet tint in the hot cores of the plumes.
                float heat = clamp((sm.a - u_ambient) * 0.04, 0.0, 1.0);
                col = mix(col, vec3(0.38, 0.40, 0.62), heat * 0.40);
            }
        } else if (u_disp_mode == 1) {
            // temperature: red hot, blue cold
            float rel = sm.a - u_ambient;
            col = vec3(1.0, 0.15, 0.05) * clamp(rel * 0.06, 0.0, 1.0)
                + vec3(0.05, 0.15, 1.0) * clamp(-rel * 0.06, 0.0, 1.0);
        } else if (u_disp_mode == 2) {
            // velocity magnitude
            vec2 v = imageLoad(u_vel, id).xy;
            float speed = length(v) / max(u_max_velocity, 0.001);
            col = mix(vec3(0.02, 0.05, 0.1), vec3(1.0, 0.2, 0.1), clamp(speed, 0.0, 1.0));
        } else if (u_disp_mode == 3) {
            // divergence: green source, red sink
            float velRight  = imageLoad(u_vel, clamp_coord(id + ivec2(1, 0))).x;
            float velLeft   = imageLoad(u_vel, id).x;
            float velTop    = imageLoad(u_vel, clamp_coord(id + ivec2(0, 1))).y;
            float velBottom = imageLoad(u_vel, id).y;
            float divergence = velRight - velLeft + velTop - velBottom;
            col = vec3(clamp(divergence * 3.0, 0.0, 1.0), 0.0, clamp(-divergence * 3.0, 0.0, 1.0));
        } else {
            // pressure
            float p = imageLoad(u_pressure, id).r;
            col = vec3(1.0, 0.1, 0.1) * clamp(p * 0.4, 0.0, 1.0)
                + vec3(0.1, 0.2, 1.0) * clamp(-p * 0.4, 0.0, 1.0);
        }
        imageStore(u_disp, id, vec4(col, 1.0));
        return;
    }
}
@end

@program fluid fluid
