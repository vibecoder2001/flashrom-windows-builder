#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLASHROM_DIR="$ROOT/flashrom"
OUT_DIR="$ROOT/out"
REL_DIR="$ROOT/release"

mkdir -p "$REL_DIR"
rm -rf "$REL_DIR"/*

# Locate flashrom.exe inside DESTDIR staging tree (robust across MSYS2 path translations)
candidates=()
while IFS= read -r -d '' f; do
  candidates+=("$f")
done < <(find "$OUT_DIR" -type f -iname 'flashrom.exe' -print0 2>/dev/null || true)

if [ "${#candidates[@]}" -eq 0 ]; then
  echo "flashrom.exe not found anywhere under $OUT_DIR" >&2
  exit 1
fi

# Prefer typical installed locations if multiple exists
EXE=""
for f in "${candidates[@]}"; do
  case "$f" in
    */mingw64/sbin/flashrom.exe|*/mingw64/bin/flashrom.exe)
      EXE="$f"
      break
      ;;
  esac
done
if [ -z "$EXE" ]; then
  EXE="${candidates[0]}"
fi

echo "Using flashrom.exe: $EXE" >&2
cp "$EXE" "$REL_DIR/"

# Version metadata from submodule
COMMIT_FULL="$(git -C "$FLASHROM_DIR" rev-parse HEAD)"
COMMIT_SHORT="$(git -C "$FLASHROM_DIR" rev-parse --short=12 HEAD)"

# Optional: nearest tag (may be empty on HEAD)
TAG_NEAREST="$(git -C "$FLASHROM_DIR" describe --tags --abbrev=0 2>/dev/null || true)"
if [ -z "$TAG_NEAREST" ]; then
  TAG_NEAREST="untagged"
fi

BUILD_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Include license file if present (flashrom typically has COPYING)
if [ -f "$FLASHROM_DIR/COPYING" ]; then
  cp "$FLASHROM_DIR/COPYING" "$REL_DIR/"
fi

# Ensure libflashrom DLL is present (it is often a dependency of flashrom.exe)
LIBFLASHROM_DLL="$(find "$OUT_DIR" -type f -iname 'libflashrom-*.dll' | head -n 1 || true)"
if [ -n "$LIBFLASHROM_DLL" ] && [ -f "$LIBFLASHROM_DLL" ]; then
  echo "Bundling: $LIBFLASHROM_DLL" >&2
  cp -n "$LIBFLASHROM_DLL" "$REL_DIR/"
fi

# Bundle dependent DLLs automatically using ntldd (portable zip)
if ! command -v ntldd >/dev/null 2>&1; then
  echo "ntldd not found; install mingw-w64-x86_64-ntldd-git in MSYS2" >&2
  exit 1
fi

echo "Resolving DLL dependencies via ntldd..." >&2
deps=()
while IFS= read -r dep; do
  deps+=("$dep")
done < <(
  ntldd -R "$EXE" 2>/dev/null \
    | awk '/=>/ {print $3}' \
    | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
    | grep -E '\.dll$' || true
)

if [ "${#deps[@]}" -eq 0 ]; then
  echo "Warning: ntldd returned no DLL dependencies; continuing." >&2
fi

for dep in "${deps[@]}"; do
  dep_msys="$dep"
  if [[ "$dep_msys" =~ ^[A-Za-z]:\\ ]]; then
    dep_msys="$(cygpath -u "$dep_msys" 2>/dev/null || echo "$dep")"
  fi

  case "$dep_msys" in
    /mingw64/bin/*.dll)
      if [ -f "$dep_msys" ]; then
        echo "Bundling: $dep_msys" >&2
        cp -n "$dep_msys" "$REL_DIR/"
      fi
      ;;
    *)
      ;;
  esac
done

# Write version stamp
cat > "$REL_DIR/FLASHROM_VERSION.txt" <<EOF
flashrom submodule commit: $COMMIT_FULL
flashrom nearest tag:      $TAG_NEAREST
build time (UTC):          $BUILD_UTC
EOF

ZIP_NAME="flashrom-${TAG_NEAREST}-${COMMIT_SHORT}-windows-x64.zip"
ZIP_PATH="$ROOT/$ZIP_NAME"

rm -f "$ZIP_PATH"
zip -j "$ZIP_PATH" "$REL_DIR"/* >/dev/null

# IMPORTANT: only output on stdout is the ZIP path for the workflow to capture
echo "$ZIP_PATH"
