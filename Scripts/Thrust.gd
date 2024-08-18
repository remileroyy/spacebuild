extends MeshInstance3D
class_name Thrust

@export var magnitude = 1.0
const EPS = 1e-3

var material = preload("res://Assets/Shaders/engine_material.tres")

func _ready():
	material = material.duplicate()
	set_surface_override_material(0, material)
	
	
func apply_thrust(linear_input, angular_input):
	var force = magnitude * global_basis.y
	var lever_arm = global_position - get_parent().global_position - get_parent().center_of_mass
	var torque = lever_arm.cross(force)
	
	var dot_linear = force.normalized().dot(linear_input)
	var dot_angular = torque.normalized().dot(angular_input)
	
	if dot_linear + dot_angular > EPS:
		material.set_shader_parameter("fade", 1.0 /  min(dot_linear + dot_angular, 1.0))
		get_parent().apply_force(force * min(dot_linear + dot_angular, 1.0), global_position - get_parent().global_position)
	else:
		material.set_shader_parameter("fade", 1.0 / EPS)
