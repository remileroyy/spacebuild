extends Camera3D
class_name Player

@export var THRUST = 1.0
@export var TORQUE = 1.0
@export_range(0.0, 1.0) var INNER_DEADZONE = 0.2
@export_range(0.0, 1.0) var OUTER_DEADZONE = 0.8

var marker = preload("res://Scenes/marker.tscn")

func _ready():
	get_parent().linear_damp = 1.0
	get_parent().angular_damp = 1.0
	Snap.update_mass_and_com(get_parent())
	
	
func _process(_delta):
	$"../../GUI/Crosshair/Text".text = "[center]%.2f[/center]" % get_parent().linear_velocity.length()
	if $BodyRaycast.get_collider():
		$"../../GUI/Crosshair".dotColor = Color.GREEN
	else:
		$"../../GUI/Crosshair".dotColor = Color.WHITE
		
		
func _physics_process(_delta):
	var linear = get_linear_input()
	var angular = get_angular_input()
	get_parent().linear_damp = 0.0 if linear.length() > 1e-1 else 1.0
	for thrust in get_parent().get_children():
		if thrust is Thrust:
			thrust.apply_thrust(linear, angular)
	
	
func get_linear_input():
	var linear = Vector3() 
	linear.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	linear.y = Input.get_action_strength("Up") - Input.get_action_strength("Down")
	linear.z = Input.get_action_strength("Back") - Input.get_action_strength("Forward")
	return linear
	
	
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
	return angular
	
	
func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == 1:
			toggle_grab($BodyRaycast.get_collider())
		elif event.button_index == 2:
			if $AreaRaycast.get_collider():
				if $AreaRaycast.get_collider() is Snap and $AreaRaycast.get_collider().connected_to:
					$AreaRaycast.get_collider().detach()
		elif event.button_index == 3:
			toggle_marker($BodyRaycast.get_collider())
	
	
func toggle_grab(node):
	if $Joint.node_b:
		var children = get_node($Joint.node_b).get_children()
		$Joint.node_a = ""
		$Joint.node_b = ""
		for child in children:
			if child is Snap and not child.connected_to :
				child.attach()
	elif node:
		$Joint.node_a = get_parent().get_path()
		$Joint.node_b = node.get_path()
	
	
func toggle_marker(node):
	if node:
		var any = false
		for child in node.get_children():
			if child is Marker:
				any = true
				child.queue_free()
		if not any:
			var instance = marker.instantiate()
			node.add_child(instance)
