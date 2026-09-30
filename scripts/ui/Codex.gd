extends Control
## Codex.gd
##
## Placeholder for M6. Will list unlocked messages.
## For now, only the Back button is wired.

@onready var back_button: Button = $VBox/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	SceneRouter.go_back()
