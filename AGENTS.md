# Project Overview
`pxl` is a high-performance 2D game framework built in Zig, targeting desktop, Android and WASM via Sokol.
`pxl` strives to have a clean, no nonsense, easy to remember api.


## Toolchain & Requirements
- **Zig Version**: `0.16.0` (Always ensure all code and build scripts target Zig 0.16)


## Build Commands
- **Build all targets & examples with summary**: `zig build --summary all`
- **Fast diagnostics / ZLS check**: `zig build check`
- **Run an example**: `zig build <example_name>`
  - `zig build batcher`
  - `zig build bunnymark`
  - `zig build ldtk`
  - `zig build microui`
  - `zig build shader`
  - `zig build text`


## Development Guidelines
- **Testing**: Test compile all code changes (`zig build` or `zig build check`) before declaring a task complete.
- **Examples**: Every `.zig` file in `examples/` must be exposed in `build.zig` as an executable run step.
- **Iterating**: when working only in an example test just that example with `zig build EXAMPLE_NAME`
- temporary allocations are handled by `pxl.mem.scratch` and general alloctions are handled by `pxl.mem.alloc`
- Allocators are not stored in pxl structs, we always use `pxl.mem` for allocations
- we do not use `std.ArrayList`, instead use `pxl.util.Vec`
- dont comment like a Clanker, only comment when something needs explanation and use 120 chars per line


## Inspiration
- Comfy: https://github.com/darthdeus/comfy
- Macroquad: https://github.com/not-fl3/macroquad
- Love2D: https://love2d.org/
