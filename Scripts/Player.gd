extends RigidBody3D

@export_range(0.0, 10.0) var THRUST = 3.0
@export_range(0.0, 10.0) var TORQUE = 1.0
@export_range(0.0, 1.0) var INNER_DEADZONE = 0.2
@export_range(0.0, 1.0) var OUTER_DEADZONE = 0.8

@export var text : RichTextLabel

var looking_at : Dictionary
var matching_velocity_with : RigidBody3D

func _ready():
	angular_damp = 2 * TORQUE
	linear_damp = 0.0

func _process(_delta):
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(position, position + transform.basis * Vector3.FORWARD)
	looking_at = space_state.intersect_ray(query)
	text.text = "%.2f" % linear_velocity.length()

func find_closest_rb():
	var closest : RigidBody3D
	var d_min = 10000.0
	for node in get_tree().get_nodes_in_group("Matching"):
		var rb = node as RigidBody3D
		var d = rb.position.distance_squared_to(position)
		if rb.get_path() != $Joint.node_b and d < d_min:
			closest = rb
			d_min = d
	return closest

func _physics_process(_delta):
	if Input.is_action_just_pressed("Space"):
		matching_velocity_with = find_closest_rb()
	if Input.is_action_pressed("Space"):
		var match_force = matching_velocity_with.linear_velocity if matching_velocity_with else Vector3.ZERO
		match_force = Vector3.ZERO.move_toward(match_force - linear_velocity, THRUST)
		apply_central_force(match_force)
	input_rotate()
	input_translate()

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
	apply_torque(basis * input * TORQUE)
	
func input_translate():
	var input = Vector3() 
	input.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	input.y = Input.get_action_strength("Up") - Input.get_action_strength("Down")
	input.z = Input.get_action_strength("Back") - Input.get_action_strength("Forward")
	apply_central_force(basis * input * THRUST)
	
func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if $Joint.node_a:
			$Joint.node_a = ""
			$Joint.node_b = ""
		elif looking_at:
			$Joint.node_a = self.get_path()
			$Joint.node_b = looking_at.collider.get_path()
