extends Area3D
class_name Snap

var other_snap: Snap
var snapping: bool = false

func _physics_process(_delta):
	if snapping:
		for other in get_overlapping_areas():
			snap_to(other)

func disconnect_from(both: bool):
	if other_snap:
		if both:
			other_snap.disconnect_from(false)
		$Joint.node_a = ""
		$Joint.node_b = ""
		$Sprite3D.modulate = Color.RED 
		other_snap = null
		# snapping = true

func connect_to(other: Snap, both: bool):
	if not other_snap:
		get_tree().get_first_node_in_group("Player").disconnect_from(get_parent().get_path())
		if both:
			other.connect_to(self, false)
		$Sprite3D.modulate = Color.GREEN 
		other_snap = other
		snapping = false

func snap_to(other: Snap):
	get_parent().global_basis = other.global_basis * basis * Basis.FLIP_Y * Basis.FLIP_X
	get_parent().global_position = other.global_position - get_parent().global_basis * position
	$Joint.node_a = get_parent().get_path()
	$Joint.node_b = other.get_parent().get_path()
	connect_to(other, true)
