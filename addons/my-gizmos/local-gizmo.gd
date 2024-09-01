extends EditorNode3DGizmoPlugin

func _init():
	create_material("r", Color(1, 0, 0))
	create_material("g", Color(0, 1, 0))
	create_material("b", Color(0, 0, 1))
	create_material("o", Color(1, 0.5, 0))

func _has_gizmo(node):
	return node is Snap
	
func _redraw(gizmo):
	gizmo.clear()
	var node = gizmo.get_node_3d()
	var lines = PackedVector3Array()
	lines.push_back(Vector3(0, 0, 0))
	lines.push_back(Vector3(1, 0, 0))
	gizmo.add_lines(lines, get_material("r", gizmo), false)
	lines = PackedVector3Array()
	lines.push_back(Vector3(0, 0, 0))
	lines.push_back(Vector3(0, 1, 0))
	gizmo.add_lines(lines, get_material("g", gizmo), false)
	lines = PackedVector3Array()
	lines.push_back(Vector3(0, 0, 0))
	lines.push_back(Vector3(0, 0, 1))
	gizmo.add_lines(lines, get_material("b", gizmo), false)

func _get_gizmo_name():
	return "Custom Gizmo"

func _get_priority():
	return 1
