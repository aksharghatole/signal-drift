extends Node
## Signals.gd
##
## Global event bus. UI and gameplay code talk through this, not through
## direct references to each other. Keeps the tree loosely coupled and
## testable.
##
## Usage:
##   Signals.screen_requested.emit("radio_console")
##   Signals.screen_requested.connect(_on_screen_requested)

signal screen_requested(screen_name: String)
signal screen_changed(screen_name: String)

signal game_started()
signal message_decoded(message_id: String)
