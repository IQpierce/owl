extends VectorPolygonRendering
class_name WallBody

var collider:PolygonCorrespondence = null

# NOTE (sam) I don't love that we have to do this on every enter_tree,
# but that is our only option that runs before child _ready and has access to tree (unlike _init)
# ... I also don't love that we need to do that at all, but Godot doesn't deep copy on duplicate
func _enter_tree():
	var child_count = get_child_count()
	for i in child_count:
		if collider != null:
			break
		var child = get_child(i)
		if child is StaticBody2D:
			var child_child_count = child.get_child_count()
			for j in child_child_count:
				var child_child = child.get_child(j)
				if child_child is PolygonCorrespondence:
					collider = child_child
	if collider != null:
		collider.counterpart = self
