extends Node
## Versioned local progress; temporary-file replacement avoids truncating
## the last good save if a write is interrupted.
const SAVE_VERSION := 1
var save_path: String = "user://save.json"
var _has_session: bool = false


func _ready() -> void:
	if "--run-tests" in OS.get_cmdline_args():
		return
	load_progress()
	Signals.game_started.connect(_on_game_started)
	Signals.message_decoded.connect(_on_message_decoded)


func has_session() -> bool:
	return _has_session


func _on_game_started() -> void:
	_has_session = true
	save()


func _on_message_decoded(_message_id: String) -> void:
	_has_session = true
	save()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _has_session:
			save()


func save() -> bool:
	if not _has_session:
		return false
	var temporary_path := save_path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": SAVE_VERSION, "decoded_ids": MessageDB.get_decoded_ids()}))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(temporary_path)
		return false
	var error := DirAccess.rename_absolute(temporary_path, save_path)
	if error != OK:
		DirAccess.remove_absolute(temporary_path)
		return false
	return true


func load_progress() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return false
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()
	if error != OK or not json.data is Dictionary:
		return false
	var data: Dictionary = json.data
	if data.get("version") != SAVE_VERSION or not data.get("decoded_ids") is Array:
		return false
	if not MessageDB.restore_decoded_ids(data["decoded_ids"]):
		return false
	_has_session = true
	return true


func erase() -> bool:
	if FileAccess.file_exists(save_path):
		if DirAccess.remove_absolute(save_path) != OK:
			return false
	if FileAccess.file_exists(save_path + ".tmp"):
		DirAccess.remove_absolute(save_path + ".tmp")
	_has_session = false
	MessageDB.reset()
	return true
