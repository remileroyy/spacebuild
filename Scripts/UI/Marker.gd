extends Control
class_name Marker

var camera: Camera3D
static var hue = 0.0
var max_reticle_position

func _ready():
	camera = get_viewport().get_camera_3d()
	modulate = Color.from_hsv(hue, 1.0, 1.0)
	hue += 0.177
	max_reticle_position = 0.5 * get_viewport().size - 0.2 * $Arrow.size
	
	
func _process(_delta):
	var pos = get_parent().to_global(get_parent().center_of_mass)
	if camera.is_position_in_frustum(pos):
		global_position = camera.unproject_position(pos)
		rotation = 0
	else:
		var local = camera.to_local(pos)
		var projection = Vector2(local.x, -local.y)
		if projection.abs().aspect() > max_reticle_position.aspect():
			projection *= max_reticle_position.x / abs(projection.x)
		else:
			projection *= max_reticle_position.y / abs(projection.y)
		global_position = 0.5 * get_viewport().size + projection
		rotation = Vector2.UP.angle_to(projection)
