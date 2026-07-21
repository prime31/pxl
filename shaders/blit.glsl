#pragma sokol @vs blit_vs
const vec2 positions[3] = { vec2(-1, -1), vec2(3, -1), vec2(-1, 3), };

out vec2 uv;

void main() {
    vec2 pos = positions[gl_VertexIndex];
    gl_Position = vec4(pos, 0, 1);
    uv = (pos * vec2(1, -1) + 1) * 0.5;
}
@end

#pragma sokol @fs blit_fs
layout(binding=0) uniform texture2D blit_tex;
layout(binding=0) uniform sampler blit_smp;

in vec2 uv;
out vec4 frag_color;

void main() {
    frag_color = texture(sampler2D(blit_tex, blit_smp), uv);
}
@end

#pragma sokol @program blit blit_vs blit_fs