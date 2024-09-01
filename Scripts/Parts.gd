extends Node3D
class_name Parts

const scene: PackedScene = preload("res://scenes/parts.tscn")
var parts: Array[Node]

func _ready():
	parts = scene.instantiate().get_child(0).get_children()
	
	
func _input(event):
	if event is InputEventKey and event.is_pressed():
		if 48 < event.physical_keycode and event.physical_keycode < 59:
			var instance = parts[(event.physical_keycode - 49) % len(parts)].duplicate() as RigidBody3D
			instance.visible = true
			instance.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
			add_child(instance)
