extends Camera3D

@export var THRUST = 1.0
@export var TORQUE = 1.0
@export_range(0.0, 1.0) var INNER_DEADZONE = 0.2
@export_range(0.0, 1.0) var OUTER_DEADZONE = 0.8

@export var text : RichTextLabel

var rb : RigidBody3D
var matching_velocity_with : RigidBody3D

func _ready():
	rb = self.get_parent() as RigidBody3D
	rb.angular_damp = 1.0

func _process(_delta):
	text.text = "%.2f\n" % rb.linear_velocity.length()
	if $RayCast3D.get_collider():
		text.text += $RayCast3D.get_collider().name

func _physics_process(_delta):
	if input_translate():
		rb.linear_damp = 0.0
	else:
		rb.linear_damp = 1.0
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
			if $Joint.node_b:
				for child in get_node($Joint.node_b).get_children():
					if child is Snap and not child.bound:
						child.try_snapping()
				$Joint.node_a = ""
				$Joint.node_b = ""
			elif $RayCast3D.get_collider():
				$Joint.node_a = rb.get_path()
				$Joint.node_b = $RayCast3D.get_collider().get_path()
