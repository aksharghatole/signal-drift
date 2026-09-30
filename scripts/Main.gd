extends Node
## Main.gd
##
## Root node of the game. Attaches the ScreenContainer to the SceneRouter
## and navigates to the initial screen.
##
## Test mode: if the command line contains "--run-tests", we skip navigating
## to the main menu and instead load the test runner, execute it, and quit
## with its status code. This runs tests in the same environment as the real
## game (autoloads registered, class_name types visible), which avoids the
## false-positive SCRIPT ERROR noise from --script mode.
##
## The runner is invoked on the next process frame, after Main._ready()
## has finished and the scene tree is free to accept new children.

const BOOT_MESSAGE := "Signal Drift - boot OK"
const VERSION := "0.1.0"
const TEST_FLAG := "--run-tests"

@onready var screen_container: Node = $ScreenContainer


func _ready() -> void:
	print("%s (v%s)" % [BOOT_MESSAGE, VERSION])

	if _has_test_flag():
		_run_tests_deferred()
		return

	# Normal game boot.
	SceneRouter.attach_container(screen_container)
	SceneRouter.go_to("main_menu")

	if DisplayServer.get_name() == "headless":
		print("Headless boot detected. Exiting.")
		get_tree().quit(0)


func _has_test_flag() -> bool:
	for arg in OS.get_cmdline_args():
		if arg == TEST_FLAG:
			return true
	return false


func _run_tests_deferred() -> void:
	# Wait one frame so Main._ready() completes and the scene tree is
	# fully set up before we hand control to the test runner.
	await get_tree().process_frame
	_run_tests()


func _run_tests() -> void:
	var runner_script: GDScript = load("res://tests/run_tests.gd")
	if runner_script == null:
		push_error("Main: cannot load test runner at res://tests/run_tests.gd")
		get_tree().quit(2)
		return

	var runner: RefCounted = runner_script.new()
	if runner == null:
		push_error("Main: cannot instantiate test runner")
		get_tree().quit(2)
		return

	var failures: int = runner.run_all()
	get_tree().quit(0 if failures == 0 else 1)
