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
	draw_line(Vector2.ZERO, mouse * center.y, Color.WHITE, 0.8, true)
	draw_arc(Vector2.ZERO, INNER_DEADZONE * center.y, 0, TAU, 45, Color.WHITE, 0.8, true)
	draw_circle(Vector2.ZERO, 4.0, dotColor)
	draw_circle(mouse * center.y, 4.0, Color.WHITE)

func _process(_delta):
	queue_redraw()
