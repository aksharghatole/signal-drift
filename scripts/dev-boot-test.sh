#!/usr/bin/env bash
# Boot the project headlessly and exit. Used as a smoke test.
set -euo pipefail

if ! command -v godot >/dev/null 2>&1; then
  echo "ERROR: 'godot' not found on PATH." >&2
  echo "Run the devcontainer, or install Godot 4.x manually." >&2
  exit 127
fi

echo ">> Booting Signal Drift headlessly..."
godot --headless --path . --quit-after 5

echo ">> Boot test complete."
