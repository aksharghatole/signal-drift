extends Control
const Radio := preload("res://scripts/core/Radio.gd")
## RadioConsole.gd
##
## UI layer for the radio console.
## Reads the current target from MessageDB, updates the waveform display,
## and on a successful lock routes the player to the MessageView screen.

const COOLDOWN_SECONDS := 2.0

@onready var freq_slider: Range           = $VBox/Dials/Frequency/FreqDial
@onready var amp_slider: Range            = $VBox/Dials/Amplitude/AmpDial
@onready var freq_value: Label            = $VBox/Dials/Frequency/FreqValue
@onready var amp_value: Label             = $VBox/Dials/Amplitude/AmpValue
@onready var waveform: Control            = $VBox/Waveform
@onready var lock_button: Button          = $VBox/LockButton
@onready var status_label: Label          = $VBox/StatusLabel
@onready var back_button: Button          = $VBox/BackButton
@onready var signal_meter: ProgressBar    = $VBox/SignalMeter
@onready var signal_label: Label          = $VBox/SignalLabel

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
	status_label.text = "%s • %d/%d decoded" % [str(msg.get("band", "band_a")).replace("_", " ").to_upper(), MessageDB.get_decoded_ids().size(), MessageDB.get_count()]


func _process(delta: float) -> void:
	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta
		if _cooldown_remaining <= 0.0:
			lock_button.disabled = false


func _on_freq_changed(value: float) -> void:
	_radio.freq = value
	freq_value.text = "%d" % int(value)
	_update_feedback()


func _on_amp_changed(value: float) -> void:
	_radio.amp = value
	amp_value.text = "%d" % int(value)
	_update_feedback()


func _update_feedback() -> void:
	var quality := _radio.signal_quality()
	waveform.set_values(_radio.freq, _radio.amp, quality)
	signal_meter.value = quality * 100.0
	if _radio.target == null:
		signal_label.text = "NO ACTIVE SIGNAL"
	elif _radio.try_lock() == Radio.LockResult.HIT:
		signal_label.text = "SIGNAL ALIGNED • LOCK READY"
	elif quality > 0.55:
		signal_label.text = "SIGNAL NEARBY"
	else:
		signal_label.text = "SCANNING • INTERFERENCE"


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
	var msg_id: String = msg.get("id", "")
	if not MessageDB.record_decode(msg_id):
		return

	Signals.message_decoded.emit(msg_id)

	_cooldown_remaining = COOLDOWN_SECONDS
	lock_button.disabled = true

	# Route to the message view. The player reads the message, then
	# presses Back to return to the next unlocked signal.
	SceneRouter.go_to("message_view")


func _on_back_pressed() -> void:
	SceneRouter.go_back()
