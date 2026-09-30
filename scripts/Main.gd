extends Node
## Main.gd
##
## Root node of the game. Attaches the ScreenContainer to the SceneRouter
## and navigates to the initial screen.

const BOOT_MESSAGE := "Signal Drift - boot OK"
const VERSION := "0.1.0"

@onready var screen_container: Node = $ScreenContainer


func _ready() -> void:
	print("%s (v%s)" % [BOOT_MESSAGE, VERSION])

	# Wire the router to the container this scene owns.
	SceneRouter.attach_container(screen_container)

	# Boot to the main menu.
	SceneRouter.go_to("main_menu")

	# In headless mode we quit right after booting so CI smoke tests are fast.
	if DisplayServer.get_name() == "headless":
		print("Headless boot detected. Exiting.")
		get_tree().quit(0)
