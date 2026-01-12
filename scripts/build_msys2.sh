#!/usr/bin/env bash
set -euo pipefail

# Build flashrom using Meson/Ninja inside MSYS2 MINGW64 shell.
# Assumes dependencies installed by workflow.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLASHROM_DIR="$ROOT/flashrom"
OUT_DIR="$ROOT/out"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

cd "$FLASHROM_DIR"

# Clean build dir each run (deterministic)
rm -rf build

# Enable libusb explicitly
meson setup build --buildtype=release --backend=ninja -Dprogrammer=group_usb -Dtests=disabled
meson compile -C build

# Install into repo-local out/
DESTDIR="$OUT_DIR" meson install -C build
