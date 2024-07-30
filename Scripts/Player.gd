extends RigidBody3D

func _physics_process(_delta):
	input_rotate()
	input_translate()


func input_rotate():
	var length = get_viewport().size.y * 0.4
	var mouse = $"../CanvasLayer/Crosshair/Line".clamped_mouse() / length
	mouse = mouse.move_toward(Vector2.ZERO, 0.2) / 0.8
	var pitch_input = mouse.y
	var yaw_input = mouse.x
	var roll_input = Input.get_action_strength("Roll+") - Input.get_action_strength("Roll-")
	apply_torque(basis * pitch_input * Vector3.LEFT)
	apply_torque(basis * yaw_input * Vector3.DOWN)
	apply_torque(basis * roll_input * Vector3.FORWARD)

func input_translate():
	var input = Vector3() 
	input.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	input.y = Input.get_action_strength("Up") - Input.get_action_strength("Down")
	input.z = Input.get_action_strength("Back") - Input.get_action_strength("Forward")
	apply_central_force(basis * input)
