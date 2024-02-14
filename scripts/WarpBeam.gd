extends Node2D
class_name WarpBeam

enum WarpSpace { Interior, Exterior }

@export var warp_space:WarpSpace = WarpSpace.Interior
@export_range(1, 20) var segment_count:int = 6
@export var cycle_speed:float = 10
@export_range(0.2, 10) var prep_req_seconds:float = 1
@export_range(1, 100) var target_segment_count:int = 40

var reach:float = 100
var progress:float = 0
var points:PackedVector2Array
var target_points:PackedVector2Array
var draw_delta:float = 0
var target:Thing
var prep_duration:float = 0

func _ready():
	# TODO (sam) Is there really no way reserve a dynamic size all at once?
	var point_count = segment_count * 2
	for i in point_count:
		points.append(Vector2.ZERO)

	var target_point_count = target_segment_count * 2
	for i in target_point_count:
		target_points.append(Vector2.ZERO)

func _process(delta: float):
	if visible:
		draw_delta += delta
		queue_redraw()

func _draw():
	var direction = Vector2.UP.rotated(global_rotation)
	var dash_size = reach / ((segment_count * 2) - 1)
	var seg_start = 0
	var seg_end = progress

	var cap = reach
	var new_target:Thing = null

	# TODO (sam) It would be better to raycast from the behind the parents collider, so don't miss the raycast up-close.
	var space_state = get_world_2d().direct_space_state
	var raycast = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * cap)
	var hit = space_state.intersect_ray(raycast)
	if hit != null:
		if hit.has("position"):
			cap = (hit["position"] - global_position).length()
		if hit.has("collider"):
			new_target = hit["collider"] as Thing

	points[0] = Vector2(0, clamp(progress - dash_size, 0, cap))
	points[1] = Vector2(0, min(seg_end, cap))

	for i in segment_count - 1:
		var index = (i + 1) * 2
		seg_start = seg_end + dash_size
		seg_end = seg_start + dash_size
		points[index] = Vector2(0, min(seg_start, cap))
		points[index + 1] = Vector2(0, min(seg_end, cap))
	
	# It is just easier to think in positive numbers and then flip
	for i in points.size():
		points[i].y *= -1

	draw_multiline(points, Color.WHITE)
	prepare_target(new_target, draw_delta)

	progress += cycle_speed * draw_delta
	if progress >= dash_size * 2:
		progress -= dash_size * 2

	draw_delta = 0

func prepare_target(new_target:Thing, delta:float):
	var target_geom = get_geometry(new_target)
	if target != new_target:
		var old_target_geom = get_geometry(target)
		if old_target_geom != null:
			old_target_geom.resolve_warp()
		target = new_target
		if target_geom != null:
			target_geom.initiate_warp(target_points)
		prep_duration = 0
	
	if target != null:
		if target_geom != null:
			target_geom.prepare_warp(prep_duration / prep_req_seconds, 1, delta)	
		prep_duration = min(prep_duration + delta, prep_req_seconds)

func get_geometry(target:Thing) -> VectorPolygonRendering:
	if target != null && target.anatomy != null && target.anatomy.line_geometry.size() > 0:
		return target.anatomy.line_geometry[0]
	return null


