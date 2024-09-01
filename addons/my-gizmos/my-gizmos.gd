@tool
extends EditorPlugin

var gizmo_plugin = preload("res://addons/my-gizmos/local-gizmo.gd").new()

func _enter_tree():
	add_node_3d_gizmo_plugin(gizmo_plugin)

func _exit_tree():
	remove_node_3d_gizmo_plugin(gizmo_plugin)
