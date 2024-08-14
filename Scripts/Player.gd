extends Camera3D

@export var THRUST = 1.0
@export var TORQUE = 1.0
@export_range(0.0, 1.0) var INNER_DEADZONE = 0.2
@export_range(0.0, 1.0) var OUTER_DEADZONE = 0.8

@export var text : RichTextLabel

var rb : RigidBody3D
var matching_velocity_with : RigidBody3D
var marker = preload("res://Scenes/marker.tscn")

func _ready():
	rb = self.get_parent() as RigidBody3D
	
	
func _process(_delta):
	text.text = "[center]%.2f[/center]" % rb.linear_velocity.length()
	if $BodyRaycast.get_collider():
		$"../../GUI/Joystick".dotColor = Color.GREEN
	else:
		$"../../GUI/Joystick".dotColor = Color.WHITE
	
	
func _physics_process(_delta):
	if input_translate():
		rb.linear_damp = 0.0
	else:
		rb.linear_damp = 1.0
	if Input.is_action_pressed("Space"):
		rb.linear_damp = 5.0
		rb.angular_damp = 5.0
	else:
		rb.angular_damp = 1.0
	input_rotate()
	
	
func input_rotate():
	var mouse = get_viewport().get_mouse_position()
	var center = get_viewport().size * 0.5
	mouse = (mouse - center) / center.y
	if mouse.length() > OUTER_DEADZONE:
		mouse = mouse.normalized() * OUTER_DEADZONE
	mouse = mouse.move_toward(Vector2.ZERO, INNER_DEADZONE)
	mouse = mouse / (OUTER_DEADZONE - INNER_DEADZONE)
	var input = Vector3()
	input.x = -mouse.y
	input.y = -mouse.x
	input.z = Input.get_action_strength("Roll-") - Input.get_action_strength("Roll+")
	rb.apply_torque(global_basis * input * TORQUE)
	
	
func input_translate():
	var input = Vector3() 
	input.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	input.y = Input.get_action_strength("Up") - Input.get_action_strength("Down")
	input.z = Input.get_action_strength("Back") - Input.get_action_strength("Forward")
	rb.apply_central_force(global_basis * input * THRUST)
	return input != Vector3.ZERO
	
	
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
		$Joint.node_a = rb.get_path()
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
