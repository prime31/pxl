/* batcher vertex shader: pass-through, vertices are already in clip space (CPU-baked transform) */
#pragma sokol @vs batcher_vs
in vec2 pos;
in vec2 texcoord0;
in vec4 color0;

out vec2 uv;
out vec4 color;

void main() {
    gl_Position = vec4(pos, 0.0, 1.0);
    uv = texcoord0;
    color = color0;
}
#pragma sokol @end

/* batcher fragment shader: sampled texture modulated by vertex color */
#pragma sokol @fs batcher_fs
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;

in vec2 uv;
in vec4 color;
out vec4 frag_color;

void main() {
    frag_color = texture(sampler2D(tex, smp), uv) * color;
}
#pragma sokol @end

#pragma sokol @program batcher batcher_vs batcher_fs
