extends Node2D
class_name WarpBeam

enum WarpSpace { Interior, Exterior }

@export var warp_space:WarpSpace = WarpSpace.Interior
@export var max_reach:float = 100
@export var reach_rate:float = 1
@export_range(1, 20) var segment_count:int = 6
@export var cycle_speed:float = 10
@export_range(0.2, 10) var prep_req_seconds:float = 1
@export_range(1, 100) var target_segment_count:int = 40
@export_range(0, 1) var transversity:float = 0

var reach:float = 0
var reach_cap:float = 0
var dash_size:Vector2 = Vector2.ZERO
var progress:float = 0
var points:PackedVector2Array
var target_points:PackedVector2Array
var target:Thing
var prep_duration:float = 0
var warp_ready:bool = false

signal found_target
signal lost_target

func _ready():
	# TODO (sam) Is there really no way reserve a dynamic size all at once?
	var point_count = segment_count * 2
	for i in point_count:
		points.append(Vector2.ZERO)

	var target_point_count = target_segment_count * 2
	for i in target_point_count:
		target_points.append(Vector2.ZERO)

func _process(delta:float):
	if visible:
		reach = min(reach + (reach_rate * max_reach * delta), max_reach)
		var direction = Vector2.UP.rotated(global_rotation)
		dash_size = Vector2(0, reach / ((segment_count * 2) - 1))
		reach_cap = reach
		var new_target:Thing = null

		# TODO (sam) It would be better to raycast from the behind the parents collider, so don't miss the raycast up-close.
		var space_state = get_world_2d().direct_space_state
		var raycast = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * reach_cap)
		var hit = space_state.intersect_ray(raycast)
		var warp_start = Vector2.ZERO
		if hit != null:
			if hit.has("position"):
				reach_cap = (hit["position"] - global_position).length()
				warp_start = hit["position"]
			if hit.has("collider"):
				new_target = hit["collider"] as Thing

		progress += cycle_speed * delta
		if progress >= dash_size.y * 2:
			progress -= dash_size.y * 2

		prepare_target(new_target, warp_start, delta)
		progress += cycle_speed * delta
		if progress >= dash_size.y * 2:
			progress -= dash_size.y * 2

		queue_redraw()
	else:
		reach = 0
		if !warp_ready && target != null:
			prepare_target(null, Vector2.ZERO, delta)

func _draw():
	if reach_cap <= 0:
		return

	var dash_alignment = 1
	var seg_start = 0
	var seg_end = progress

	if transversity > 0:
		dash_size.x = dash_size.y
		dash_alignment = 0

	var progress_portion = progress / (dash_size.y * 2)
	var base_transverse_size = dash_size.x * progress_portion * (1 - transversity)

	points[0] = Vector2(-base_transverse_size, clamp(progress - (dash_size.y * dash_alignment), 0, reach_cap))
	points[1] = Vector2(base_transverse_size, min(seg_end, reach_cap))

	for i in segment_count - 1:
		var index = (i + 1) * 2
		seg_start = seg_end + dash_size.y + (dash_size.y * (1 - dash_alignment))
		seg_end = seg_start + dash_size.y * dash_alignment
		var transverse_size = base_transverse_size + (dash_size.x * transversity * (i / (segment_count - 1.0)))

		points[index] = Vector2(-transverse_size, min(seg_start, reach_cap))
		points[index + 1] = Vector2(transverse_size, min(seg_end, reach_cap))
	
	# It is just easier to think in positive numbers and then flip
	for i in points.size():
		points[i].y *= -1

	draw_multiline(points, OwlGame.instance.draw_line_color, OwlGame.instance.draw_line_thickness / global_scale.x)

func prepare_target(new_target:Thing, warp_start:Vector2, delta:float):
	# If warp is currently ready, it cannot be changed
	if warp_ready:
		return

	var target_geom = get_geometry(new_target)
	if target != new_target:
		var old_target_geom = get_geometry(target)
		if old_target_geom != null:
			old_target_geom.resolve_warp(!warp_ready)
		else:
			found_target.emit()
		target = new_target
		if target_geom != null:
			target_geom.initiate_warp(warp_start)
		else:
			lost_target.emit()
		prep_duration = 0
	
	if target != null:
		if target_geom != null:
			target_geom.prepare_warp(prep_duration / prep_req_seconds, 1, delta)	
		prep_duration = min(prep_duration + delta, prep_req_seconds)
	
	warp_ready = (target != null && prep_duration >= prep_req_seconds) || warp_ready

func get_geometry(target:Thing) -> VectorPolygonRendering:
	if target != null && target.anatomy != null && target.anatomy.line_geometry.size() > 0:
		if target.anatomy.line_geometry[0].can_warp():
			return target.anatomy.line_geometry[0]
	return null


