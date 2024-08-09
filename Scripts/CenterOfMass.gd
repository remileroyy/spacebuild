extends Sprite3D


func _process(_delta):
	position = get_parent().center_of_mass
