class_name WaveformDisplay
extends Control
## WaveformDisplay.gd
##
## Draws a live waveform that reacts to freq/amp values.

const POINT_COUNT := 128
const BASE_AMPLITUDE := 0.4
const BASE_CYCLES := 8.0

@onready var _line: Line2D = $Line

var _freq: float = 50.0
var _amp: float = 50.0


func _ready() -> void:
	_line.width = 2.0
	_line.default_color = Color(0.25, 0.82, 0.79)
	_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_rebuild()


func set_values(freq: float, amp: float) -> void:
	_freq = freq
	_amp = amp
	_rebuild()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_rebuild()


func _rebuild() -> void:
	if _line == null:
		return

	var w: float = size.x
	var h: float = size.y
	if w <= 0.0 or h <= 0.0:
		return

	var half_h: float = h * 0.5
	var mid_y: float = h * 0.5

	var cycles: float = BASE_CYCLES * (_freq / 100.0)
	var peak: float = BASE_AMPLITUDE * (_amp / 100.0) * half_h

	var points := PackedVector2Array()
	points.resize(POINT_COUNT)
	for i in POINT_COUNT:
		var t: float = float(i) / float(POINT_COUNT - 1)
		var x: float = t * w
		var y: float = mid_y - sin(t * TAU * cycles) * peak
		points[i] = Vector2(x, y)
	_line.points = points
