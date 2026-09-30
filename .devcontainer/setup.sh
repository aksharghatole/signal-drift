#!/usr/bin/env bash
# Installs Godot 4.3 (headless-capable Linux binary) into the devcontainer.
# Detects x86_64 vs aarch64 and downloads the matching build.
set -euo pipefail

GODOT_VERSION="4.3-stable"
GODOT_DIR="$HOME/.local/bin"
GODOT_BIN="$GODOT_DIR/godot"

case "$(uname -m)" in
  x86_64|amd64)  FILE="Godot_v${GODOT_VERSION}_linux.x86_64.zip" ;;
  aarch64|arm64) FILE="Godot_v${GODOT_VERSION}_linux.arm64.zip"  ;;
  *) echo "ERROR: unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${FILE}"

mkdir -p "$GODOT_DIR"

# If a working Godot is already installed, do nothing.
if [ -x "$GODOT_BIN" ] && "$GODOT_BIN" --version >/dev/null 2>&1; then
  echo "Godot already installed and runnable at $GODOT_BIN"
  "$GODOT_BIN" --version
  exit 0
fi

# Remove any broken/impostor godot from prior runs.
rm -f "$GODOT_BIN"

echo ">> Detected architecture: $(uname -m)"
echo ">> Downloading $FILE ..."
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
curl -fsSL "$URL" -o "$TMP/$FILE"

echo ">> Extracting..."
# -j = junk paths, extracts just the file (flattens the top-level folder)
unzip -q -j "$TMP/$FILE" -d "$TMP/extracted"

# Find the actual binary anywhere under the extracted dir.
EXTRACTED="$(find "$TMP/extracted" -type f -name 'Godot_v*' | head -n1)"
if [ -z "$EXTRACTED" ]; then
  echo "ERROR: could not find extracted Godot binary." >&2
  echo "Contents of extracted dir:" >&2
  ls -laR "$TMP/extracted" >&2
  exit 1
fi

# Sanity-check that we actually extracted an ELF binary, not a zip/html/etc.
if ! head -c 4 "$EXTRACTED" | grep -q $'\x7fELF'; then
  echo "ERROR: extracted file is not an ELF binary." >&2
  echo "File type:" >&2
  file "$EXTRACTED" >&2
  exit 1
fi

mv "$EXTRACTED" "$GODOT_BIN"
chmod +x "$GODOT_BIN"

if ! grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo ">> Godot installed at $GODOT_BIN"
"$GODOT_BIN" --version
