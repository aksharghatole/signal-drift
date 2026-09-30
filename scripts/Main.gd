extends Node
## Main.gd
##
## Root node of the game. In Milestone 1 it only proves the project boots.
## Later milestones will hand off control to the SceneRouter.

const BOOT_MESSAGE := "Signal Drift — boot OK"
const VERSION := "0.1.0"


func _ready() -> void:
	print("%s (v%s)" % [BOOT_MESSAGE, VERSION])

	# In headless mode (CI / smoke test) we quit right after booting.
	# In a real window we leave the app running.
	if DisplayServer.get_name() == "headless":
		print("Headless boot detected. Exiting.")
		get_tree().quit(0)
