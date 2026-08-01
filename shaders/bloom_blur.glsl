#pragma sokol @vs bloom_blur_vs
const vec2 positions[3] = { vec2(-1, -1), vec2(3, -1), vec2(-1, 3), };

out vec2 uv;

void main() {
    vec2 pos = positions[gl_VertexIndex];
    gl_Position = vec4(pos, 0, 1);
    uv = (pos * vec2(1, -1) + 1) * 0.5;
}
#pragma sokol @end

#pragma sokol @fs bloom_blur_h_fs
layout(binding=0) uniform texture2D bloom_tex;
layout(binding=0) uniform sampler bloom_smp;
layout(binding=1) uniform bloom_blur_h_fs_uniforms {
    float u_radius;
};

in vec2 uv;
out vec4 frag_color;

void main() {
    vec2 texel = 1.0 / vec2(textureSize(sampler2D(bloom_tex, bloom_smp), 0));

    vec3 sum = vec3(0.0);
    sum += texture(sampler2D(bloom_tex, bloom_smp), uv + vec2(-2.0 * u_radius * texel.x, 0.0)).rgb * 0.1216216;
    sum += texture(sampler2D(bloom_tex, bloom_smp), uv + vec2(-1.0 * u_radius * texel.x, 0.0)).rgb * 0.2332432;
    sum += texture(sampler2D(bloom_tex, bloom_smp), uv).rgb * 0.2902703;
    sum += texture(sampler2D(bloom_tex, bloom_smp), uv + vec2(1.0 * u_radius * texel.x, 0.0)).rgb * 0.2332432;
    sum += texture(sampler2D(bloom_tex, bloom_smp), uv + vec2(2.0 * u_radius * texel.x, 0.0)).rgb * 0.1216216;

    frag_color = vec4(sum, 1.0);
}
#pragma sokol @end

#pragma sokol @fs bloom_blur_v_fs
layout(binding=0) uniform texture2D bloom_tex;
layout(binding=0) uniform sampler bloom_smp;
layout(binding=1) uniform bloom_blur_v_fs_uniforms {
    float u_radius;
};

in vec2 uv;
out vec4 frag_color;

void main() {
    vec2 texel = 1.0 / vec2(textureSize(sampler2D(bloom_tex, bloom_smp), 0));

    vec3 sum = vec3(0.0);
    sum += texture(sampler2D(bloom_tex, bloom_smp), uv + vec2(0.0, -2.0 * u_radius * texel.y)).rgb * 0.1216216;
    sum += texture(sampler2D(bloom_tex, bloom_smp), uv + vec2(0.0, -1.0 * u_radius * texel.y)).rgb * 0.2332432;
    sum += texture(sampler2D(bloom_tex, bloom_smp), uv).rgb * 0.2902703;
    sum += texture(sampler2D(bloom_tex, bloom_smp), uv + vec2(0.0, 1.0 * u_radius * texel.y)).rgb * 0.2332432;
    sum += texture(sampler2D(bloom_tex, bloom_smp), uv + vec2(0.0, 2.0 * u_radius * texel.y)).rgb * 0.1216216;

    frag_color = vec4(sum, 1.0);
}
#pragma sokol @end

#pragma sokol @program bloom_blur_h bloom_blur_vs bloom_blur_h_fs
#pragma sokol @program bloom_blur_v bloom_blur_vs bloom_blur_v_fs
