const std = @import("std");
const pxl = @import("pxl.zig");

// /* Custom pipeline creation. */
// sg_pipeline sgp_make_pipeline(const sgp_pipeline_desc* desc); /* Creates a custom shader pipeline to be used with SGP. */

// /* Draw command queue management. */
// void sgp_begin(int width, int height);    /* Begins a new SGP draw command queue. */
// void sgp_flush(void);                     /* Dispatch current Sokol GFX draw commands. */
// void sgp_end(void);                       /* End current draw command queue, discarding it. */

// /* 2D coordinate space projection */
// void sgp_project(float left, float right, float top, float bottom); /* Set the coordinate space boundary in the current viewport. */
// void sgp_reset_project(void);                                       /* Resets the coordinate space to default (coordinate of the viewport). */

// /* 2D coordinate space transformation. */
// void sgp_push_transform(void);                            /* Saves current transform matrix, to be restored later with a pop. */
// void sgp_pop_transform(void);                             /* Restore transform matrix to the same value of the last push. */
// void sgp_reset_transform(void);                           /* Resets the transform matrix to identity (no transform). */
// void sgp_translate(float x, float y);                     /* Translates the 2D coordinate space. */
// void sgp_rotate(float theta);                             /* Rotates the 2D coordinate space around the origin. */
// void sgp_rotate_at(float theta, float x, float y);        /* Rotates the 2D coordinate space around a point. */
// void sgp_scale(float sx, float sy);                       /* Scales the 2D coordinate space around the origin. */
// void sgp_scale_at(float sx, float sy, float x, float y);  /* Scales the 2D coordinate space around a point. */

// /* State change for custom pipelines. */
// void sgp_set_pipeline(sg_pipeline pipeline);              /* Sets current draw pipeline. */
// void sgp_reset_pipeline(void);                            /* Resets to the current draw pipeline to default (builtin pipelines). */
// void sgp_set_uniform(const void* vs_data, uint32_t vs_size, const void *fs_data, uint32_t fs_size); /* Sets uniform buffer for a custom pipeline. */
// void sgp_reset_uniform(void);                             /* Resets uniform buffer to default (current state color). */

// /* State change functions for the common pipelines. */
// void sgp_set_blend_mode(sgp_blend_mode blend_mode);       /* Sets current blend mode. */
// void sgp_reset_blend_mode(void);                          /* Resets current blend mode to default (no blending). */
// void sgp_set_color(float r, float g, float b, float a);   /* Sets current color modulation. */
// void sgp_reset_color(void);                               /* Resets current color modulation to default (white). */
// void sgp_set_image(int channel, sg_image image);          /* Sets current bound image in a texture channel. */
// void sgp_unset_image(int channel);                        /* Remove current bound image in a texture channel (no texture). */
// void sgp_reset_image(int channel);                        /* Resets current bound image in a texture channel to default (white texture). */
// void sgp_set_sampler(int channel, sg_sampler sampler);    /* Sets current bound sampler in a texture channel. */
// void sgp_unset_sampler(int channel);                      /* Remove current bound sampler in a texture channel (no sampler). */
// void sgp_reset_sampler(int channel);                      /* Resets current bound sampler in a texture channel to default (nearest sampler). */

// /* State change functions for all pipelines. */
// void sgp_viewport(int x, int y, int w, int h);            /* Sets the screen area to draw into. */
// void sgp_reset_viewport(void);                            /* Reset viewport to default values (0, 0, width, height). */
// void sgp_scissor(int x, int y, int w, int h);             /* Set clip rectangle in the viewport. */
// void sgp_reset_scissor(void);                             /* Resets clip rectangle to default (viewport bounds). */
// void sgp_reset_state(void);                               /* Reset all state to default values. */

// /* Drawing functions. */
// void sgp_clear(void);                                                                         /* Clears the current viewport using the current state color. */
// void sgp_draw(sg_primitive_type primitive_type, const sgp_vertex* vertices, uint32_t count);  /* Low level drawing function, capable of drawing any primitive. */
// void sgp_draw_points(const sgp_point* points, uint32_t count);                                /* Draws points in a batch. */
// void sgp_draw_point(float x, float y);                                                        /* Draws a single point. */
// void sgp_draw_lines(const sgp_line* lines, uint32_t count);                                   /* Draws lines in a batch. */
// void sgp_draw_line(float ax, float ay, float bx, float by);                                   /* Draws a single line. */
// void sgp_draw_lines_strip(const sgp_point* points, uint32_t count);                           /* Draws a strip of lines. */
// void sgp_draw_filled_triangles(const sgp_triangle* triangles, uint32_t count);                /* Draws triangles in a batch. */
// void sgp_draw_filled_triangle(float ax, float ay, float bx, float by, float cx, float cy);    /* Draws a single triangle. */
// void sgp_draw_filled_triangles_strip(const sgp_point* points, uint32_t count);                /* Draws strip of triangles. */
// void sgp_draw_filled_rects(const sgp_rect* rects, uint32_t count);                            /* Draws a batch of rectangles. */
// void sgp_draw_filled_rect(float x, float y, float w, float h);                                /* Draws a single rectangle. */
// void sgp_draw_textured_rects(int channel, const sgp_textured_rect* rects, uint32_t count);    /* Draws a batch textured rectangle, each from a source region. */
// void sgp_draw_textured_rect(int channel, sgp_rect dest_rect, sgp_rect src_rect);              /* Draws a single textured rectangle from a source region. */
