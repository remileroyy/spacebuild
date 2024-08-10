extends Area3D
class_name Snap

var connected_to: Snap
var self_and_siblings: Array[Node]

func _ready():
	self_and_siblings = get_parent().get_children().duplicate()
	
func get_all_connected(connected: Array = Array()):
	connected.append_array(self_and_siblings)
	for sibling in self_and_siblings:
		if sibling is Snap and sibling.connected_to:
			if not sibling.connected_to in connected:
				sibling.connected_to.get_all_connected(connected)
	return connected
	
func _physics_process(_delta):
	if connected_to:
		$Sprite3D.modulate = Color.GREEN
	else:
		if has_overlapping_areas():
			$Sprite3D.modulate = Color.YELLOW
		else:
			$Sprite3D.modulate = Color.RED
	
func attach():
	for other in get_overlapping_areas():
		if other.get_parent() != get_parent():
			snap_to(other)
			merge_with(other)
			break
	
func detach():
	connected_to.connected_to = null
	connected_to = null
	var rb = RigidBody3D.new()
	rb.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	get_tree().root.get_child(0).add_child(rb)
	for child in get_all_connected():
		child.reparent(rb)
	update_mass_com(rb)

func merge_with(other: Snap):
	get_parent().queue_free()
	for child in get_parent().get_children():
		child.reparent(other.get_parent())
	update_mass_com(other.get_parent())
	connected_to = other
	connected_to.connected_to = self
	
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
	get_parent().global_basis = other.global_basis * Basis.FLIP_Y * basis.inverse()
	get_parent().global_position = other.global_position - get_parent().global_basis * position
