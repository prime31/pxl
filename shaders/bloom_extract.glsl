#pragma sokol @vs bloom_extract_vs
const vec2 positions[3] = { vec2(-1, -1), vec2(3, -1), vec2(-1, 3), };

out vec2 uv;

void main() {
    vec2 pos = positions[gl_VertexIndex];
    gl_Position = vec4(pos, 0, 1);
    uv = (pos * vec2(1, -1) + 1) * 0.5;
}
#pragma sokol @end

#pragma sokol @fs bloom_extract_fs
layout(binding=0) uniform texture2D scene_tex;
layout(binding=0) uniform sampler bloom_smp;
layout(binding=1) uniform bloom_extract_fs_uniforms {
    float u_threshold;
};

in vec2 uv;
out vec4 frag_color;

void main() {
    vec3 col = texture(sampler2D(scene_tex, bloom_smp), uv).rgb;
    float luma = dot(col, vec3(0.2126, 0.7152, 0.0722));
    float k = max(luma - u_threshold, 0.0);
    frag_color = vec4(col * k, 1.0);
}
#pragma sokol @end

#pragma sokol @program bloom_extract bloom_extract_vs bloom_extract_fs
