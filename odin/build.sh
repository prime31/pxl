#!/bin/sh
set -eu

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
EXAMPLE=${1:-hello}
OUT=${2:-"$ROOT/odin/$EXAMPLE/$EXAMPLE"}
OBJ_DIR=$(mktemp -d "${TMPDIR:-/tmp}/pxl-odin.XXXXXX")

cleanup() {
	rm -rf "$OBJ_DIR"
}
trap cleanup EXIT INT TERM

case "$EXAMPLE" in
	hello|shapes|aseprite) ;;
	*)
		echo "usage: $0 {hello|shapes|aseprite} [output]" >&2
		exit 2
		;;
esac

mkdir -p "$(dirname "$OUT")"

odin build "$ROOT/odin/$EXAMPLE" -build-mode:obj -out:"$OBJ_DIR/$EXAMPLE"

set -- "$OBJ_DIR/$EXAMPLE"-*.o
zig cc "$@" \
	-I"$ROOT/zig-out/include" \
	-L"$ROOT/zig-out/lib" \
	-lpxl -lsokol_clib \
	-framework Foundation \
	-framework Metal \
	-framework QuartzCore \
	-framework AppKit \
	-framework AudioToolbox \
	-framework GameController \
	-o "$OUT"

cd "$ROOT"
set +e
"$OUT"
status=$?
set -e
exit "$status"
