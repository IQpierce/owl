extends Node2D
class_name OwlGame

static var scene:OwlScene

func _ready():
	var scene_parent = get_tree().get_root()
	for child in scene_parent.get_children():
		if child is OwlScene:
			scene = child
