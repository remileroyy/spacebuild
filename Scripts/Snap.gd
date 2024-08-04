extends Area3D

func _physics_process(_delta):
	if $Joint.node_a:
		return
	for snap in get_overlapping_areas():
		if snap.get_parent().name > get_parent().name:
			#get_parent().global_rotation = snap.global_rotation - get_parent().basis * global_rotation
			get_parent().global_position = snap.global_position - get_parent().basis * position
			$Joint.node_a = get_parent().get_path()
			$Joint.node_b = snap.get_parent().get_path()
			
			
