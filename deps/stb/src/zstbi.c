#include <stdlib.h>

// NOTE: stb_image, stb_image_resize and stb_image_write used to be wired to
// custom allocators (zstbiMallocPtr & co. dispatching into a Zig allocator).
// That machinery is gone — the libraries below use the C runtime malloc for
// everything (the same way stb_vorbis already did), and `stbi_image_free`
// releases their buffers. No init/deinit is required.

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

// stb_image_write is disabled. The Zig side (`writeToFile`/`writeToFn` in
// zstbi.zig) is already in place; to enable image writing, uncomment the
// define + include below. The STBIW_MALLOC/REALLOC/FREE macros are NOT needed
// — default malloc matches everything else in this file.
//
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
