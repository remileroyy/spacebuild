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
	
	
func _process(_delta):
	$"../../GUI/Joystick/Text".text = "[center]%.2f[/center]" % get_parent().linear_velocity.length()
	if $BodyRaycast.get_collider():
		$"../../GUI/Joystick".dotColor = Color.GREEN
	else:
		$"../../GUI/Joystick".dotColor = Color.WHITE
		
	
	
func _physics_process(_delta):
	var trans = get_trans_input()
	var rot = get_rot_input()
	get_parent().linear_damp = 0.0 if trans.length() > 1e-1 else 1.0
	input_move(trans, rot)
	
	
func get_trans_input():
	var trans_input = Vector3() 
	trans_input.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	trans_input.y = Input.get_action_strength("Up") - Input.get_action_strength("Down")
	trans_input.z = Input.get_action_strength("Back") - Input.get_action_strength("Forward")
	return trans_input
	
	
func get_rot_input():
	var mouse = get_viewport().get_mouse_position()
	var center = get_viewport().size * 0.5
	mouse = (mouse - center) / center.y
	if mouse.length() > OUTER_DEADZONE:
		mouse = mouse.normalized() * OUTER_DEADZONE
	mouse = mouse.move_toward(Vector2.ZERO, INNER_DEADZONE)
	mouse = mouse / (OUTER_DEADZONE - INNER_DEADZONE)
	var rot_input = Vector3()
	rot_input.x = -mouse.y
	rot_input.y = -mouse.x
	rot_input.z = Input.get_action_strength("Roll-") - Input.get_action_strength("Roll+")
	return rot_input
	
	
func input_move(trans, rot):
	for thrust in get_parent().get_children():
		if thrust is Thrust:
			thrust.modulate = Color.RED
			var linear = thrust.basis.y.dot(trans)
			var angular = (thrust.position - get_parent().center_of_mass).cross(thrust.basis.y).dot(rot)
			if linear > 1e-1:
				thrust.modulate = Color.GREEN
				get_parent().apply_force(get_parent().basis * (thrust.basis.y * linear * thrust.force), get_parent().center_of_mass + get_parent().basis * thrust.position)
			elif angular > 1e-1:
				thrust.modulate = Color.GREEN
				get_parent().apply_force(get_parent().basis * (thrust.basis.y * angular * thrust.force), get_parent().center_of_mass + get_parent().basis * thrust.position)
	
	
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
