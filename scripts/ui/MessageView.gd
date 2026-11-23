extends Control
## MessageView.gd
##
## Displays the decoded message pulled from MessageDB.get_current().
## On Back, advances MessageDB to the next message and returns to the
## radio console.

const CHARACTERS_PER_SECOND := 55.0

@onready var title_label: Label = $VBox/TitleLabel
@onready var body_label: Label  = $VBox/BodyScroll/BodyLabel
@onready var back_button: Button = $VBox/BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_display_current_message()


func _display_current_message() -> void:
	var msg: Dictionary = MessageDB.get_current()
	if msg.is_empty():
		title_label.text = "No message"
		body_label.text = "No signal is currently being decoded."
		return

	title_label.text = msg.get("title", "Untitled")
	body_label.text = msg.get("body", "")
	var character_count := body_label.get_total_character_count()
	if character_count == 0:
		return

	# Reveal the text without changing the label's wrapping as it appears.
	body_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	body_label.visible_characters = 0
	var reveal := create_tween()
	reveal.tween_property(
		body_label, "visible_characters", character_count, character_count / CHARACTERS_PER_SECOND
	)


func _on_back_pressed() -> void:
	# Player read the message; move to the next one.
	MessageDB.advance()
	SceneRouter.go_back()
