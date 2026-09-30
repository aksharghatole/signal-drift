#!/usr/bin/env bash
# Run the Signal Drift test suite via the --test flag.
# This runs in the same environment as the real game (autoloads registered,
# class_name types visible) so output is clean — no false-positive
# SCRIPT ERROR lines from --script mode.
set -euo pipefail

if ! command -v godot >/dev/null 2>&1; then
  echo "ERROR: 'godot' not found on PATH." >&2
  echo "Run the devcontainer, or install Godot 4.x manually." >&2
  exit 127
fi

echo ">> Running Signal Drift test suite..."
godot --headless --path . --run-tests

echo ">> Test run complete."
