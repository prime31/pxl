@vs vs_display
@glsl_options flip_vert_y
in vec4 pos;
out vec2 uv;
void main() {
    gl_Position = vec4((pos.xy - 0.5) * vec2(2.0, -2.0), 0.0, 1.0);
    uv = pos.xy;
}
@end

@fs fs_display
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;

in vec2 uv;
out vec4 frag_color;

void main() {
    frag_color = texture(sampler2D(tex, smp), uv);
}
@end

@program display vs_display fs_display