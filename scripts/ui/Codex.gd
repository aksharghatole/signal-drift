extends Control
## Archive of decoded transmissions, in decode order.

@onready var back_button: Button = $VBox/BackButton
@onready var summary: Label = $VBox/Summary
@onready var entries: VBoxContainer = $VBox/Scroll/Entries


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	populate()


func populate() -> void:
	for child in entries.get_children():
		entries.remove_child(child)
		child.queue_free()
	var messages := MessageDB.get_decoded_messages()
	summary.text = "%d / %d transmissions decoded" % [messages.size(), MessageDB.get_count()]
	if messages.is_empty():
		var empty := Label.new()
		empty.text = "No transmissions decoded yet. Return to the radio to search."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entries.add_child(empty)
		return
	for message in messages:
		var heading := Label.new()
		heading.text = "%s — %s" % [str(message.get("band", "")).replace("_", " ").to_upper(), message.get("title", "Untitled")]
		heading.add_theme_font_size_override("font_size", 24)
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entries.add_child(heading)
		var body := Label.new()
		body.text = message.get("body", "")
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		entries.add_child(body)
		entries.add_child(HSeparator.new())


func _on_back_pressed() -> void:
	SceneRouter.go_back()
