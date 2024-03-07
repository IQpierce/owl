extends Polygon2D
class_name PatchworkPolygon2D

#TODO (sam) We can remove patchwork field and always just edit raw polygon data, but children must define all verts 
#  this is to allow for Polygon to draw its fill so we can properly stencil
@export var ccw_convexity:bool = true
# TODO (sam) This is pretty gross, but Godot doesn't support exporting arbitrary data class, so we're stuck with this or a dictionary.
@export var injected_polygons:Array[InjectedPolygon2D]
@export var stencil_polygons:Array[PatchworkPolygon2D]

var raw_polygon:PackedVector2Array
#var patchwork:PackedVector2Array
var patch_pairs:PackedByteArray
var post_patch_extras:PackedByteArray
var hidden_verts:PackedByteArray
var matching_collider:PolygonCorrespondence

static func compare(a: InjectedPolygon2D, b:InjectedPolygon2D):
	return a.injectee_open < b.injectee_open

func _build_on_ready() -> bool:
	return true

func _ready():
	color.a = 0
	raw_polygon.resize(polygon.size())
	for i in polygon.size():
		raw_polygon[i] = polygon[i]
	if injected_polygons.size() > 0:
		injected_polygons.sort_custom(compare)
	if _build_on_ready():
		build_patchwork()

func _draw():
	var normals_length = OwlGame.instance.draw_normals
	if normals_length > 0 && global_scale.x > 0:
		for i in polygon.size():
			if !hidden_verts.has(i) || !hidden_verts.has((i + 1) % polygon.size()):
				var start = polygon[i]
				var end = polygon[(i + 1) % polygon.size()]
				var mid = (start + end) / 2
				var normal = get_patchwork_normal(i) / global_scale.x * normals_length
				draw_line(mid, mid + normal, Color.BLUE, 1 / global_scale.x, true)

func build_patchwork():
	# We need at least one vertex to attach to, and we don't want to build before we've hit _ready.
	if raw_polygon.size() < 1:
		return

	patch_pairs.clear()
	var polygon_size = raw_polygon.size()
	var inject_count = injected_polygons.size()

	if inject_count == 0 && stencil_polygons.size() == 0:
		polygon = raw_polygon
	else:
		var patchwork = PackedVector2Array()

		var inject_i = 0
		var polygon_i = 0
		var patchwork_i = 0
		while polygon_i < polygon_size:
			var inject:InjectedPolygon2D = null
			if inject_i < inject_count:
				if injected_polygons[inject_i] != null && polygon_i == injected_polygons[inject_i].injectee_open:
					inject = injected_polygons[inject_i]
					inject_i += 1

			patchwork.append(raw_polygon[polygon_i])
			polygon_i += 1
			patchwork_i += 1

			if inject != null:
				var patch_start = patchwork_i
				inject.build_patchwork()
				patchwork.append_array(inject.polygon)
				var patch_end = patchwork.size() - 1
				for trans_i in range(patch_start, patch_end + 1):
					patchwork[trans_i] = to_local(inject.to_global(patchwork[trans_i]))
				polygon_i = inject.injectee_close
				patch_pairs.append(patch_start)
				patch_pairs.append(patch_end)
				patchwork_i = patch_end + 1

		polygon = patchwork
	

	if matching_collider != null:
		matching_collider.sync_polygon_data()

func get_patchwork_normal(index:int, global_direction:bool = false):
	if index >= polygon.size():
		return Vector2.ZERO

	var start = polygon[index]
	var end = polygon[(index + 1) % polygon.size()]
	var normal = end - start
	normal = Vector2(normal.y, -normal.x).normalized()
	if ccw_convexity:
		normal *= -1
	
	if global_direction:
		normal = normal.rotated(global_rotation)

	return normal

func reinject(inject:InjectedPolygon2D):
	for inject_i in injected_polygons.size():
		if injected_polygons[inject_i] == inject:
			pass
	# TODO (sam) only rebuild the verts between the injected open and close


