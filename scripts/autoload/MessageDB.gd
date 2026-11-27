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
##   MessageDB.record_decode(id)     -> records the current signal once

const DATA_PATH := "res://data/messages.json"

var _messages: Array = []
var _decoded_ids: Array[String] = []
var _last_decoded_id: String = ""


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
	reset()


func get_all() -> Array:
	return _messages


func get_count() -> int:
	return _messages.size()


func get_by_id(message_id: String) -> Dictionary:
	for m in _messages:
		if m.get("id", "") == message_id:
			return m
	return {}


## Bands unlock in order of their first appearance in the message pack.
## Every message in an earlier band must be decoded before the next opens.
func get_unlocked_bands() -> Array[String]:
	var bands: Array[String] = []
	for message in _messages:
		var band := str(message.get("band", "band_a"))
		if not bands.has(band):
			bands.append(band)
	var unlocked: Array[String] = []
	for band in bands:
		unlocked.append(band)
		for message in _messages:
			if str(message.get("band", "band_a")) == band:
				if not _decoded_ids.has(str(message.get("id", ""))):
					return unlocked
	return unlocked


func get_current() -> Dictionary:
	var unlocked := get_unlocked_bands()
	for message in _messages:
		if unlocked.has(str(message.get("band", "band_a"))) and not _decoded_ids.has(str(message.get("id", ""))):
			return message
	return {}


## Only the active target can be decoded; duplicate or locked IDs are rejected.
func record_decode(message_id: String) -> bool:
	var current := get_current()
	if current.is_empty() or current.get("id", "") != message_id or message_id.is_empty():
		return false
	_decoded_ids.append(message_id)
	_last_decoded_id = message_id
	return true


func get_decoded_ids() -> Array[String]:
	return _decoded_ids.duplicate()


func get_decoded_messages() -> Array[Dictionary]:
	var messages: Array[Dictionary] = []
	for message_id in _decoded_ids:
		var message := get_by_id(message_id)
		if not message.is_empty():
			messages.append(message)
	return messages


func get_last_decoded() -> Dictionary:
	return get_by_id(_last_decoded_id)


func reset() -> void:
	_decoded_ids.clear()
	_last_decoded_id = ""

## Only restore a valid ordered prefix; roll back any invalid input.
func restore_decoded_ids(ids: Array) -> bool:
	var previous := _decoded_ids.duplicate()
	var previous_last := _last_decoded_id
	reset()
	for id in ids:
		if not id is String or not record_decode(id):
			_decoded_ids = previous
			_last_decoded_id = previous_last
			return false
	return true
