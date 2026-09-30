extends SceneTree
## run_tests.gd
##
## Headless test runner.
## Invoke with:  godot --headless --path . --script tests/run_tests.gd
##
## Exits with code 0 on success, 1 on failure.

var _failures: int = 0


func _init() -> void:
	print("== Signal Drift test suite ==")

	# M1 / M2 tests
	_test_main_scene_exists()
	_test_project_file_parses()
	_test_all_registered_screens_exist()
	_test_signals_script_declares_expected_signals()
	_test_scene_router_navigates_and_returns()
	_test_main_menu_has_five_buttons()
	_test_main_menu_wires_new_game_to_radio_console()
	_test_sub_screens_have_back_button()
	_test_all_sub_screen_back_buttons_resolve()

	# M3 tests
	_test_radio_lock_result_no_target()
	_test_radio_lock_result_hit()
	_test_radio_lock_result_miss()
	_test_radio_lock_result_on_tolerance_boundary()

	print("")
	if _failures == 0:
		print("ALL TESTS PASSED")
		quit(0)
	else:
		print("FAILED: %d test(s)" % _failures)
		quit(1)


# ---------------------------------------------------------------------------
# M1 / M2 tests
# ---------------------------------------------------------------------------

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


func _test_main_menu_has_five_buttons() -> void:
	var path := "res://scenes/MainMenu.tscn"
	if not ResourceLoader.exists(path):
		_fail("MainMenu.tscn missing")
		return

	var scene: PackedScene = load(path)
	if scene == null:
		_fail("MainMenu.tscn failed to load")
		return

	var instance: Node = scene.instantiate()
	if instance == null:
		_fail("MainMenu.tscn failed to instantiate")
		return

	var buttons_root: Node = instance.get_node_or_null("Center/Buttons")
	if buttons_root == null:
		_fail("MainMenu: Buttons container not found at Center/Buttons")
		instance.free()
		return

	var count: int = 0
	for child in buttons_root.get_children():
		if child is Button:
			count += 1

	if count == 5:
		_pass("MainMenu has exactly 5 buttons")
	else:
		_fail("MainMenu has %d buttons (expected 5)" % count)

	instance.free()


func _test_main_menu_wires_new_game_to_radio_console() -> void:
	var path := "res://scenes/MainMenu.tscn"
	if not ResourceLoader.exists(path):
		_fail("MainMenu.tscn missing")
		return

	var scene: PackedScene = load(path)
	if scene == null:
		_fail("MainMenu.tscn failed to load")
		return

	var instance: Node = scene.instantiate()
	if instance == null:
		_fail("MainMenu.tscn failed to instantiate")
		return

	var required_paths := [
		"Center/Buttons/NewGameButton",
		"Center/Buttons/ContinueButton",
		"Center/Buttons/CodexButton",
		"Center/Buttons/SettingsButton",
		"Center/Buttons/QuitButton",
		"Center/VersionLabel",
	]

	var missing: Array[String] = []
	for p in required_paths:
		if instance.get_node_or_null(p) == null:
			missing.append(p)

	if missing.is_empty():
		_pass("MainMenu.gd @onready paths all resolve")
	else:
		_fail("MainMenu missing nodes: %s" % ", ".join(missing))

	instance.free()


func _test_sub_screens_have_back_button() -> void:
	var screens := {
		"RadioConsole": "res://scenes/RadioConsole.tscn",
		"MessageView":  "res://scenes/MessageView.tscn",
		"Codex":        "res://scenes/Codex.tscn",
		"Settings":     "res://scenes/Settings.tscn",
	}

	var missing: Array[String] = []
	for screen_name in screens.keys():
		var path: String = screens[screen_name]
		if not ResourceLoader.exists(path):
			missing.append("%s (file missing)" % screen_name)
			continue
		var scene: PackedScene = load(path)
		if scene == null:
			missing.append("%s (load failed)" % screen_name)
			continue
		var instance: Node = scene.instantiate()
		if instance == null:
			missing.append("%s (instantiate failed)" % screen_name)
			continue
		# RadioConsole now nests BackButton under VBox as well.
		var back: Node = instance.get_node_or_null("VBox/BackButton")
		if back == null:
			missing.append("%s (no VBox/BackButton)" % screen_name)
		instance.free()

	if missing.is_empty():
		_pass("all 4 sub-screens have VBox/BackButton")
	else:
		_fail("missing back buttons: %s" % ", ".join(missing))


func _test_all_sub_screen_back_buttons_resolve() -> void:
	var screen_scripts := {
		"RadioConsole": "res://scenes/RadioConsole.tscn",
		"MessageView":  "res://scenes/MessageView.tscn",
		"Codex":        "res://scenes/Codex.tscn",
		"Settings":     "res://scenes/Settings.tscn",
	}

	var missing: Array[String] = []
	for screen_name in screen_scripts.keys():
		var path: String = screen_scripts[screen_name]
		if not ResourceLoader.exists(path):
			missing.append("%s (file missing)" % screen_name)
			continue
		var scene: PackedScene = load(path)
		if scene == null:
			missing.append("%s (load failed)" % screen_name)
			continue
		var instance: Node = scene.instantiate()
		if instance == null:
			missing.append("%s (instantiate failed)" % screen_name)
			continue
		if instance.get_node_or_null("VBox/BackButton") == null:
			missing.append("%s ($VBox/BackButton)" % screen_name)
		instance.free()

	if missing.is_empty():
		_pass("all 4 sub-screen scripts' @onready paths resolve")
	else:
		_fail("broken @onready paths: %s" % ", ".join(missing))


# ---------------------------------------------------------------------------
# M3 tests — Radio core logic
# ---------------------------------------------------------------------------

func _test_radio_lock_result_no_target() -> void:
	var radio: RefCounted = _new_radio()
	if radio == null:
		_fail("cannot instantiate Radio")
		return

	var result: int = radio.try_lock()
	if result == radio.LockResult.NO_TARGET:
		_pass("Radio: try_lock with no target returns NO_TARGET")
	else:
		_fail("Radio: expected NO_TARGET, got %d" % result)


func _test_radio_lock_result_hit() -> void:
	var radio: RefCounted = _new_radio()
	if radio == null:
		_fail("cannot instantiate Radio")
		return

	radio.set_target(40.0, 60.0, 5.0)
	radio.freq = 40.0
	radio.amp = 60.0

	var result: int = radio.try_lock()
	if result == radio.LockResult.HIT:
		_pass("Radio: exact-match lock returns HIT")
	else:
		_fail("Radio: expected HIT, got %d" % result)


func _test_radio_lock_result_miss() -> void:
	var radio: RefCounted = _new_radio()
	if radio == null:
		_fail("cannot instantiate Radio")
		return

	radio.set_target(40.0, 60.0, 5.0)
	radio.freq = 10.0
	radio.amp = 60.0

	var result: int = radio.try_lock()
	if result == radio.LockResult.MISS:
		_pass("Radio: out-of-tolerance lock returns MISS")
	else:
		_fail("Radio: expected MISS, got %d" % result)


func _test_radio_lock_result_on_tolerance_boundary() -> void:
	var radio: RefCounted = _new_radio()
	if radio == null:
		_fail("cannot instantiate Radio")
		return

	radio.set_target(40.0, 60.0, 5.0)

	# Exactly on the edge of tolerance should still HIT (inclusive).
	radio.freq = 45.0  # 40 + 5
	radio.amp = 55.0   # 60 - 5
	var result: int = radio.try_lock()
	if result == radio.LockResult.HIT:
		_pass("Radio: boundary lock returns HIT (inclusive tolerance)")
	else:
		_fail("Radio: expected HIT at boundary, got %d" % result)


func _new_radio() -> RefCounted:
	var radio_script: GDScript = load("res://scripts/core/Radio.gd")
	if radio_script == null:
		return null
	return radio_script.new()


# --- helpers ---

func _pass(msg: String) -> void:
	print("  [PASS] %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("  [FAIL] %s" % msg)
