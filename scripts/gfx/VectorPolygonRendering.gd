extends Polygon2D
class_name VectorPolygonRendering

enum DrawState { Intro, Stable, Outro }

@export var intro_secs:float = 0
@export var _warpable:bool = false
@export var point_draw_radius:float = .09
@export var circle_draw_color:Color = Color(0.86274510622025, 0.86274510622025, 0.86274510622025)
@export var line_draw_color:Color = Color(0.70588237047195, 0.70588237047195, 0.70588237047195)
@export var draw_line_width:float = .1
@export var draw_line_antialiased:bool = true
@export var skip_line_indeces:Array[int]	# Each line that begins with a vert index that's in this list, will be skipped

var draw_state:DrawState = DrawState.Stable
var draw_elapsed:float = 0
var initial_point_radius:float = 1
var initial_line_width:float = 1
var warp_points:PackedVector2Array

func can_warp() -> bool:
	return true#draw_state == DrawState.Stable && _warpable

func _ready():
	initial_point_radius = point_draw_radius
	initial_line_width = draw_line_width
	if intro_secs > 0:
		draw_state = DrawState.Intro
		draw_elapsed = 0
	else:
		draw_state = DrawState.Stable

func _process(delta:float):
	var redraw = false
	if draw_state == DrawState.Intro:
		redraw = true
		draw_elapsed += delta
		if draw_elapsed >= intro_secs:
			draw_state = DrawState.Stable
	elif draw_state == DrawState.Outro:
		redraw = true
		draw_elapsed -= delta

	if redraw:
		queue_redraw()

func _draw():
	var points = polygon
	var stride = 1
	if can_warp() && warp_points.size() > 0:
		points = warp_points
		stride = 2

	var draw_portion = 1
	if draw_state == DrawState.Intro || draw_state == DrawState.Outro && intro_secs > 0:
		draw_portion = draw_elapsed / intro_secs
	
	var vertex_count = points.size()
	
	for i in range(0, vertex_count, stride):
		# TODO (sam) Warp Points does not properly support this
		if skip_line_indeces.has(i):
			continue
		
		#var x = points[i].x
		#var y = points[i].y

		#if draw_portion < i / (polygon.size * 1.0):
		#	x = last_drawn.x
		#	y = last_drawn.y
		
		var next_index = 0
		if i < vertex_count - 1:
			next_index = i + 1

		var next_point = points[next_index]

		var draw_line = true
		if draw_state != DrawState.Stable:
			var check_index = i
			#if i > points.size() / 2:
			#	check_index = points.size() - i

			var index_portion = check_index / (points.size() * 1.0)
			var next_portion = (check_index + 1) / (points.size() * 1.0)
			if draw_portion <= index_portion:
				draw_line = false
			else:
				var line_portion = clamp((draw_portion - index_portion) / (next_portion - index_portion), 0, 1)
				next_point = ((1 - line_portion) * points[i]) + (line_portion * next_point)

		if draw_line:
			draw_line(points[i], next_point, line_draw_color, draw_line_width, draw_line_antialiased)
	
	#if vertex_count % stride != 0:
	#	draw_line(points[points.size() - 1], points[0], line_draw_color, draw_line_width, draw_line_antialiased)

	
	# @TODO - it would be nice to not have to repeat this entire loop verbatim!! dupe code!!!	
	# ... actually not quite dupe code anymore if we support dashed lines
	var polygon_vertex_count = polygon.size()
	for i in range(polygon_vertex_count):
		var x = polygon[i].x
		var y = polygon[i].y

		var draw_vert = true
		if draw_state != DrawState.Stable:
			var check_index = i
			#if i > polygon.size() / 2:
			#	check_index = polygon.size() - i

			if draw_portion <= check_index / (polygon.size() * 1.0):
				draw_vert = false

		if draw_vert:
			draw_circle(Vector2(x, y), point_draw_radius, circle_draw_color)

func undraw():
	if draw_elapsed > intro_secs || draw_elapsed <= 0:
		draw_elapsed = intro_secs
	draw_state = DrawState.Outro

func initiate_warp(points_structure:PackedVector2Array):
	if polygon.size() == 0 || points_structure.size() < polygon.size() * 2:
		return

	print("initiate warp")
	warp_points = points_structure
	var polygon_period = warp_points.size() / (polygon.size() + 1)

	# Default all points, because we probably skip the last few when building proper positions
	for i in warp_points.size():
		warp_points[i] = polygon[0]
	
	warp_points[0] = polygon[0]
	for i in range(1, polygon.size()):
		warp_points[i * 2 - 1] = polygon[i]
		warp_points[i * 2] = polygon[i]

func resolve_warp(reset_points:bool):
	# TODO (sam) Are we slowly gonna accumulate a bunch of garbage from all the things that have been warped?
	# TODO (sam) I really hate this approach but PackedVector2Arrays cannot be null
	if reset_points:
		warp_points = PackedVector2Array()
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
		
