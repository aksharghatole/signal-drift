extends Control
## MainMenu.gd
##
## Main menu screen. Wires the five top-level buttons to SceneRouter.
## Handles the Quit button, which is the only button that doesn't route.

const VERSION_LABEL := "v0.1.0"

@onready var new_game_button: Button   = $Center/Buttons/NewGameButton
@onready var continue_button: Button   = $Center/Buttons/ContinueButton
@onready var codex_button: Button      = $Center/Buttons/CodexButton
@onready var settings_button: Button   = $Center/Buttons/SettingsButton
@onready var quit_button: Button       = $Center/Buttons/QuitButton
@onready var version_label: Label      = $Center/VersionLabel


func _ready() -> void:
	version_label.text = VERSION_LABEL

	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	codex_button.pressed.connect(_on_codex_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_new_game_pressed() -> void:
	Signals.game_started.emit()
	SceneRouter.go_to("radio_console")


func _on_continue_pressed() -> void:
	# M2b placeholder: no save system yet, so Continue behaves like New Game.
	# In M7 this will load the most recent save.
	SceneRouter.go_to("radio_console")


func _on_codex_pressed() -> void:
	SceneRouter.go_to("codex")


func _on_settings_pressed() -> void:
	SceneRouter.go_to("settings")


func _on_quit_pressed() -> void:
	get_tree().quit(0)
