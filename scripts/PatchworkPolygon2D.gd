extends Polygon2D
class_name PatchworkPolygon2D

@export var ccw_convexity:bool = true
# TODO (sam) This is pretty gross, but Godot doesn't support exporting arbitrary data class, so we're stuck with this or a dictionary.
@export var injected_polygons:Array[InjectedPolygon2D]

var patchwork:PackedVector2Array
var patch_pairs:PackedByteArray
var matching_collider:PolygonCorrespondence

static func compare(a: InjectedPolygon2D, b:InjectedPolygon2D):
	return a.injectee_open < b.injectee_open

func _build_on_ready() -> bool:
	return true

func _ready():
	if injected_polygons.size() > 0:
		injected_polygons.sort_custom(compare)
	if _build_on_ready():
		build_patchwork()

func _draw():
	var normals_length = OwlGame.instance.draw_normals
	if normals_length > 0 && global_scale.x > 0:
		for i in patchwork.size():
			var start = patchwork[i]
			var end = patchwork[(i + 1) % patchwork.size()]
			var mid = (start + end) / 2

			var normal = end - start
			normal = Vector2(normal.y, -normal.x).normalized() / global_scale.x * normals_length
			if ccw_convexity:
				normal *= -1

			draw_line(mid, mid + normal, Color.BLUE, 1 / global_scale.x, true)

func build_patchwork():
	patch_pairs.clear()
	var polygon_size = polygon.size()
	var inject_count = injected_polygons.size()

	if inject_count == 0:
		patchwork = polygon
	else:
		if patchwork == polygon:
			patchwork = PackedVector2Array()
		else:
			patchwork.clear()

		var inject_i = 0
		var polygon_i = 0
		var patchwork_i = 0
		while polygon_i < polygon_size:
			var inject:InjectedPolygon2D = null
			if inject_i < inject_count:
				if injected_polygons[inject_i] != null && polygon_i == injected_polygons[inject_i].injectee_open:
					inject = injected_polygons[inject_i]
					inject_i += 1

			patchwork.append(polygon[polygon_i])
			polygon_i += 1
			patchwork_i += 1

			if inject != null:
				var patch_start = patchwork_i
				inject.build_patchwork()
				patchwork.append_array(inject.patchwork)
				var patch_end = patchwork.size() - 1
				for trans_i in range(patch_start, patch_end + 1):
					patchwork[trans_i] = to_local(inject.to_global(patchwork[trans_i]))
				polygon_i = inject.injectee_close
				patch_pairs.append(patch_start)
				patch_pairs.append(patch_end)
				patchwork_i = patch_end + 1
	
	if matching_collider != null:
		matching_collider.sync_polygon_data()

func reinject(inject:InjectedPolygon2D):
	for inject_i in injected_polygons.size():
		if injected_polygons[inject_i] == inject:
			pass
	# TODO (sam) only rebuild the verts between the injected open and close


