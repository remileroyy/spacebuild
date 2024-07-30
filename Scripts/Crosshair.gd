extends Control


func _draw():
	var mouse = clamped_mouse()
	draw_circle(mouse, 4.0, Color.WHITE)
	draw_line(Vector2.ZERO, mouse, Color.WHITE, 2.0, true)

func clamped_mouse():
	return Vector2.ZERO.move_toward(get_local_mouse_position(), get_viewport().size.y * 0.4)

func _process(_delta):
	queue_redraw()
