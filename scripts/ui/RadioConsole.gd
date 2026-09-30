extends Control
## RadioConsole.gd
##
## UI layer for the radio console. Handles dial input, updates the
## waveform, and displays lock results.
##
## All gameplay rules live in scripts/core/Radio.gd — this script only
## translates input into Radio calls and Radio results into UI updates.

const COOLDOWN_SECONDS := 2.0
const TEST_TOLERANCE := 5.0  ## Temporary. M5 will load targets from data.

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
	_radio.set_target(34.0, 61.0, TEST_TOLERANCE)

	freq_slider.value_changed.connect(_on_freq_changed)
	amp_slider.value_changed.connect(_on_amp_changed)
	lock_button.pressed.connect(_on_lock_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Push initial state into the radio and display.
	_on_freq_changed(freq_slider.value)
	_on_amp_changed(amp_slider.value)
	status_label.text = "Search for a signal."


func _process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta
		if _cooldown_remaining <= 0.0:
			lock_button.disabled = false
			status_label.text = "Search for a signal."


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
			status_label.text = "Signal locked!"
			# M5 will route this to the message system via Signals.
			Signals.message_decoded.emit("test_signal_m3")
			_start_cooldown()
		Radio.LockResult.MISS:
			status_label.text = "No signal at this position."
		Radio.LockResult.NO_TARGET:
			status_label.text = "No target set."


func _start_cooldown() -> void:
	_cooldown_remaining = COOLDOWN_SECONDS
	lock_button.disabled = true


func _on_back_pressed() -> void:
	SceneRouter.go_back()
