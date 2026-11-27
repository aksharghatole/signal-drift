class_name WaveformDisplay
extends Control
## Oscilloscope grid, persistent phosphor glow and interference feedback.
const POINT_COUNT := 160
var _freq := 50.0
var _amp := 50.0
var _quality := 0.0
var _display_quality := 0.0
var _phase := 0.0


func set_values(freq: float, amp: float, quality: float = 0.0) -> void:
	_freq = freq
	_amp = amp
	_quality = clampf(quality, 0.0, 1.0)


func _process(delta: float) -> void:
	_phase = fmod(_phase + delta * 2.0, TAU)
	_display_quality = lerpf(_display_quality, _quality, 1.0 - exp(-delta * 9.0))
	queue_redraw()


func _draw() -> void:
	if size.x < 32.0 or size.y < 32.0:
		return
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, Color("#081618"))
	draw_rect(area.grow(-1.0), Color("#35504d"), false, 2.0)
	var inset := Vector2(14.0, 14.0)
	var span := size - inset * 2.0
	for i in range(1, 10):
		var x := inset.x + span.x * float(i) / 10.0
		draw_line(Vector2(x, inset.y), Vector2(x, size.y - inset.y), Color("#193a38"), 1.0)
	for i in range(1, 6):
		var y := inset.y + span.y * float(i) / 6.0
		draw_line(Vector2(inset.x, y), Vector2(size.x - inset.x, y), Color("#193a38"), 1.0)
	var points := PackedVector2Array()
	for i in range(POINT_COUNT):
		var t := float(i) / float(POINT_COUNT - 1)
		var signal_value := sin(t * TAU * (2.0 + 7.0 * _freq / 100.0) - _phase) * (0.13 + 0.28 * _amp / 100.0)
		var interference := (sin(t * 113.0 + _phase * 5.0) + sin(t * 251.0 - _phase * 7.0)) * 0.09 * (1.0 - _display_quality)
		var y := size.y * 0.5 - (signal_value + interference) * span.y
		points.append(Vector2(inset.x + t * span.x, clampf(y, inset.y, size.y - inset.y)))
	var ink := Color("#b88d57").lerp(Color("#8ce8c5"), _display_quality)
	draw_polyline(points, Color(ink, 0.12), 9.0, true)
	draw_polyline(points, Color(ink, 0.30), 4.0, true)
	draw_polyline(points, ink, 1.8, true)
