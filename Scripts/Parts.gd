extends Node3D
class_name Parts

static var parts = {}

func _ready():
	load_parts("res://Scenes/Parts/")
	
	
func _input(event):
	if event is InputEventKey and event.is_pressed():
		if 48 < event.physical_keycode and event.physical_keycode < 58:
			var key = parts.keys()[(event.physical_keycode - 49) % len(parts)]
			var instance = parts[key]["scene"].instantiate()
			add_child(instance)
	
	
func load_parts(path):
	var dir = DirAccess.open(path)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		parts[file_name] = {}
		parts[file_name]["scene"] = load(path + file_name)
		parts[file_name]["mass"] = 1.0
		file_name = dir.get_next()
