#pragma sokol @header const pxl = @import("pxl")
#pragma sokol @header const math = pxl.math
#pragma sokol @ctype mat4 math.Mat4
#pragma sokol @ctype vec2 math.Vec2

@include blit.glsl
@include shapes.glsl
@include batcher.glsl
@include quad.glsl
@include default.glsl
@include offscreen.glsl
@include display.glsl
@include gp_example.glsl
