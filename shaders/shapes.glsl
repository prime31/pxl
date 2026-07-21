@vs shapes_vs
layout(binding=0) uniform shapes_vs_params {
    float draw_mode;
    mat4 mvp;
};

in vec4 position;
in vec3 normal;
in vec2 texcoord;
in vec4 color0;

out vec4 color;

void main() {
    gl_Position = mvp * position;
    if (draw_mode == 0.0) {
        color = vec4((normal + 1.0) * 0.5, 1.0);
    }
    else if (draw_mode == 1.0) {
        color = vec4(texcoord, 0.0, 1.0);
    }
    else {
        color = color0;
    }
}
@end


@fs shapes_fs
in vec4 color;
out vec4 frag_color;

void main() {
    frag_color = color;
}
@end

@program shapes shapes_vs shapes_fs
