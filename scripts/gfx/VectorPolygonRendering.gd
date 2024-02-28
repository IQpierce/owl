extends Polygon2D
class_name VectorPolygonRendering

enum DrawState { Intro, Stable, Outro }

@export var intro_secs:float = 0
@export var _warpable:bool = false
@export var circle_draw_color:Color = Color(0.86274510622025, 0.86274510622025, 0.86274510622025)
@export var line_draw_color:Color = Color(0.70588237047195, 0.70588237047195, 0.70588237047195)
@export var draw_line_antialiased:bool = true
@export var skip_line_indeces:Array[int]	# Each line that begins with a vert index that's in this list, will be skipped
@export var split_points_max = 40

var draw_state:DrawState = DrawState.Stable
var draw_elapsed:float = 0
var initial_point_radius:float = 0
var initial_line_width:float = 0
var zoom_scaling = 1
var warp_points:PackedVector2Array
var far_distance:float = -1
var poly_from_warp_index = 0
var low_warp_index = 0
var high_warp_index = 0

func can_warp() -> bool:
	return draw_state != DrawState.Intro && _warpable

func _ready():
	if global_scale.y != global_scale.x && OS.has_feature("editor"):
		push_warning("Vector Rendering requires uniform scaling for good lines. Matching scale.y to scale.x.")
		global_scale.y = global_scale.x

	if global_scale.x > 0:
		initial_point_radius = OwlGame.instance.draw_point_thickness / global_scale.x
		initial_line_width = OwlGame.instance.draw_line_thickness / global_scale.x

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
	var warping = false
	if can_warp() && warp_points.size() > 0:
		points = warp_points
		stride = 1#2
		warping = true

	var draw_portion = 1
	if draw_state == DrawState.Intro || draw_state == DrawState.Outro && intro_secs > 0:
		draw_portion = draw_elapsed / intro_secs
	
	var vertex_count = points.size()

	for i in range(0, vertex_count, stride):
		# TODO (sam) Warp Points does not properly support this
		if skip_line_indeces.has(i):
			continue
		
		var next_index = 0
		if i < vertex_count - 1:
			next_index = i + 1

		var next_point = points[next_index]

		var beyond_warp = i >= low_warp_index && i <= high_warp_index
		var draw_line = !warping || beyond_warp || (i < low_warp_index && i % 2 == 0) || (i > high_warp_index && (points.size() - i) % 2 == 0)
		if draw_state != DrawState.Stable:
			var check_index = i
			var index_portion = check_index / (points.size() * 1.0)
			var next_portion = (check_index + 1) / (points.size() * 1.0)
			if draw_portion <= index_portion:
				draw_line = false
			else:
				var line_portion = clamp((draw_portion - index_portion) / (next_portion - index_portion), 0, 1)
				next_point = ((1 - line_portion) * points[i]) + (line_portion * next_point)

		if draw_line:
			draw_line(points[i], next_point, line_draw_color, initial_line_width * zoom_scaling, draw_line_antialiased)
	
	# @TODO - it would be nice to not have to repeat this entire loop verbatim!! dupe code!!!	
	# ... actually not quite dupe code anymore if we support dashed lines
	var polygon_vertex_count = polygon.size()
	for i in range(polygon_vertex_count):
		var x = polygon[i].x
		var y = polygon[i].y

		var draw_vert = true
		if draw_state != DrawState.Stable:
			var check_index = i
			if draw_portion <= check_index / (polygon.size() * 1.0):
				draw_vert = false

		if draw_vert:
			draw_circle(Vector2(x, y), initial_point_radius * zoom_scaling, circle_draw_color)

func undraw():
	if draw_elapsed > intro_secs || draw_elapsed <= 0:
		draw_elapsed = intro_secs
	draw_state = DrawState.Outro

func initiate_warp(warp_start:Vector2):
	if polygon.size() == 0:
		return

	warp_points.clear()
	var match_off_line = INF
	var match_prev = 0
	var match_next = 0

	for i in polygon.size():
		var prev_point = to_global(polygon[i])
		var next_point = to_global(polygon[(i + 1) % polygon.size()])
		var prev_to_warp = Vector3(warp_start.x - prev_point.x, warp_start.y - prev_point.y, 0)
		var warp_to_next = Vector3(next_point.x - warp_start.x, next_point.y - warp_start.y, 0)
		#TODO (sam) Is finding abs(min) sufficient, or do we need to match winding order?
		var off_line = abs(prev_to_warp.cross(warp_to_next).z)
		if off_line < match_off_line:
			match_off_line = off_line
			match_prev = i
			match_next = (i + 1) % polygon.size()
	
	poly_from_warp_index = match_prev

	var prev_point = to_local(warp_start)
	warp_points.append(prev_point)
	var total_dist = 0.0
	var index = match_prev
	for counted in range(1, polygon.size() + 1):
		index = (index + 1) % polygon.size()
		var next_point = polygon[index]
		warp_points.append(next_point)
		total_dist += (next_point - prev_point).length()
		prev_point = next_point
	total_dist += (warp_points[0] - prev_point).length()
	far_distance = total_dist / 2

	low_warp_index = 0
	high_warp_index = warp_points.size() - 1

func resolve_warp(reset_points:bool):
	# TODO (sam) Are we slowly gonna accumulate a bunch of garbage from all the things that have been warped?
	# TODO (sam) I really hate this approach but PackedVector2Arrays cannot be null
	if reset_points:
		warp_points.clear()
		#warp_points = PackedVector2Array()
	queue_redraw()

func prepare_warp(warp_progress:float, cycle_progress:float, delta:float):
	if far_distance <= 0:
		return

	var start_poly_index = poly_from_warp_index

	var low_poly_index  = build_warp_direction(true,  warp_points.size(), poly_from_warp_index + 1, warp_progress)
	var high_poly_index = build_warp_direction(false, low_warp_index + 1, poly_from_warp_index,     warp_progress)

	var fill_index = low_warp_index + 1
	var poly_index = low_poly_index
	var warp_point_index = fill_index
	var prev_poly_point = warp_points[fill_index]
	while poly_index < high_poly_index:
		var next_poly_point = polygon[poly_index % polygon.size()]
		if warp_point_index < high_warp_index:
			warp_points[warp_point_index] = next_poly_point
		else:
			warp_points.insert(warp_point_index, next_poly_point)
			high_warp_index += 1
		warp_point_index += 1
		fill_index += 1
		poly_index += 1
		prev_poly_point = next_poly_point
	
	queue_redraw()

func build_warp_direction(increment:bool, threshold_warp_index:int, start_poly_index:int, warp_progress:float) -> int:
	var dash_points = (split_points_max * warp_progress) as int
	var warp_dist = far_distance * warp_progress

	var accumulate_poly_index = poly_from_warp_index + 1 if increment else poly_from_warp_index + polygon.size() + 1

	var ran_length = 0
	var prev_poly_point = warp_points[0]
	var warp_end_found = false
	var warp_point_index = 0 if increment else warp_points.size() - 1
	var step_i           = 0 if increment else polygon.size()
	var step_size        = 1 if increment else -1

	while !warp_end_found && ((increment && step_i < polygon.size()) || (!increment && step_i >= 0)):
		var next_poly_point = polygon[(start_poly_index + step_i) % polygon.size()]
		var segment_length = (next_poly_point - prev_poly_point).length()
		if ran_length + segment_length > warp_dist:
			var end_portion = clamp((warp_dist - ran_length) / segment_length, 0, 1)
			next_poly_point = ((1 - end_portion) * prev_poly_point) + (end_portion * next_poly_point)
			segment_length = (warp_dist - ran_length)
			warp_end_found = true
		else:
			accumulate_poly_index += step_size
		var points_between = ((segment_length / far_distance) * split_points_max) as int + 1
		for j in points_between:
			var portion = clamp(j / (points_between * 1.0), 0, 1)
			var new_warp_point = ((1 - portion) * prev_poly_point) + (portion * next_poly_point)
			if (increment && warp_point_index < threshold_warp_index) || (!increment && warp_point_index > threshold_warp_index):
				warp_points[warp_point_index] = new_warp_point
			else:
				warp_point_index = threshold_warp_index
				warp_points.insert(warp_point_index, new_warp_point)
			if increment:
				low_warp_index = warp_point_index
			else:
				high_warp_index = warp_point_index
			warp_point_index += step_size
		ran_length += segment_length
		prev_poly_point = next_poly_point
		step_i += step_size

	return accumulate_poly_index
