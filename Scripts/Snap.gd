extends Area3D

func _physics_process(_delta):
	if $Joint.node_a:
		return
	for snap in get_overlapping_areas():
		if snap.get_parent().name < get_parent().name:
			snap_to(snap)
			$Joint.node_a = get_parent().get_path()
			$Joint.node_b = snap.get_parent().get_path()

func snap_to(snap):
	var cross = global_basis.z.cross(-snap.global_basis.z)
	var angle = global_basis.z.signed_angle_to(-snap.global_basis.z, cross)
	rotate_around_pivot(get_parent(), position, cross.normalized(), angle)
	get_parent().global_position = snap.global_position - get_parent().global_basis * position

func rotate_around_pivot(node, pivot_local, rotation_axis, rotation_amount):
	var translation_to_pivot = Transform3D(Basis(), pivot_local)
	var rotate_to = Transform3D(Basis(rotation_axis, rotation_amount), Vector3())
	var translation_back = Transform3D(Basis(), -pivot_local)
	node.transform = translation_to_pivot * rotate_to * translation_back * node.transform
