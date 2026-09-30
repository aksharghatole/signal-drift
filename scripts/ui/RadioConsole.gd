extends Control
## RadioConsole.gd
##
## Placeholder for M3. Will host the tuning dials and waveform display.
## For now, only the Back button is wired.

@onready var back_button: Button = $VBox/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	SceneRouter.go_back()
