#pragma sokol @vs bloom_composite_vs
const vec2 positions[3] = { vec2(-1, -1), vec2(3, -1), vec2(-1, 3), };

out vec2 uv;

void main() {
    vec2 pos = positions[gl_VertexIndex];
    gl_Position = vec4(pos, 0, 1);
    uv = (pos * vec2(1, -1) + 1) * 0.5;
}
#pragma sokol @end

#pragma sokol @fs bloom_composite_fs
layout(binding=0) uniform texture2D scene_tex;
layout(binding=1) uniform texture2D bloom_mix_tex;
layout(binding=0) uniform sampler bloom_smp;

in vec2 uv;
out vec4 frag_color;

void main() {
    vec3 scene_col = texture(sampler2D(scene_tex, bloom_smp), uv).rgb;
    vec3 bloom_col = texture(sampler2D(bloom_mix_tex, bloom_smp), uv).rgb;
    float intensity = 1.4;
    frag_color = vec4(scene_col + bloom_col * intensity, 1.0);
}
#pragma sokol @end

#pragma sokol @program bloom_composite bloom_composite_vs bloom_composite_fs
