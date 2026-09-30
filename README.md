# Signal Drift

A radio-tuning puzzle game for Android. You are the last operator listening
after a global storm.

## Status

Milestone 1: Project boots.

## Tech

- **Engine:** Godot 4.x (GDScript)
- **Target:** Android (API 26+)
- **Dev env:** GitHub Codespaces
- **License:** MIT (see LICENSE)

## Development

### Boot test (headless)

    ./scripts/dev-boot-test.sh

Or directly:

    godot --headless --path . --quit-after 3

### Run tests (headless)

    godot --headless --path . --script tests/run_tests.gd

### Open in editor

Point a **local** Godot 4.x installation at this repo folder and open
`project.godot`. Codespaces itself does not provide the graphical editor.

## Android build

See `docs/android-build.md` (added in Milestone 9).

## Project structure

    assets/       fonts, audio, icon
    data/         messages.json and other content
    scenes/       .tscn scene files
    scripts/      GDScript source
      autoload/   singletons
      core/       gameplay logic (no UI)
      ui/         UI scripts
    tests/        headless test scripts

## License

MIT
