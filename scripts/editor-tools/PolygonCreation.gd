@tool
extends EditorScript

# @TODO: Figure out a good way (popup input??) to make these not be magic numbers!	
var num_poly_sides = 80
var poly_radius = 500

func _run():
	var selection:EditorSelection = get_editor_interface().get_selection()
	if selection && selection.get_selected_nodes().size() > 0:
		for selected_node:Node2D in selection.get_selected_nodes():
			var created_polygon:PackedVector2Array = create_polygon()
			
			var collision_polygon:CollisionPolygon2D = selected_node as CollisionPolygon2D
			if collision_polygon:
				print("Creating new polygon data for ", collision_polygon)
				collision_polygon.polygon = created_polygon
			else:
				var polygon:Polygon2D = selected_node as Polygon2D
				if polygon:
					print("Creating new polygon data for ", polygon)
					polygon.polygon = created_polygon
					

func create_polygon() -> PackedVector2Array:
	var ret:Array
	
	for i in num_poly_sides:
		var theta:float = (float(i)/float(num_poly_sides)) * (2*PI)
		var point:Vector2 = Vector2(
			cos(theta) * poly_radius,
			sin(theta) * poly_radius
		)
		ret.append(point)
	
	ret.append(ret[0])
	
	return PackedVector2Array(ret)

