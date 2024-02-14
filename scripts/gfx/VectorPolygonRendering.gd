extends Polygon2D
class_name VectorPolygonRendering

@export var point_draw_radius:float = .09
@export var circle_draw_color:Color = Color(0.86274510622025, 0.86274510622025, 0.86274510622025)
@export var line_draw_color:Color = Color(0.70588237047195, 0.70588237047195, 0.70588237047195)
@export var draw_line_width:float = .1
@export var draw_line_antialiased:bool = true
@export var skip_line_indeces:Array[int]	# Each line that begins with a vert index that's in this list, will be skipped

var initial_point_radius:float = 1
var initial_line_width:float = 1
var warp_points:PackedVector2Array

func _ready():
	initial_point_radius = point_draw_radius
	initial_line_width = draw_line_width

func _draw():
	var points = polygon
	var stride = 1
	if warp_points.size() > 0:
		points = warp_points
		stride = 2

	var vertex_count = points.size()
	
	for i in range(0, vertex_count, stride):
		# TODO (sam) Warp Points does not properly support this
		if skip_line_indeces.has(i):
			continue
		
		var x = points[i].x
		var y = points[i].y
		
		var nextPoint = [0, 0]
		
		if i < vertex_count - 1:
			nextPoint = points[i + 1]
		else:
			nextPoint = points[0]
		
		draw_line(points[i], nextPoint, line_draw_color, draw_line_width, draw_line_antialiased)
	
	#if vertex_count % stride != 0:
	#	draw_line(points[points.size() - 1], points[0], line_draw_color, draw_line_width, draw_line_antialiased)

	
	# @TODO - it would be nice to not have to repeat this entire loop verbatim!! dupe code!!!	
	# ... actually not quite dupe code anymore if we support dashed lines
	var polygon_vertex_count = polygon.size()
	for i in range(polygon_vertex_count):
		var x = polygon[i].x
		var y = polygon[i].y
		
		var nextPoint = [0, 0]
		
		if i < polygon_vertex_count - 1:
			nextPoint = polygon[i + 1]
		else:
			nextPoint = polygon[0]
		
		draw_circle(Vector2(x, y), point_draw_radius, circle_draw_color)

func initiate_warp(points_structure:PackedVector2Array):
	if polygon.size() == 0 || points_structure.size() < polygon.size() * 2:
		return

	warp_points = points_structure
	var polygon_period = warp_points.size() / (polygon.size() + 1)

	# Default all points, because we probably skip the last few when building proper positions
	for i in warp_points.size():
		warp_points[i] = polygon[0]
	
	warp_points[0] = polygon[0]
	for i in range(1, polygon.size()):
		warp_points[i * 2 - 1] = polygon[i]
		warp_points[i * 2] = polygon[i]

func resolve_warp():
	# TODO (sam) Are we slowly gonna accumulate a bunch of garbage from all the things that have been warped?
	warp_points.clear()
	queue_redraw()

func prepare_warp(warp_progress:float, cycle_progress:float, delta:float):
	var polygon_period = warp_points.size() / (polygon.size() + 1)
	var index_offset = 0
	var prev_polygon_index = 0
	var next_polygon_index = 0
	
	#TODO (sam) FIGURE OUT PROPER INDEXING

	#TODO (sam) This is a HACK to reduce render mishaps
	warp_progress = min(warp_progress, 0.89)

	var affected_points = (polygon.size() * polygon_period * warp_progress) as int
	if affected_points % 2 != 0:
		affected_points += 1

	for i in affected_points:
		if i % polygon_period == 0:
			if i < warp_points.size():
				warp_points[i] = polygon[next_polygon_index]
			prev_polygon_index = next_polygon_index
			next_polygon_index += 1
			if next_polygon_index >= polygon.size():
				next_polygon_index = 0
				index_offset = 0#i + polygon_period
		else:
			var portion = (i - index_offset - (prev_polygon_index * polygon_period)) / (polygon_period * 1.0)
			if i < warp_points.size():
				warp_points[i] = ((1 - portion) * polygon[prev_polygon_index]) + (portion * polygon[next_polygon_index])

	# Default all points, because we probably skip the last few when building proper positions
	#for i in range(affected_points, warp_points.size()):
	#	warp_points[i] = polygon[next_polygon_index]

	if affected_points < warp_points.size():
		warp_points[affected_points] = polygon[next_polygon_index]
	for i in range(next_polygon_index - 1, polygon.size()):
		var warp_index = (affected_points) + ((i - (next_polygon_index -1)) * 2)
		if warp_index < warp_points.size():
			warp_points[warp_index - 1] = polygon[i]
			warp_points[warp_index] = polygon[i]

	queue_redraw()
		
