extends Generic6DOFJoint3D

@export var dig_radius : float = 2.0

func _process(_delta):
	var collider = $BodyRaycast.get_collider()
	if collider:
		%Crosshair.dotColor = Color.GREEN
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and collider is Asteroid:
			collider.dig($BodyRaycast.get_collision_point(), dig_radius)
	else:
		%Crosshair.dotColor = Color.WHITE


func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == 1:
			toggle_grab($BodyRaycast.get_collider())
		elif event.button_index == 2:
			if $AreaRaycast.get_collider():
				if $AreaRaycast.get_collider() is Snap and $AreaRaycast.get_collider().connected_to:
					$AreaRaycast.get_collider().detach()
	
	
func toggle_grab(node):
	if node_b:
		var children = get_node(node_b).get_children()
		node_a = ""
		node_b = ""
		for child in children:
			if child is Snap and not child.connected_to :
				child.attach()
	elif node and node is RigidBody3D:
		node_a = $"..".get_path()
		node_b = node.get_path()
