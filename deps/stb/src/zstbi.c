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


// Append the stb_vorbis configuration and source compilation code
#define STB_VORBIS_NO_STDIO            // Eliminates file system overhead
#define STB_VORBIS_NO_PUSHDATA_API    // Removes chunk-streaming code
#define STB_VORBIS_NO_PULLDATA_API    // Removes polling loop logic
#define STB_VORBIS_NO_INTEGER_CONVERSION // Forces f32 outputs (Sokol matches natively!)

#include "stb_vorbis.c"
