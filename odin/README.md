# Odin bindings

This folder contains Odin bindings for pxl's C ABI (`pxl.h`) and the three small
examples mirrored from the Rust wrapper: `hello`, `shapes`, and `aseprite`.

Build the native library and generated asset header from the project root first:

```sh
zig build lib
```

The examples expect the project root as their working directory and link
`zig-out/lib/libpxl.a` plus `zig-out/lib/libsokol_clib.a`. Odin's native linker
rejects the archive member alignment emitted by Zig on macOS, so use the
provided script: it emits an Odin object and lets `zig cc` perform the final link.

Each example is a standalone Odin package. From the project root:

```sh
zig build lib
Odin/build.sh hello
Odin/build.sh shapes
Odin/build.sh aseprite
```

The script invokes `odin build -build-mode:obj` and then uses `zig cc` for the
final executable link. It also adds the macOS frameworks required by sokol.
