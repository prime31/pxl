#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
EXAMPLE=${1:-hello}
OUT=${2:-"$ROOT/Odin/$EXAMPLE/$EXAMPLE"}
OBJ="$ROOT/odin-$EXAMPLE-main.o"
rm -f "$ROOT/odin-$EXAMPLE-"*.o "$ROOT/odin-$EXAMPLE"

case "$EXAMPLE" in
  hello|shapes|aseprite) ;;
  *) echo "usage: $0 {hello|shapes|aseprite} [output]" >&2; exit 2 ;;
esac

odin build "$ROOT/Odin/$EXAMPLE" -build-mode:obj -out:"$ROOT/odin-$EXAMPLE"
zig cc "$ROOT/odin-$EXAMPLE-main.o" "$ROOT/odin-$EXAMPLE-pxl.o" "$ROOT/odin-$EXAMPLE-builtin.o" "$ROOT/odin-$EXAMPLE-runtime-core_builtin.o" "$ROOT/odin-$EXAMPLE-runtime-core.o" "$ROOT/odin-$EXAMPLE-runtime-entry_unix.o" "$ROOT/odin-$EXAMPLE-runtime-error_checks.o" "$ROOT/odin-$EXAMPLE-runtime-heap_allocator.o" "$ROOT/odin-$EXAMPLE-runtime-heap_allocator_unix.o" "$ROOT/odin-$EXAMPLE-runtime-default_temporary_allocator.o" "$ROOT/odin-$EXAMPLE-runtime-default_temp_allocator_arena.o" "$ROOT/odin-$EXAMPLE-runtime-internal.o" "$ROOT/odin-$EXAMPLE-runtime-os_specific.o" "$ROOT/odin-$EXAMPLE-runtime-os_specific_darwin.o" "$ROOT/odin-$EXAMPLE-runtime-print.o" "$ROOT/odin-$EXAMPLE-runtime-procs.o" "$ROOT/odin-$EXAMPLE-runtime-random_generator_chacha8.o" "$ROOT/odin-$EXAMPLE-runtime-random_generator_chacha8_simd128.o" \
  -I"$ROOT/zig-out/include" \
  -L"$ROOT/zig-out/lib" \
  -lpxl -lsokol_clib \
  -framework Foundation -framework Metal -framework QuartzCore \
  -framework AppKit -framework AudioToolbox -framework GameController \
  -o "$OUT"
if [ "${PXL_RUN:-0}" = 1 ]; then
  "$OUT"
fi
