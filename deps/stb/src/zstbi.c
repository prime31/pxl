#include <stdlib.h>

void* (*zstbiMallocPtr)(size_t size) = NULL;
void* (*zstbiReallocPtr)(void* ptr, size_t size) = NULL;
void (*zstbiFreePtr)(void* ptr) = NULL;

#define STBI_MALLOC(size) zstbiMallocPtr(size)
#define STBI_REALLOC(ptr, size) zstbiReallocPtr(ptr, size)
#define STBI_FREE(ptr) zstbiFreePtr(ptr)

#define STB_IMAGE_IMPLEMENTATION
#define STBI_NO_JPEG
#define STBI_NO_BMP
#define STBI_NO_PSD
#define STBI_NO_TGA
#define STBI_NO_GIF
#define STBI_NO_HDR
#define STBI_NO_PIC
#define STBI_NO_PNM
#include "stb_image.h"

void* (*zstbirMallocPtr)(size_t size, void* context) = NULL;
void (*zstbirFreePtr)(void* ptr, void* context) = NULL;

#define STBIR_MALLOC(size, context) zstbirMallocPtr(size, context)
#define STBIR_FREE(ptr, context) zstbirFreePtr(ptr, context)

// #define STB_IMAGE_RESIZE_IMPLEMENTATION
// #include "stb_image_resize.h"

void* (*zstbiwMallocPtr)(size_t size) = NULL;
void* (*zstbiwReallocPtr)(void* ptr, size_t size) = NULL;
void (*zstbiwFreePtr)(void* ptr) = NULL;

#define STBIW_MALLOC(size) zstbiwMallocPtr(size)
#define STBIW_REALLOC(ptr, size) zstbiwReallocPtr(ptr, size)
#define STBIW_FREE(ptr) zstbiwFreePtr(ptr)

// #define STB_IMAGE_WRITE_IMPLEMENTATION
// #include "stb_image_write.h"


// Append the stb_vorbis configuration and source compilation code.
// The goal is to keep exactly one API surface: decode a whole in-memory
// stream into interleaved f32 samples (see `pxl.stb.vorbis` in zstbi.zig).
// Each define below trims what we don't need; note the one we deliberately
// do NOT set.
//
// STB_VORBIS_NO_STDIO: assets are loaded through pxl.fs.read (filesystem
// + Android AAssetManager), and stdio doesn't exist on Android/wasm —
// decoding from memory keeps a single portable path.
#define STB_VORBIS_NO_STDIO
// STB_VORBIS_NO_PUSHDATA_API: the chunk-streaming push decoder is unused;
// we always have the whole file in memory and use the simpler pull API.
#define STB_VORBIS_NO_PUSHDATA_API
// NOTE: STB_VORBIS_NO_PULLDATA_API is intentionally NOT defined here — it
// would compile out stb_vorbis_open_memory/get_samples_float_interleaved,
// i.e. the whole decode-from-memory API that pxl.stb.vorbis uses.
// STB_VORBIS_NO_INTEGER_CONVERSION: forces f32 output and removes the int16
// conversion path; sokol-audio's native format is f32.
#define STB_VORBIS_NO_INTEGER_CONVERSION

#include "stb_vorbis.c"
