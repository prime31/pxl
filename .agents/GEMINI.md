# Project Overview

`pxl` is a high-performance 2D game framework built in Zig, targeting desktop and WebAssembly via Sokol.

## Toolchain & Requirements

- **Zig Version**: `0.16.0` (Always ensure all code and build scripts target Zig 0.16)

## Build Commands

- **Build all targets & examples**: `zig build`
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


## Inspiration
- Comfy: https://github.com/darthdeus/comfy
- Macroquad: https://github.com/not-fl3/macroquad
