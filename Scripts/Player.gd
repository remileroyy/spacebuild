extends RigidBody3D

@export_range(0.0, 10.0) var THRUST = 3.0
@export_range(0.0, 10.0) var TORQUE = 1.0
@export_range(0.0, 1.0) var INNER_DEADZONE = 0.2
@export_range(0.0, 1.0) var OUTER_DEADZONE = 0.8

@export var text : RichTextLabel

var looking_at : Dictionary

func _ready():
	angular_damp = TORQUE

func _process(_delta):
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(position, position + transform.basis * Vector3.FORWARD)
	looking_at = space_state.intersect_ray(query)
	text.text = "%.2f" % linear_velocity.length() #looking_at.collider.name if looking_at else ""

func _physics_process(_delta):
	if Input.is_action_just_pressed("Space"):
		linear_damp = THRUST
	elif Input.is_action_just_released("Space"):
		linear_damp = 0.0
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
