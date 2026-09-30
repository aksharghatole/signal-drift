extends Control
const Radio := preload("res://scripts/core/Radio.gd")
## RadioConsole.gd
##
## UI layer for the radio console.
## Reads the current target from MessageDB, updates the waveform display,
## and on a successful lock routes the player to the MessageView screen.

const COOLDOWN_SECONDS := 2.0
const FALLBACK_SIGNAL_ID := "sig"

@onready var freq_slider: HSlider         = $VBox/FreqRow/FreqSlider
@onready var amp_slider: HSlider          = $VBox/AmpRow/AmpSlider
@onready var freq_value: Label            = $VBox/FreqRow/FreqValue
@onready var amp_value: Label             = $VBox/AmpRow/AmpValue
@onready var waveform: Control            = $VBox/Waveform
@onready var lock_button: Button          = $VBox/LockButton
@onready var status_label: Label          = $VBox/StatusLabel
@onready var back_button: Button          = $VBox/BackButton

var _radio: Radio = null
var _cooldown_remaining: float = 0.0


func _ready() -> void:
	_radio = Radio.new()

	freq_slider.value_changed.connect(_on_freq_changed)
	amp_slider.value_changed.connect(_on_amp_changed)
	lock_button.pressed.connect(_on_lock_pressed)
	back_button.pressed.connect(_on_back_pressed)

	_load_current_target()

	_on_freq_changed(freq_slider.value)
	_on_amp_changed(amp_slider.value)


func _load_current_target() -> void:
	var msg: Dictionary = MessageDB.get_current()
	if msg.is_empty():
		_radio.clear_target()
		status_label.text = "All signals decoded."
		lock_button.disabled = true
		return

	lock_button.disabled = false
	_radio.set_target(
		float(msg.get("target_freq", 50)),
		float(msg.get("target_amp", 50)),
		float(msg.get("tolerance", 6))
	)
	status_label.text = "Search for a signal."


func _process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta
		if _cooldown_remaining <= 0.0:
			lock_button.disabled = false


func _on_freq_changed(value: float) -> void:
	_radio.freq = value
	freq_value.text = "%d" % int(value)
	waveform.set_values(_radio.freq, _radio.amp)


func _on_amp_changed(value: float) -> void:
	_radio.amp = value
	amp_value.text = "%d" % int(value)
	waveform.set_values(_radio.freq, _radio.amp)


func _on_lock_pressed() -> void:
	if _cooldown_remaining > 0.0:
		return

	var result: Radio.LockResult = _radio.try_lock()
	match result:
		Radio.LockResult.HIT:
			_on_hit()
		Radio.LockResult.MISS:
			status_label.text = "No signal at this position."
		Radio.LockResult.NO_TARGET:
			status_label.text = "No target set."


func _on_hit() -> void:
	var msg: Dictionary = MessageDB.get_current()
	var msg_id: String = msg.get("id", FALLBACK_SIGNAL_ID)

	Signals.message_decoded.emit(msg_id)

	_cooldown_remaining = COOLDOWN_SECONDS
	lock_button.disabled = true

	# Route to the message view. The player reads the message, then
	# presses Back, which advances MessageDB and returns here.
	SceneRouter.go_to("message_view")


func _on_back_pressed() -> void:
	SceneRouter.go_back()
