extends Control

@export_range(0.0, 1.0) var INNER_DEADZONE = 0.2
@export_range(0.0, 1.0) var OUTER_DEADZONE = 0.8
var dotColor = Color.WHITE

func _draw():
	var mouse = get_viewport().get_mouse_position()
	var center = get_viewport().size * 0.5
	mouse = (mouse - center) / center.y
	if mouse.length() > OUTER_DEADZONE:
		mouse = mouse.normalized() * OUTER_DEADZONE
	draw_line(0.5 * size, 0.5 * size + mouse * center.y, Color.WHITE, 0.8, true)
	draw_arc(0.5 * size, INNER_DEADZONE * center.y, 0, TAU, 45, Color.WHITE, 0.8, true)
	draw_circle(0.5 * size, 4.0, dotColor)
	draw_circle(0.5 * size + mouse * center.y, 4.0, Color.WHITE)

func _process(_delta):
	queue_redraw()
