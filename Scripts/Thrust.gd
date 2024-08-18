extends MeshInstance3D
class_name Thrust

@export var magnitude = 1.0
const EPS = 0.01

var material = preload("res://Assets/Shaders/engine_material.tres")

func _ready():
	material = material.duplicate()
	set_surface_override_material(0, material)
	
	
func apply_thrust(linear_input, angular_input):
	var force = magnitude * global_basis.y
	var lever_arm = global_position - get_parent().global_position - get_parent().center_of_mass
	var torque = lever_arm.cross(force)
	
	print(name," ", torque)
	print(get_parent().basis * angular_input)
	
	var dot_linear = force.normalized().dot(get_parent().basis * linear_input)
	var dot_angular = torque.normalized().dot(get_parent().basis * angular_input)
	
	if dot_linear + dot_angular > EPS:
		material.set_shader_parameter("fade", 1.0 /  min(dot_linear + dot_angular, 1.0))
		get_parent().apply_force(force * min(dot_linear + dot_angular, 1.0), global_position - get_parent().global_position)
	else:
		material.set_shader_parameter("fade", 100.0)
	
func apply_thrust_old(linear, angular):
	material.set_shader_parameter("fade", 100.0)
	var linear_dot = basis.y.dot(linear)
	var angular_dot = (position - get_parent().center_of_mass).cross(basis.y).dot(angular)
	if linear_dot > EPS:
		var vector = basis.y * magnitude * abs(linear)
		print(vector)
		material.set_shader_parameter("fade", 1.0/vector.length())
		get_parent().apply_force(get_parent().basis * vector, get_parent().basis * (get_parent().center_of_mass + position))
	#elif angular_dot > EPS:
		#var vector = basis.y * force
		#print(vector)
		#material.set_shader_parameter("fade", 1.0/vector.length())
		#get_parent().apply_force(get_parent().basis * vector, get_parent().basis * (get_parent().center_of_mass + position))
