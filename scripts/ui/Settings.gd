extends Control
## Local save management.
@onready var back_button: Button = $VBox/BackButton
@onready var erase_button: Button = $VBox/EraseButton
@onready var status_label: Label = $VBox/Status
@onready var confirmation: ConfirmationDialog = $EraseConfirmation
@onready var volume_slider: HSlider = $VBox/VolumeSlider
@onready var volume_label: Label = $VBox/VolumeLabel


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	erase_button.pressed.connect(_on_erase_pressed)
	confirmation.confirmed.connect(_erase_save)
	erase_button.disabled = not SaveManager.has_session() and not FileAccess.file_exists(SaveManager.save_path)
	status_label.text = "Local save management"
	volume_slider.set_value_no_signal(AudioManager.master_volume * 100.0)
	volume_label.text = "MASTER VOLUME  %d%%" % int(round(volume_slider.value))
	volume_slider.value_changed.connect(_on_volume_changed)


func _on_volume_changed(value: float) -> void:
	AudioManager.set_master_volume(value / 100.0)
	volume_label.text = "MASTER VOLUME  %d%%" % int(round(value))


func _on_erase_pressed() -> void:
	confirmation.popup_centered()


func _erase_save() -> void:
	if SaveManager.erase():
		status_label.text = "Saved progress erased."
		erase_button.disabled = true
	else:
		status_label.text = "Could not erase the save. Please try again."


func _on_back_pressed() -> void:
	AudioManager.save_preferences()
	SceneRouter.go_back()
