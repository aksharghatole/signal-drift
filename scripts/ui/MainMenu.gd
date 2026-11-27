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
	continue_button.disabled = not SaveManager.has_session()

	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	codex_button.pressed.connect(_on_codex_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_new_game_pressed() -> void:
	if SaveManager.has_session():
		var confirm := ConfirmationDialog.new()
		confirm.title = "Start a new game?"
		confirm.dialog_text = "This replaces your current radio progress."
		confirm.confirmed.connect(_start_new_game)
		confirm.confirmed.connect(confirm.queue_free)
		confirm.canceled.connect(confirm.queue_free)
		add_child(confirm)
		confirm.popup_centered()
		return
	_start_new_game()


func _start_new_game() -> void:
	MessageDB.reset()
	Signals.game_started.emit()
	SceneRouter.go_to("radio_console")


func _on_continue_pressed() -> void:
	if SaveManager.has_session():
		SceneRouter.go_to("radio_console")


func _on_codex_pressed() -> void:
	SceneRouter.go_to("codex")


func _on_settings_pressed() -> void:
	SceneRouter.go_to("settings")


func _on_quit_pressed() -> void:
	if SaveManager.has_session():
		SaveManager.save()
	get_tree().quit(0)
