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

	_test_main_scene_exists()
	_test_project_file_parses()

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
	# If we're running at all, project.godot parsed (Godot refuses to start otherwise).
	# This test is a canary.
	var app_name: String = ProjectSettings.get_setting("application/config/name", "")
	if app_name == "Signal Drift":
		_pass("project name is 'Signal Drift'")
	else:
		_fail("project name unexpected: '%s'" % app_name)


func _pass(msg: String) -> void:
	print("  [PASS] %s" % msg)


func _fail(msg: String) -> void:
	_failures += 1
	print("  [FAIL] %s" % msg)
