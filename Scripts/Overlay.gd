extends Control

func _draw():
	for node in get_tree().get_nodes_in_group("Snap"):
		var pos = node.global_position
		if not get_viewport().get_camera_3d().is_position_behind(pos):
			var coord = get_viewport().get_camera_3d().unproject_position(pos)
			draw_circle(coord, 5.0, Color.RED)

func _process(_delta):
	queue_redraw()
