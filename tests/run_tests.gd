extends SceneTree
## run_tests.gd
##
## Headless test runner.
## Invoke with:  godot --headless --path . --script tests/run_tests.gd
##
## Exits with code 0 on success, 1 on failure.
##
## Note: this script extends SceneTree, so it is not a Node and cannot use
## get_node() with absolute paths. It instantiates scripts directly instead
## of relying on Godot's autoload machinery.

var _failures: int = 0


func _init() -> void:
	print("== Signal Drift test suite ==")

	_test_main_scene_exists()
	_test_project_file_parses()
	_test_all_registered_screens_exist()
	_test_signals_script_declares_expected_signals()
	_test_scene_router_navigates_and_returns()

	print("")
	if _failures == 0:
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("FAILED: %d test(s)" % _failures)
		quit(1)


func _test_main_scene_exists() -> void:
	var path := "res://scenes/Main.tscn"
	if ResourceLoader.exists(path):
		_pass("main scene exists: %s" % path)
	else:
		_fail("main scene missing: %s" % path)


func _test_project_file_parses() -> void:
	var app_name: String = ProjectSettings.get_setting("application/config/name", "")
	if app_name == "Signal Drift":
		_pass("project name is 'Signal Drift'")
	else:
		_fail("project name unexpected: '%s'" % app_name)


func _test_all_registered_screens_exist() -> void:
	var router_script: GDScript = load("res://scripts/autoload/SceneRouter.gd")
	if router_script == null:
		_fail("cannot load SceneRouter.gd")
		return

	var constants: Dictionary = router_script.get_script_constant_map()
	if not constants.has("SCREENS"):
		_fail("SceneRouter.SCREENS constant missing")
		return

	var screens: Dictionary = constants["SCREENS"]
	if screens.is_empty():
		_fail("SCREENS dictionary empty")
		return

	var missing: Array[String] = []
	for screen_name in screens.keys():
		var path: String = screens[screen_name]
		if not ResourceLoader.exists(path):
			missing.append("%s -> %s" % [screen_name, path])

	if missing.is_empty():
		_pass("all %d registered screens exist" % screens.size())
	else:
		_fail("missing screens: %s" % ", ".join(missing))


func _test_signals_script_declares_expected_signals() -> void:
	var signals_script: GDScript = load("res://scripts/autoload/Signals.gd")
	if signals_script == null:
		_fail("cannot load Signals.gd")
		return

	# Instantiate the script so we can ask about its signals.
	# The script extends Node, so instantiate() gives us a real Node.
	var signals_instance: Object = signals_script.new()
	if signals_instance == null:
		_fail("cannot instantiate Signals.gd")
		return

	var expected := ["screen_requested", "screen_changed", "game_started", "message_decoded"]
	var present: Array = []
	for s in signals_instance.get_signal_list():
		present.append(s["name"])

	var missing: Array[String] = []
	for sig in expected:
		if not present.has(sig):
			missing.append(sig)

	if missing.is_empty():
		_pass("Signals script declares all expected signals")
	else:
		_fail("Signals missing: %s" % ", ".join(missing))

	signals_instance.free()


func _test_scene_router_navigates_and_returns() -> void:
	var router_script: GDScript = load("res://scripts/autoload/SceneRouter.gd")
	if router_script == null:
		_fail("cannot load SceneRouter.gd")
		return

	var router: Node = router_script.new()
	if router == null:
		_fail("cannot instantiate SceneRouter")
		return

	var container := Node.new()
	get_root().add_child(container)
	router.attach_container(container)

	router.go_to("main_menu")
	if router.current_screen() != "main_menu":
		_fail("router did not navigate to main_menu")
		container.queue_free()
		router.free()
		return

	router.go_to("radio_console")
	if router.current_screen() != "radio_console":
		_fail("router did not navigate to radio_console")
		container.queue_free()
		router.free()
		return

	router.go_back()
	if router.current_screen() != "main_menu":
		_fail("router go_back() did not return to main_menu")
		container.queue_free()
		router.free()
		return

	_pass("router navigates and returns correctly")
	container.queue_free()
	router.free()


# --- helpers ---

func _pass(msg: String) -> void:
	print("  [PASS] %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("  [FAIL] %s" % msg)
