extends Node3D
class_name Thrust

@export var force = 1.0

func apply_thrust(linear, angular):
	visible = false
	var linear_dot = basis.y.dot(linear)
	var angular_dot = (position - get_parent().center_of_mass).cross(basis.y).dot(angular)
	if linear_dot > 1e-2:
		visible = true
		get_parent().apply_force(get_parent().basis * (basis.y * linear_dot * force), get_parent().basis * (get_parent().center_of_mass + position))
	elif angular_dot > 1e-2:
		visible = true
		get_parent().apply_force(get_parent().basis * (basis.y * angular_dot * force), get_parent().basis * (get_parent().center_of_mass + position))
