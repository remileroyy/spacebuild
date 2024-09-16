extends Camera3D
class_name Player

@export_range(0.0, 1.0) var INNER_DEADZONE = 0.2
@export_range(0.0, 1.0) var OUTER_DEADZONE = 0.8

var marker = preload("res://scenes/marker.tscn")

func _ready():
	$"../..".linear_damp = 0.0
	$"../..".angular_damp = 0.0
	$BodyRaycast.add_exception($"../..")
	
	
func _process(_delta):
	%Text.text = "[center]%.2f m/s\n%.2f °/s[/center]" % [$"../..".linear_velocity.length(), rad_to_deg($"../..".angular_velocity.length())]
		
		
func _physics_process(_delta):
	var linear = get_linear_input()
	var angular = get_angular_input()
	for thrust in $"../..".get_children():
		if thrust is Thrust:
			thrust.apply_thrust(linear, angular)
	
	
func get_linear_input():
	var linear = Vector3() 
	linear.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	linear.y = Input.get_action_strength("Up") - Input.get_action_strength("Down")
	linear.z = Input.get_action_strength("Back") - Input.get_action_strength("Forward")
	if linear.length() > 1e-3:
		return global_basis * linear
	elif Input.is_action_pressed("Space") and $"../..".linear_velocity.length() > 0.05:
		return -$"../..".linear_velocity.normalized()
	else:
		return Vector3.ZERO
	
func get_angular_input():
	var mouse = get_viewport().get_mouse_position()
	var center = get_viewport().size * 0.5
	mouse = (mouse - center) / center.y
	if mouse.length() > OUTER_DEADZONE:
		mouse = mouse.normalized() * OUTER_DEADZONE
	mouse = mouse.move_toward(Vector2.ZERO, INNER_DEADZONE)
	mouse = mouse / (OUTER_DEADZONE - INNER_DEADZONE)
	var angular = Vector3()
	angular.x = -mouse.y
	angular.y = -mouse.x
	angular.z = Input.get_action_strength("Roll-") - Input.get_action_strength("Roll+")
	if angular.length() > 1e-3:
		return global_basis * angular
	elif $"../..".angular_velocity.length() > 0.05:
		return -$"../..".angular_velocity.normalized()
	else:
		return Vector3.ZERO
	
	
func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == 3:
			toggle_marker($BodyRaycast.get_collider())
	
	
func toggle_marker(node):
	if node and node is RigidBody3D:
		var any = false
		for child in node.get_children():
			if child is Marker:
				any = true
				child.queue_free()
		if not any:
			var instance = marker.instantiate()
			node.add_child(instance)
