extends TextureRect
class_name Marker

var camera: Camera3D
var max_reticle_position: Vector2

static var hue = 0.0

func _ready():
	camera = get_viewport().get_camera_3d()
	max_reticle_position = 0.5 * get_viewport().size - 0.5 * size
	pivot_offset = 0.5 * size
	modulate = Color.from_hsv(hue, 1.0, 1.0)
	hue += 0.18
	
	
func _process(_delta):
	if camera.is_position_in_frustum($"..".to_global($"..".center_of_mass)):
		rotation = 0
		global_position = camera.unproject_position($"..".to_global($"..".center_of_mass)) - 0.5 * size
	else:
		var local_to_camera = camera.to_local($"..".to_global($"..".center_of_mass))
		var reticle_position = Vector2(local_to_camera.x, -local_to_camera.y)
		if reticle_position.abs().aspect() > max_reticle_position.aspect():
			reticle_position *= max_reticle_position.x / abs(reticle_position.x)
		else:
			reticle_position *= max_reticle_position.y / abs(reticle_position.y)
		global_position = max_reticle_position + reticle_position
		rotation = Vector2.UP.angle_to(reticle_position)
