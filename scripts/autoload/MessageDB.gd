extends Node
## MessageDB.gd
##
## Loads messages from data/messages.json and exposes queries.
## Autoloaded as a singleton so every screen can call it.
##
## Usage:
##   MessageDB.get_all()             -> Array[Dictionary]
##   MessageDB.get_by_id("msg_001")  -> Dictionary or {}
##   MessageDB.get_current()         -> Dictionary or {}
##   MessageDB.advance()             -> moves current pointer forward

const DATA_PATH := "res://data/messages.json"

var _messages: Array = []
var _current_index: int = 0


func _ready() -> void:
	_load()


func _load() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		push_error("MessageDB: file not found: %s" % DATA_PATH)
		return

	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("MessageDB: cannot open %s" % DATA_PATH)
		return

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("MessageDB: invalid JSON in %s" % DATA_PATH)
		return

	if not parsed.has("messages") or typeof(parsed["messages"]) != TYPE_ARRAY:
		push_error("MessageDB: missing or invalid 'messages' array")
		return

	_messages = parsed["messages"]
	_current_index = 0


func get_all() -> Array:
	return _messages


func get_count() -> int:
	return _messages.size()


func get_by_id(message_id: String) -> Dictionary:
	for m in _messages:
		if m.get("id", "") == message_id:
			return m
	return {}


## Returns the message the player is currently working on,
## or {} if all have been decoded.
func get_current() -> Dictionary:
	if _current_index >= _messages.size():
		return {}
	return _messages[_current_index]


## Move to the next message. Returns true if there was one to advance to.
func advance() -> bool:
	if _current_index < _messages.size():
		_current_index += 1
	return _current_index < _messages.size()


## For tests and debugging.
func set_current_index(index: int) -> void:
	_current_index = clampi(index, 0, _messages.size())


func reset() -> void:
	_current_index = 0
