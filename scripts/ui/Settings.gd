extends Control
## Local save management.
@onready var back_button: Button = $VBox/BackButton
@onready var erase_button: Button = $VBox/EraseButton
@onready var status_label: Label = $VBox/Status
@onready var confirmation: ConfirmationDialog = $EraseConfirmation


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	erase_button.pressed.connect(_on_erase_pressed)
	confirmation.confirmed.connect(_erase_save)
	erase_button.disabled = not SaveManager.has_session() and not FileAccess.file_exists(SaveManager.save_path)
	status_label.text = "Local save management"


func _on_erase_pressed() -> void:
	confirmation.popup_centered()


func _erase_save() -> void:
	if SaveManager.erase():
		status_label.text = "Saved progress erased."
		erase_button.disabled = true
	else:
		status_label.text = "Could not erase the save. Please try again."


func _on_back_pressed() -> void:
	SceneRouter.go_back()
