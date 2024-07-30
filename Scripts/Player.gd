extends RigidBody3D

const THRUST = 3.0

@export var line : Control

func _physics_process(_delta):
	if Input.is_action_just_pressed("Space"):
		linear_damp = THRUST
	elif Input.is_action_just_released("Space"):
		linear_damp = 0.0
	input_rotate()
	input_translate()

func input_rotate():
	var length = get_viewport().size.y * 0.4
	var mouse = line.clamped_mouse() / length
	mouse = mouse.move_toward(Vector2.ZERO, 0.2) / 0.8
	var input = Vector3()
	input.x = -mouse.y
	input.y = -mouse.x
	input.z = Input.get_action_strength("Roll-") - Input.get_action_strength("Roll+")
	apply_torque(basis * input)

func input_translate():
	var input = Vector3() 
	input.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	input.y = Input.get_action_strength("Up") - Input.get_action_strength("Down")
	input.z = Input.get_action_strength("Back") - Input.get_action_strength("Forward")
	apply_central_force(basis * input * THRUST)
