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
#var warp_start:Vector2 = Vector2.ZERO
var far_distance:float = -1
var low_warp_index = 0
var high_warp_index = 0

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
	var warping = false
	if can_warp() && warp_points.size() > 0:
		points = warp_points
		stride = 1#2
		warping = true

	var draw_portion = 1
	if draw_state == DrawState.Intro || draw_state == DrawState.Outro && intro_secs > 0:
		draw_portion = draw_elapsed / intro_secs
	
	var vertex_count = points.size()

	#TODO REMOVE
	if vertex_count >= 40:
		pass#print("REMOVE ", points)

	#if warp_points.size() > 0:
	#	print(low_warp_index, " | ", warp_points[low_warp_index], " | ", warp_points[low_warp_index + 1])
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

		# TODO (sam) low and high warp index are not sufficient for warps that don't start at polygon[0]
		var beyond_warp = i >= low_warp_index && i <= high_warp_index
		var draw_line = !warping || beyond_warp || (i < low_warp_index && i % 2 == 0) || (i > high_warp_index && (points.size() - i) % 2 == 0)
		#var draw_line = !warping || (i > high_warp_index && (i - high_warp_index) % 2 == 0)
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

# TODO (sam) do not take in points structure
func initiate_warp(points_structure:PackedVector2Array):
	if polygon.size() == 0 || points_structure.size() < polygon.size() * 2:
		return

	#warp_points = points_structure
	warp_points = PackedVector2Array()
	#for point in polygon:
	#	warp_points.append(point)

	#TODO (sam) we need to consider where we start the warp from, instead of first polygon vert
	warp_points.append(polygon[0])
	var prev_point = warp_points[0]
	var total_dist = 0.0
	var index = 0
	for counted in range(1, polygon.size()):
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
		warp_points = PackedVector2Array()
	queue_redraw()

func prepare_warp(warp_progress:float, cycle_progress:float, delta:float):
	if far_distance <= 0:
		return

	#TODO define this as a member?
	var max_dash_points = 40

	var dash_points = (max_dash_points * warp_progress) as int

	var warp_dist = far_distance * warp_progress
	var low_poly_index = 1
	var high_poly_index = polygon.size()

	var ran_length = 0
	var poly_points_added = 0
	var start_poly_index = 0 #TODO this depends on where started ... we often want to start between two polygon points, so is this the first or last one we'll reach?
	var prev_poly_point = polygon[start_poly_index] # TODO this should instead be the point we start the warp (which may not be an exact vert on the polygon
	var warp_point_index = 0
	var warp_end_found = false
	var inc_i = 0
	while inc_i < polygon.size() && !warp_end_found:
		var next_poly_point = polygon[(start_poly_index + inc_i + 1) % polygon.size()]
		var segment_length = (next_poly_point - prev_poly_point).length()
		if ran_length + segment_length > warp_dist:
			var end_portion = clamp((warp_dist - ran_length) / segment_length, 0, 1)
			next_poly_point = ((1 - end_portion) * prev_poly_point) + (end_portion * next_poly_point)
			segment_length = (warp_dist - ran_length)
			warp_end_found = true
		else:
			low_poly_index += 1
		var points_between = ((segment_length / far_distance) * max_dash_points) as int + 1
		for j in points_between:
			var portion = clamp(j / (points_between * 1.0), 0, 1)
			# TODO (sam) This is rough approximation of letting dashes be smaller than gaps
			#if warp_point_index % 2 != 0:
			#	var prev_portion = clamp((j - 1) / (points_between * 1.0), 0, 1)
			#	portion = (prev_portion + portion) / 2
			var new_warp_point = ((1 - portion) * prev_poly_point) + (portion * next_poly_point)
			if warp_point_index < warp_points.size():
				warp_points[warp_point_index] = new_warp_point
			else:
				warp_points.append(new_warp_point)
			low_warp_index = warp_point_index
			#high_warp_index = warp_points.size() - 1
			warp_point_index += 1
		ran_length += segment_length
		prev_poly_point = next_poly_point
		if !warp_end_found:
			inc_i += 1
			poly_points_added += 1
		else:
			break

	var dec_i = polygon.size()
	ran_length = 0
	#var start_poly_index = 0 #TODO this depends on where started ... we often want to start between two polygon points, so is this the first or last one we'll reach?
	prev_poly_point = polygon[start_poly_index] # TODO this should instead be the point we start the warp (which may not be an exact vert on the polygon
	#var warp_point_index = warp_points.size()
	#var insert_index = warp_points.size() #NO insert size is not length because this could be later frame... but we cannot just append because we are going backwards
	warp_end_found = false
	warp_point_index = warp_points.size() - 1
	while dec_i >= 0 && !warp_end_found:
		var next_poly_point = polygon[(start_poly_index + dec_i - 1) % polygon.size()]
		var segment_length = (next_poly_point - prev_poly_point).length()
		if ran_length + segment_length > warp_dist:
			var end_portion = clamp((warp_dist - ran_length) / segment_length, 0, 1)
			next_poly_point = ((1 - end_portion) * prev_poly_point) + (end_portion * next_poly_point)
			segment_length = (warp_dist - ran_length)
			warp_end_found = true
		else:
			high_poly_index -= 1
		var points_between = ((segment_length / far_distance) * max_dash_points) as int + 1
		for j in points_between:
			var portion = clamp(j / (points_between * 1.0), 0, 1)
			# TODO (sam) This is rough approximation of letting dashes be smaller than gaps
			#if warp_point_index % 2 != 0:
			#	var prev_portion = clamp((j - 1) / (points_between * 1.0), 0, 1)
			#	portion = (prev_portion + portion) / 2
			var new_warp_point = ((1 - portion) * prev_poly_point) + (portion * next_poly_point)
			if warp_point_index > low_warp_index + 1:
				warp_points[warp_point_index] = new_warp_point
			else:
				warp_point_index = low_warp_index + 1
				warp_points.insert(warp_point_index, new_warp_point)
			#warp_points.insert(insert_index, new_warp_point)
			#low_warp_index = warp_point_index
			high_warp_index = warp_point_index
			warp_point_index -= 1
		ran_length += segment_length
		prev_poly_point = next_poly_point
		if !warp_end_found:
			dec_i -= 1
			poly_points_added += 1
		else:
			break

	var fill_index = low_warp_index + 1
	#if low_warp_index % 2 == 0:
	#	low_warp_index -= 1
	var poly_index = low_poly_index
	warp_point_index = fill_index
	prev_poly_point = warp_points[fill_index]
	while poly_index < high_poly_index:
		var next_poly_point = polygon[poly_index % polygon.size()]
		if warp_point_index < high_warp_index:
			warp_points[warp_point_index] = next_poly_point
		else:
			warp_points.insert(warp_point_index, next_poly_point)
			high_warp_index += 1
		warp_point_index += 1
		fill_index += 1
		poly_points_added += 1
		poly_index += 1
		prev_poly_point = next_poly_point
	
	# TODO (sam) This is a hack to remove the extra visible-dash at the end... this should not exist
	#if warp_progress >= 1:
	#	high_warp_index = low_warp_index - 1
	#print("-------")


	queue_redraw()
		
