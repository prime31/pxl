#pragma sokol @header const frm = @import("frm")
#pragma sokol @header const math = frm.math
#pragma sokol @ctype mat4 math.Mat4
#pragma sokol @ctype vec2 math.Vec2

@include blit.glsl
@include shapes.glsl
@include quad.glsl
@include default.glsl
@include offscreen.glsl
@include display.glsl