#!/usr/bin/env bash
# Download the prebuilt Android arm64 runtime (FreeCAD/CPython/Qt libs) that is
# not stored in the repository, verify its checksum and extract it into the tree.
#
#   tools/fetch-runtime.sh
#
# Override with RUNTIME_TAG / RUNTIME_ASSET / RUNTIME_BASE / RUNTIME_CACHE.
set -euo pipefail
cd "$(dirname "$0")/.."

TAG="${RUNTIME_TAG:-runtime-0.5.18}"
ASSET="${RUNTIME_ASSET:-runtime-arm64-e95a31c.tar.zst}"
BASE="${RUNTIME_BASE:-https://github.com/Toobe53/mobilecad/releases/download/$TAG}"
CACHE="${RUNTIME_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/mobilecad-runtime}"

command -v zstd >/dev/null || { echo "zstd is required (brew install zstd / apt install zstd)" >&2; exit 1; }
mkdir -p "$CACHE"

fetch() {
  local name="$1"
  local dest="$CACHE/$name"
  if [ -s "$dest" ]; then return; fi
  echo "downloading $name …"
  curl -fL --retry 3 --retry-delay 2 -o "$dest.part" "$BASE/$name"
  mv "$dest.part" "$dest"
}

fetch "$ASSET"
fetch SHA256SUMS-runtime
( cd "$CACHE" && grep " $ASSET\$" SHA256SUMS-runtime | shasum -a 256 -c - )

echo "extracting $ASSET …"
zstd -dc "$CACHE/$ASSET" | tar -xf - -C .
echo "runtime ready (FreeCAD e95a31c / Python 3.14)"
