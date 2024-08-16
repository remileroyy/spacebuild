extends RigidBody3D
class_name Construct

var thrusts: Array[Node] = []


func _ready():
	for child in get_children():
		if child is Thrust:
			thrusts.append(child)
	
	
func input_move(trans, rot):
	for thrust in thrusts:
		thrust.modulate = Color.RED
		var linear = thrust.basis.y.dot(trans)
		var angular = (thrust.position - center_of_mass).cross(thrust.basis.y).dot(rot)
		if linear > 1e-1:
			thrust.modulate = Color.GREEN
			apply_force(basis * (thrust.basis.y * linear * thrust.force), center_of_mass + basis * thrust.position)
		elif angular > 1e-1:
			thrust.modulate = Color.GREEN
			apply_force(basis * (thrust.basis.y * angular * thrust.force), center_of_mass + basis * thrust.position)
