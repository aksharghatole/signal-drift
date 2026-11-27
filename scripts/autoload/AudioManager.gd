extends Node
## Original synthesized receiver audio. No downloaded assets or audio imports.
const SAMPLE_RATE := 22050
const DEFAULT_VOLUME := 0.7
const DURATIONS := {"ui_click": 0.065, "decode_success": 0.55, "decode_fail": 0.25, "ambient_hum": 4.0}
var settings_path := "user://audio.cfg"
var master_volume := DEFAULT_VOLUME
var _effects: Dictionary = {}
var _click: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _quality := 0.0


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	load_preferences()
	for key in DURATIONS:
		_effects[key] = make_sound(key)
	_click = AudioStreamPlayer.new()
	_click.stream = _effects["ui_click"]
	_click.max_polyphony = 2
	add_child(_click)
	_sfx = AudioStreamPlayer.new()
	_sfx.max_polyphony = 4
	add_child(_sfx)
	_ambient = AudioStreamPlayer.new()
	_ambient.stream = _effects["ambient_hum"]
	add_child(_ambient)
	_apply_volume()
	get_tree().node_added.connect(_on_node_added)
	Signals.screen_changed.connect(_on_screen_changed)


func _on_node_added(node: Node) -> void:
	if node is Button:
		node.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	play_sfx("ui_click")


func _on_screen_changed(screen_name: String) -> void:
	if _ambient == null:
		return
	if screen_name == "radio_console":
		if not _ambient.playing:
			_ambient.play()
	else:
		_ambient.stop()


func set_signal_quality(value: float) -> void:
	_quality = clampf(value, 0.0, 1.0)
	_apply_volume()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_volume()


func _apply_volume() -> void:
	for player in [_click, _sfx]:
		if player != null:
			player.volume_db = linear_to_db(maxf(master_volume, 0.0001))
			if is_zero_approx(master_volume):
				player.stop()
	if _ambient != null:
		_ambient.volume_db = linear_to_db(maxf(master_volume * lerpf(0.48, 0.14, _quality), 0.0001))



func save_preferences() -> bool:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	return config.save(settings_path) == OK


func load_preferences() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		set_master_volume(DEFAULT_VOLUME)
		return
	var saved: Variant = config.get_value("audio", "master_volume", DEFAULT_VOLUME)
	if (saved is float or saved is int) and is_finite(float(saved)):
		set_master_volume(float(saved))
	else:
		set_master_volume(DEFAULT_VOLUME)


func play_sfx(sound_name: String) -> void:
	if _sfx == null or is_zero_approx(master_volume) or not _effects.has(sound_name) or sound_name == "ambient_hum":
		return
	if sound_name == "ui_click":
		_click.play()
	else:
		_sfx.stream = _effects[sound_name]
		_sfx.play()


## Deterministic, mono 16-bit PCM: short clicks, lock chimes, a failed lock
## buzz, and a periodic four-second receiver hum. All samples are original.
func make_sound(sound_name: String) -> AudioStreamWAV:
	if not DURATIONS.has(sound_name):
		return null
	var duration := float(DURATIONS[sound_name])
	var count := int(duration * SAMPLE_RATE)
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var envelope := minf(1.0, t / 0.008) * minf(1.0, (duration - t) / 0.045)
		var sample := 0.0
		match sound_name:
			"ui_click":
				sample = 0.3 * sin(TAU * 840.0 * t) * exp(-t * 55.0) * envelope
			"decode_success":
				var frequency := 440.0 if t < 0.16 else (660.0 if t < 0.32 else 880.0)
				# Fade each note's boundaries to avoid clicks.
				var local := fmod(t, 0.16) if t < 0.32 else t - 0.32
				var note_length := 0.16 if t < 0.32 else duration - 0.32
				var note_envelope := minf(1.0, local / 0.012) * minf(1.0, (note_length - local) / 0.035)
				sample = 0.23 * (sin(TAU * frequency * local) + 0.22 * sin(TAU * frequency * 2.0 * local)) * note_envelope
			"decode_fail":
				sample = 0.21 * (sin(TAU * 110.0 * t) + 0.35 * sin(TAU * 173.0 * t)) * envelope
			"ambient_hum":
				# Integer cycles per loop keep the boundary continuous.
				sample = 0.15 * sin(TAU * 55.0 * t) + 0.04 * sin(TAU * 110.0 * t)
				sample += 0.055 * sin(TAU * 193.25 * t + sin(TAU * 0.5 * t)) * sin(TAU * 0.25 * t)
				sample += 0.035 * sin(TAU * 1319.25 * t) * sin(TAU * 173.75 * t) * sin(TAU * 0.5 * t)
		pcm.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = pcm
	if sound_name == "ambient_hum":
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = count
	return stream
