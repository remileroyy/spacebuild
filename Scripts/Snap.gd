extends Area3D
class_name Snap

var bound: Snap

func _physics_process(_delta):
	if bound:
		$Sprite3D.modulate = Color.GREEN
	else:
		if has_overlapping_areas():
			$Sprite3D.modulate = Color.YELLOW
		else:
			$Sprite3D.modulate = Color.RED

func try_snapping():
	for other in get_overlapping_areas():
		if other.get_parent() != get_parent():
			snap_to(other)
			merge_with(other)
			return

func merge_with(other: Snap):
	get_parent().queue_free()
	for child in get_parent().get_children():
		child.reparent(other.get_parent())
	update_mass_com(other.get_parent())
	bound = other
	other.bound = self
	
func update_mass_com(rb: RigidBody3D):
	var mass = 0.0
	var com = Vector3.ZERO
	for child in rb.get_children():
		if child is MeshInstance3D:
			mass += ModuleData.MASS[child.mesh.resource_name]
			com += ModuleData.MASS[child.mesh.resource_name] * child.position
	rb.mass = mass
	rb.center_of_mass = com / mass
	
func snap_to(other: Snap):
	get_parent().global_basis = other.global_basis * basis * Basis.FLIP_Y * Basis.FLIP_X
	get_parent().global_position = other.global_position - get_parent().global_basis * position
