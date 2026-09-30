# Signal Drift

A radio-tuning puzzle game for Android. You are the last operator
listening after a global storm.

## Status

Playable MVP loop: main menu → radio console → decoded messages.

See the Issues page for the roadmap and open work.

## Tech

- Engine: Godot 4.3 (GDScript)
- Target: Android (API 26+)
- Dev env: GitHub Codespaces
- License: MIT (see LICENSE)

## Resume Development

1. Open the Codespace for this repo (or create a new one)
2. Godot is installed automatically via `.devcontainer/setup.sh`
3. Run tests: `./scripts/dev-boot-test.sh`
4. Game entry point: `scenes/Main.tscn`

## Development Commands

    # Run the test suite (clean, no noise)
    ./scripts/dev-boot-test.sh

    # Boot the game headlessly (smoke test)
    godot --headless --path . --quit-after 5

    # Open in the editor
    # Requires local Godot 4.3. Point it at this folder, open project.godot.

## Project structure

    assets/         fonts, audio, icon
    data/           messages.json and content
    scenes/         .tscn scene files
    scripts/
      autoload/     Signals, SceneRouter, MessageDB
      core/         Radio, WaveformDisplay (no UI)
      ui/           one script per screen
    tests/          headless test runner

## License

MIT
