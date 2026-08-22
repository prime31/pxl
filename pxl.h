// pxl.h — C header for the pxl game framework
// Include next to libpxl.a when linking. #include "pxl_assets.h" for the
// generated asset id constants (PXL_TEXTURE_*, PXL_FONT_*, etc.).

#ifndef PXL_H
#define PXL_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include "pxl_assets.h"

#ifdef __cplusplus
extern "C" {
#endif

// ── Math types ───────────────────────────────────────────────────────────────

typedef struct { float x, y; }               PxlVec2;
typedef uint32_t                             PxlColor;   // RGBA packed: 0xAABBGGRR
typedef struct { float x, y, w, h; }         PxlRect;

// ── Enums ────────────────────────────────────────────────────────────────────

typedef enum {
    PXL_ANCHOR_CENTER        = 0,
    PXL_ANCHOR_TOP_LEFT      = 1,
    PXL_ANCHOR_TOP_CENTER    = 2,
    PXL_ANCHOR_TOP_RIGHT     = 3,
    PXL_ANCHOR_CENTER_LEFT   = 4,
    PXL_ANCHOR_CENTER_RIGHT  = 5,
    PXL_ANCHOR_BOTTOM_LEFT   = 6,
    PXL_ANCHOR_BOTTOM_CENTER = 7,
    PXL_ANCHOR_BOTTOM_RIGHT  = 8,
} PxlAnchor;

typedef enum {
    PXL_BLEND_NONE     = 0,
    PXL_BLEND_ALPHA    = 1,
    PXL_BLEND_ADD      = 2,
    PXL_BLEND_MULTIPLY = 3,
} PxlBlendMode;

typedef enum {
    PXL_SFX_COIN       = 0,
    PXL_SFX_LASER      = 1,
    PXL_SFX_EXPLOSION  = 2,
    PXL_SFX_POWERUP    = 3,
    PXL_SFX_HURT       = 4,
    PXL_SFX_JUMP       = 5,
    PXL_SFX_BLIP       = 6,
    PXL_SFX_TONE       = 7,
} PxlSfxPreset;

typedef enum {
    PXL_LOOP_LOOP          = 0,
    PXL_LOOP_ONCE          = 1,
    PXL_LOOP_CLAMP_FOREVER = 2,
    PXL_LOOP_PING_PONG     = 3,
    PXL_LOOP_PING_PONG_ONCE = 4,
    PXL_LOOP_REVERSE       = 5,
    PXL_LOOP_REVERSE_ONCE  = 6,
} PxlLoopMode;

typedef enum {
    PXL_KEYCODE_SPACE       = 32,
    PXL_KEYCODE_APOSTROPHE  = 39,
    PXL_KEYCODE_COMMA       = 44,
    PXL_KEYCODE_MINUS       = 45,
    PXL_KEYCODE_PERIOD      = 46,
    PXL_KEYCODE_SLASH       = 47,
    PXL_KEYCODE_0           = 48,
    PXL_KEYCODE_1           = 49,
    PXL_KEYCODE_2           = 50,
    PXL_KEYCODE_3           = 51,
    PXL_KEYCODE_4           = 52,
    PXL_KEYCODE_5           = 53,
    PXL_KEYCODE_6           = 54,
    PXL_KEYCODE_7           = 55,
    PXL_KEYCODE_8           = 56,
    PXL_KEYCODE_9           = 57,
    PXL_KEYCODE_SEMICOLON   = 59,
    PXL_KEYCODE_EQUAL       = 61,
    PXL_KEYCODE_A           = 65,
    PXL_KEYCODE_B           = 66,
    PXL_KEYCODE_C           = 67,
    PXL_KEYCODE_D           = 68,
    PXL_KEYCODE_E           = 69,
    PXL_KEYCODE_F           = 70,
    PXL_KEYCODE_G           = 71,
    PXL_KEYCODE_H           = 72,
    PXL_KEYCODE_I           = 73,
    PXL_KEYCODE_J           = 74,
    PXL_KEYCODE_K           = 75,
    PXL_KEYCODE_L           = 76,
    PXL_KEYCODE_M           = 77,
    PXL_KEYCODE_N           = 78,
    PXL_KEYCODE_O           = 79,
    PXL_KEYCODE_P           = 80,
    PXL_KEYCODE_Q           = 81,
    PXL_KEYCODE_R           = 82,
    PXL_KEYCODE_S           = 83,
    PXL_KEYCODE_T           = 84,
    PXL_KEYCODE_U           = 85,
    PXL_KEYCODE_V           = 86,
    PXL_KEYCODE_W           = 87,
    PXL_KEYCODE_X           = 88,
    PXL_KEYCODE_Y           = 89,
    PXL_KEYCODE_Z           = 90,
    PXL_KEYCODE_LEFT_BRACKET  = 91,
    PXL_KEYCODE_BACKSLASH     = 92,
    PXL_KEYCODE_RIGHT_BRACKET = 93,
    PXL_KEYCODE_GRAVE_ACCENT  = 96,
    PXL_KEYCODE_ESCAPE        = 256,
    PXL_KEYCODE_ENTER         = 257,
    PXL_KEYCODE_TAB           = 258,
    PXL_KEYCODE_BACKSPACE     = 259,
    PXL_KEYCODE_INSERT        = 260,
    PXL_KEYCODE_DELETE        = 261,
    PXL_KEYCODE_RIGHT         = 262,
    PXL_KEYCODE_LEFT          = 263,
    PXL_KEYCODE_DOWN          = 264,
    PXL_KEYCODE_UP            = 265,
    PXL_KEYCODE_PAGE_UP       = 266,
    PXL_KEYCODE_PAGE_DOWN     = 267,
    PXL_KEYCODE_HOME          = 268,
    PXL_KEYCODE_END           = 269,
    PXL_KEYCODE_CAPS_LOCK     = 280,
    PXL_KEYCODE_SCROLL_LOCK   = 281,
    PXL_KEYCODE_NUM_LOCK      = 282,
    PXL_KEYCODE_PRINT_SCREEN  = 283,
    PXL_KEYCODE_PAUSE         = 284,
    PXL_KEYCODE_F1            = 290,
    PXL_KEYCODE_F2            = 291,
    PXL_KEYCODE_F3            = 292,
    PXL_KEYCODE_F4            = 293,
    PXL_KEYCODE_F5            = 294,
    PXL_KEYCODE_F6            = 295,
    PXL_KEYCODE_F7            = 296,
    PXL_KEYCODE_F8            = 297,
    PXL_KEYCODE_F9            = 298,
    PXL_KEYCODE_F10           = 299,
    PXL_KEYCODE_F11           = 300,
    PXL_KEYCODE_F12           = 301,
    PXL_KEYCODE_KP_0          = 320,
    PXL_KEYCODE_KP_1          = 321,
    PXL_KEYCODE_KP_2          = 322,
    PXL_KEYCODE_KP_3          = 323,
    PXL_KEYCODE_KP_4          = 324,
    PXL_KEYCODE_KP_5          = 325,
    PXL_KEYCODE_KP_6          = 326,
    PXL_KEYCODE_KP_7          = 327,
    PXL_KEYCODE_KP_8          = 328,
    PXL_KEYCODE_KP_9          = 329,
    PXL_KEYCODE_KP_DECIMAL    = 330,
    PXL_KEYCODE_KP_DIVIDE     = 331,
    PXL_KEYCODE_KP_MULTIPLY   = 332,
    PXL_KEYCODE_KP_SUBTRACT   = 333,
    PXL_KEYCODE_KP_ADD        = 334,
    PXL_KEYCODE_KP_ENTER      = 335,
    PXL_KEYCODE_KP_EQUAL      = 336,
    PXL_KEYCODE_LEFT_SHIFT    = 340,
    PXL_KEYCODE_LEFT_CONTROL  = 341,
    PXL_KEYCODE_LEFT_ALT      = 342,
    PXL_KEYCODE_LEFT_SUPER    = 343,
    PXL_KEYCODE_RIGHT_SHIFT   = 344,
    PXL_KEYCODE_RIGHT_CONTROL = 345,
    PXL_KEYCODE_RIGHT_ALT     = 346,
    PXL_KEYCODE_RIGHT_SUPER   = 347,
} PxlKeycode;

typedef enum {
    PXL_MOUSE_LEFT    = 0,
    PXL_MOUSE_RIGHT   = 1,
    PXL_MOUSE_MIDDLE  = 2,
} PxlMouseButton;

typedef enum {
    PXL_RESOLUTION_DEFAULT                = 0,
    PXL_RESOLUTION_NO_BORDER              = 1,
    PXL_RESOLUTION_NO_BORDER_PIXEL_PERFECT = 2,
    PXL_RESOLUTION_SHOW_ALL               = 3,
    PXL_RESOLUTION_SHOW_ALL_PIXEL_PERFECT = 4,
    PXL_RESOLUTION_BEST_FIT               = 5,
} PxlResolutionPolicy;

typedef enum {
    PXL_GAMEPAD_A            = 0,
    PXL_GAMEPAD_B            = 1,
    PXL_GAMEPAD_X            = 2,
    PXL_GAMEPAD_Y            = 3,
    PXL_GAMEPAD_LEFT_BUMPER  = 4,
    PXL_GAMEPAD_RIGHT_BUMPER = 5,
    PXL_GAMEPAD_BACK         = 6,
    PXL_GAMEPAD_START        = 7,
    PXL_GAMEPAD_GUIDE        = 8,
    PXL_GAMEPAD_LEFT_THUMB   = 9,
    PXL_GAMEPAD_RIGHT_THUMB  = 10,
    PXL_GAMEPAD_DPAD_UP      = 11,
    PXL_GAMEPAD_DPAD_RIGHT   = 12,
    PXL_GAMEPAD_DPAD_DOWN    = 13,
    PXL_GAMEPAD_DPAD_LEFT    = 14,
} PxlGamepadButton;

// ── Opaque handles ───────────────────────────────────────────────────────────

typedef struct PxlTexture     PxlTexture;
typedef struct PxlFont        PxlFont;
typedef struct PxlTilemap     PxlTilemap;
typedef struct PxlAnimPlayer  PxlAnimPlayer;

// ── Config types ─────────────────────────────────────────────────────────────

typedef struct {
    const char *  window_title;
    int32_t       width;
    int32_t       height;
    int32_t       sample_count;
    int32_t       swap_interval;
    bool          high_dpi;
    bool          fullscreen;
    bool          debug_render_enabled;
    PxlColor      clear_color;
    bool          disable_vsync;
    bool          enable_clipboard;
    bool          enable_dragndrop;
    bool          srgb;
    bool          hdr;
    int32_t       design_width;
    int32_t       design_height;
    int32_t       resolution_policy;
    bool          bloom_enabled;
    int32_t       bloom_downsample;
    float         bloom_threshold;
    float         bloom_intensity;
    float         bloom_blur_radius;
} PxlConfig;

typedef struct {
    void (*setup)(void);
    void (*update)(void);
    void (*render)(void);
    void (*shutdown)(void);
} PxlCallbacks;

typedef struct {
    uint32_t  clear_color_value;
    bool      has_clear_color;
    bool      has_camera;
    float     cam_offset_x;
    float     cam_offset_y;
    float     cam_zoom;
    float     cam_rotation;
    bool      pixel_snap;
} PxlPass;

typedef struct {
    uint16_t  x;
    uint16_t  y;
} PxlAnimCell;

// ── Entrypoint ───────────────────────────────────────────────────────────────

void pxl_run(PxlConfig config, PxlCallbacks callbacks);

// ── Pass ─────────────────────────────────────────────────────────────────────

void pxl_pass_begin(PxlPass pass);
void pxl_pass_end(void);

// ── Drawing ──────────────────────────────────────────────────────────────────

void pxl_draw_rect(float x, float y, float w, float h, PxlColor color);
void pxl_draw_line(float x1, float y1, float x2, float y2, float thickness, PxlColor color);
void pxl_draw_circle(float cx, float cy, float radius, uint32_t segments, PxlColor color);
void pxl_draw_circle_outline(float cx, float cy, float radius, float thickness, uint32_t segments, PxlColor color);
void pxl_draw_point(float cx, float cy, float size, PxlColor color);

void pxl_draw_sprite(PxlTexture* tex,
    float src_x, float src_y, float src_w, float src_h,
    float pos_x, float pos_y, float rotation, float scale_x, float scale_y,
    PxlColor color, bool flip_x, bool flip_y, PxlAnchor origin);

void pxl_draw_texture(PxlTexture* tex, float x, float y);
void pxl_draw_textured_rect(PxlTexture* tex,
    float dst_x, float dst_y, float dst_w, float dst_h,
    float src_x, float src_y, float src_w, float src_h, PxlColor color);

void pxl_draw_text(const char* text, float x, float y, PxlColor color);

void pxl_draw_set_blend_mode(PxlBlendMode mode);
void pxl_draw_reset_blend_mode(void);
void pxl_draw_set_camera(float offset_x, float offset_y, float zoom, float rotation);

// ── Time ─────────────────────────────────────────────────────────────────────

float    pxl_time_dt(void);
uint32_t pxl_time_fps(void);
float    pxl_time_time(void);
uint32_t pxl_time_frame_count(void);

// ── Input ────────────────────────────────────────────────────────────────────

bool pxl_input_key_down(int32_t keycode);
bool pxl_input_key_pressed(int32_t keycode);
bool pxl_input_key_up(int32_t keycode);

bool pxl_input_mouse_down(int32_t button);
bool pxl_input_mouse_pressed(int32_t button);
void pxl_input_mouse_pos(float* x, float* y);

bool pxl_input_is_action_pressed(const char* action);
bool pxl_input_is_action_just_pressed(const char* action);
void pxl_input_add_binding(const char* action, int32_t keycode);

bool pxl_input_is_gamepad_connected(size_t index);
bool pxl_input_is_gamepad_button_down(size_t index, int32_t button);

// ── Window ───────────────────────────────────────────────────────────────────

int32_t pxl_window_width(void);
int32_t pxl_window_height(void);
float   pxl_window_widthf(void);
float   pxl_window_heightf(void);
float   pxl_window_dpi_scale(void);
bool    pxl_window_is_fullscreen(void);
void    pxl_window_toggle_fullscreen(void);
void    pxl_window_show_mouse(bool show);
bool    pxl_window_mouse_shown(void);
void    pxl_window_lock_mouse(bool lock);
bool    pxl_window_mouse_locked(void);
void    pxl_window_request_quit(void);
void    pxl_window_cancel_quit(void);
void    pxl_window_quit(void);
void    pxl_window_set_title(const char* title);
void    pxl_window_set_clipboard(const char* str);
const char* pxl_window_get_clipboard(void);

// ── Audio ────────────────────────────────────────────────────────────────────
// Sound and playback handles are opaque u64 values. 0 = invalid/null.

uint64_t pxl_audio_load(const char* path, bool streamed);
void     pxl_audio_unload(uint64_t sound_handle);

uint64_t pxl_audio_play(uint64_t sound_handle, float volume, float pan, float pitch, bool loop);
void     pxl_audio_play_one_shot(uint64_t sound_handle, float volume, float pan, float pitch);
uint64_t pxl_audio_sfx(int32_t preset, float volume, float pan, float pitch);
void     pxl_audio_stop(uint64_t playback_handle);
bool     pxl_audio_is_playing(uint64_t playback_handle);

double   pxl_audio_playback_position(uint64_t playback_handle);
double   pxl_audio_playback_duration(uint64_t playback_handle);
double   pxl_audio_sound_duration(uint64_t sound_handle);

// ── Assets ───────────────────────────────────────────────────────────────────
// Asset IDs come from pxl_assets.h (PXL_TEXTURE_*, PXL_FONT_*, etc.)

PxlTexture*  pxl_assets_load_texture(uint32_t id);
PxlFont*     pxl_assets_load_font(uint32_t id);
PxlTilemap*  pxl_assets_load_tilemap(uint32_t id);
uint64_t     pxl_assets_load_audio(uint32_t id, bool streamed);

void pxl_assets_destroy_texture(PxlTexture* tex);
void pxl_assets_destroy_font(PxlFont* font);
void pxl_assets_destroy_tilemap(PxlTilemap* map);
void pxl_assets_destroy_audio(uint64_t handle);

// ── Animation ────────────────────────────────────────────────────────────────

uint32_t        pxl_anim_add(const char* name, PxlTexture* tex,
                    float cell_w, float cell_h,
                    const PxlAnimCell* cells, size_t cell_count,
                    float fps, int32_t loop_mode);

PxlAnimPlayer*  pxl_anim_player_create(void);
void            pxl_anim_player_destroy(PxlAnimPlayer* player);
void            pxl_anim_player_play(PxlAnimPlayer* player, uint32_t anim_id);
void            pxl_anim_player_update(PxlAnimPlayer* player, float dt);
void            pxl_anim_player_pause(PxlAnimPlayer* player);
void            pxl_anim_player_resume(PxlAnimPlayer* player);
void            pxl_anim_player_stop(PxlAnimPlayer* player);
bool            pxl_anim_player_finished(PxlAnimPlayer* player);
void            pxl_anim_player_set_speed(PxlAnimPlayer* player, float speed);

// Fills out-params from the current frame. Returns false when there's no
// animation or no frames.
bool pxl_anim_player_current_frame(PxlAnimPlayer* player,
    PxlTexture** tex,
    float* src_x, float* src_y, float* src_w, float* src_h,
    PxlColor* color, bool* flip_x, bool* flip_y);

void pxl_anim_player_reset(PxlAnimPlayer* player);

// ── Color helpers ────────────────────────────────────────────────────────────

static inline PxlColor pxl_color_rgba(uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    return (uint32_t)r | ((uint32_t)g << 8) | ((uint32_t)b << 16) | ((uint32_t)a << 24);
}

static inline PxlColor pxl_color_rgb(uint8_t r, uint8_t g, uint8_t b) {
    return pxl_color_rgba(r, g, b, 255);
}

#define PXL_COLOR_WHITE       pxl_color_rgb(255, 255, 255)
#define PXL_COLOR_BLACK       pxl_color_rgb(0, 0, 0)
#define PXL_COLOR_RED         pxl_color_rgb(230, 41, 55)
#define PXL_COLOR_GREEN       pxl_color_rgb(0, 228, 48)
#define PXL_COLOR_BLUE        pxl_color_rgb(0, 121, 241)
#define PXL_COLOR_YELLOW      pxl_color_rgb(253, 249, 0)
#define PXL_COLOR_MAGENTA     pxl_color_rgb(255, 0, 255)
#define PXL_COLOR_CYAN        pxl_color_rgb(0, 255, 255)
#define PXL_COLOR_ORANGE      pxl_color_rgb(255, 161, 0)
#define PXL_COLOR_PINK        pxl_color_rgb(255, 109, 194)
#define PXL_COLOR_PURPLE      pxl_color_rgb(200, 122, 255)
#define PXL_COLOR_GRAY        pxl_color_rgb(130, 130, 130)
#define PXL_COLOR_TRANSPARENT 0

#ifdef __cplusplus
}
#endif

#endif // PXL_H