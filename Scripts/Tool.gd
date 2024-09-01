extends Generic6DOFJoint3D


func _process(_delta):
	if $BodyRaycast.get_collider():
		%Crosshair.dotColor = Color.GREEN
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
	elif node:
		node_a = get_parent().get_path()
		node_b = node.get_path()
