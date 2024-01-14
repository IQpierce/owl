extends Polygon2D

@export var point_draw_radius:float = .09
@export var circle_draw_color:Color = Color(0.86274510622025, 0.86274510622025, 0.86274510622025)
@export var line_draw_color:Color = Color(0.70588237047195, 0.70588237047195, 0.70588237047195)
@export var draw_line_width:float = .1
@export var draw_line_antialiased:bool = true

func _draw():
	var vertex_count = polygon.size()  
	
	for i in range(vertex_count):
		var x = polygon[i].x
		var y = polygon[i].y
		
		var nextPoint = [0, 0]
		
		if i < vertex_count - 1:
			nextPoint = polygon[i + 1]
		else:
			nextPoint = polygon[0]
		
		draw_line(polygon[i], nextPoint, line_draw_color, draw_line_width, draw_line_antialiased)
	
	# @TODO - it would be nice to not have to repeat this entire loop verbatim!! dupe code!!!	
	for i in range(vertex_count):
		var x = polygon[i].x
		var y = polygon[i].y
		
		var nextPoint = [0, 0]
		
		if i < vertex_count - 1:
			nextPoint = polygon[i + 1]
		else:
			nextPoint = polygon[0]
		
		draw_circle(Vector2(x, y), point_draw_radius, circle_draw_color)
