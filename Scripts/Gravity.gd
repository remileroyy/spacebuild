extends Area3D

func _ready():
	gravity = 1.0
	gravity_point = true
	gravity_point_center = Vector3.ZERO
	gravity_space_override = SPACE_OVERRIDE_COMBINE
	linear_damp = 1.0
	angular_damp = 1.0
