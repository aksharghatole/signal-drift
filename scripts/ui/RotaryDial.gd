extends Range
## Relative drag keeps the dial usable without obscuring the pointer on touchscreens.
## Arrow keys and wheel provide precise adjustment on desktop.
const START := deg_to_rad(135.0)
const SWEEP := deg_to_rad(270.0)
const INK := Color("#8ce8c5")
var _dragging := false
var _drag_value := 0.0


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	value_changed.connect(_on_value_changed)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _on_value_changed(_value: float) -> void:
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			if event.pressed:
				grab_focus()
				_drag_value = value
			accept_event()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			value += step if event.button_index == MOUSE_BUTTON_WHEEL_UP else -step
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_dragging = false
			return
		_drag_value = clampf(_drag_value - event.relative.y * 0.5 + event.relative.x * 0.5, min_value, max_value)
		value = _drag_value
		accept_event()
	elif event is InputEventKey and event.pressed:
		if event.keycode in [KEY_UP, KEY_RIGHT, KEY_DOWN, KEY_LEFT]:
			value += step if event.keycode in [KEY_UP, KEY_RIGHT] else -step
			accept_event()
		elif event.keycode == KEY_HOME or event.keycode == KEY_END:
			value = min_value if event.keycode == KEY_HOME else max_value
			accept_event()


func _draw() -> void:
	var center := size * 0.5
	var radius := maxf(10.0, minf(size.x, size.y) * 0.39)
	var fraction := ratio
	draw_circle(center + Vector2(0, 5), radius, Color("#060b0e"))
	draw_circle(center, radius, Color("#25343a"))
	draw_circle(center, radius * 0.86, Color("#17252b"))
	draw_arc(center, radius * 1.08, START, START + SWEEP, 64, Color("#405359"), 3.0, true)
	if fraction > 0.0:
		draw_arc(center, radius * 1.08, START, START + SWEEP * fraction, 64, INK, 3.0, true)
	for i in range(21):
		var direction := Vector2.from_angle(START + SWEEP * float(i) / 20.0)
		var inner := 1.16 if i % 5 == 0 else 1.20
		draw_line(center + direction * radius * inner, center + direction * radius * 1.25, Color("#9aaeb0"), 2.0 if i % 5 == 0 else 1.0, true)
	var pointer := Vector2.from_angle(START + SWEEP * fraction)
	draw_line(center + pointer * radius * 0.45, center + pointer * radius * 0.77, INK, 5.0, true)
	draw_circle(center, radius * 0.15, Color("#405359"))
	if has_focus():
		draw_arc(center, radius * 1.28, 0.0, TAU, 64, Color("#f0bf77"), 2.0, true)
