
@vs fog_noise_vs
layout(location=0) in vec2 pos0;
layout(location=1) in vec2 texcoord0;
layout(location=2) in vec4 color0;

layout(location=0) out vec2 uv;
layout(location=1) out vec4 color;

void main() {
    gl_Position = vec4(pos0, 0.0, 1.0);
    uv = texcoord0;
    color = color0;
}
@end

@fs fog_noise_fs
layout(binding=0) uniform texture2D tex;
layout(binding=0) uniform sampler smp;
layout(binding=1) uniform fog_noise_fs_uniforms {
    vec2 iVelocity;
    float iPressure;
    float iTime;
    float iWarpiness;
    float iRatio;
    float iZoom;
};
layout(location=0) in vec2 uv;
layout(location=1) in vec4 color;
layout(location=0) out vec4 frag_color;

float noise(vec2 p) {
    return texture(sampler2D(tex, smp), p).r;
}

void main() {
    vec3 tex_col = vec3(0.0, 0.0, 0.0);
    vec2 fog_uv = (uv * vec2(iRatio, 1.0)) * iZoom;
    float f = noise(fog_uv - iVelocity * iTime);
    f = noise(fog_uv + f * iWarpiness);

    vec3 col = mix(tex_col, vec3(f) * color.rgb, iPressure);
    frag_color = vec4(col, 1.0);
}
@end

@program fog_noise fog_noise_vs fog_noise_fs
