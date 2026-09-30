extends Node
## SceneRouter.gd
##
## Owns the current screen and swaps children of the ScreenContainer node
## inside Main.tscn. Screens are registered by name so callers don't have
## to know file paths.
##
## Usage from any script:
##   SceneRouter.go_to("radio_console")
##   SceneRouter.go_back()

const SCREENS: Dictionary = {
	"main_menu":     "res://scenes/MainMenu.tscn",
	"radio_console": "res://scenes/RadioConsole.tscn",
	"message_view":  "res://scenes/MessageView.tscn",
	"codex":         "res://scenes/Codex.tscn",
	"settings":      "res://scenes/Settings.tscn",
}

## Where the router mounts the current screen. Set by Main.gd during boot.
var container: Node = null

var _current: String = ""
var _history: Array[String] = []


func _ready() -> void:
	var sig_bus := _get_signals()
	if sig_bus:
		sig_bus.screen_requested.connect(go_to)


## Mount the given screen inside `container`. Safe to call before container
## is assigned — it just logs and returns.
func go_to(screen_name: String) -> void:
	if not SCREENS.has(screen_name):
		push_error("SceneRouter: unknown screen '%s'" % screen_name)
		return

	if container == null:
		push_warning("SceneRouter: container not set; deferring '%s'" % screen_name)
		_current = screen_name
		return

	if _current != "":
		_history.append(_current)

	_swap(screen_name)


## Return to the previous screen, if any.
func go_back() -> void:
	if _history.is_empty():
		push_warning("SceneRouter: go_back() with empty history")
		return
	var prev: String = _history.pop_back()
	_swap(prev)


func current_screen() -> String:
	return _current


## Called by Main.gd after the ScreenContainer exists.
func attach_container(node: Node) -> void:
	container = node
	if _current != "" and container.get_child_count() == 0:
		_swap(_current)


# --- internals ---

## Look up the Signals autoload by path, but only when we're inside the tree.
## Returns null when running as a standalone Node (e.g. in unit tests).
func _get_signals() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/Signals")


func _swap(screen_name: String) -> void:
	for child in container.get_children():
		child.queue_free()

	var path: String = SCREENS[screen_name]
	var scene: PackedScene = load(path)
	if scene == null:
		push_error("SceneRouter: failed to load '%s'" % path)
		return

	var instance: Node = scene.instantiate()
	container.add_child(instance)

	_current = screen_name

	var sig_bus := _get_signals()
	if sig_bus:
		sig_bus.screen_changed.emit(screen_name)
