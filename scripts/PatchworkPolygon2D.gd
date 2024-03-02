extends Polygon2D
class_name PatchworkPolygon2D

@export var ccw_convexity:bool = true
# TODO (sam) This is pretty gross, but Godot doesn't support exporting arbitrary data class, so we're stuck with this or a dictionary.
@export var injected_polygons:Array[InjectedPolygon2D]
@export var stencil_polygons:Array[PatchworkPolygon2D]

var patchwork:PackedVector2Array
var patch_pairs:PackedByteArray
var post_patch_extras:PackedByteArray
var hidden_verts:PackedByteArray
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
			if !hidden_verts.has(i) || !hidden_verts.has((i + 1) % patchwork.size()):
				var start = patchwork[i]
				var end = patchwork[(i + 1) % patchwork.size()]
				var mid = (start + end) / 2
				var normal = get_patchwork_normal(i) / global_scale.x * normals_length
				draw_line(mid, mid + normal, Color.BLUE, 1 / global_scale.x, true)

func build_patchwork():
	patch_pairs.clear()
	var polygon_size = polygon.size()
	var inject_count = injected_polygons.size()

	if inject_count == 0 && stencil_polygons.size() == 0:
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

	# In lieu of a stencil buffer and render order, we can manually compare the vertices of polygons
	# This is not cheap... we might want to use the raw polygon as a stencil instead of the whole patchwork
	for stencil_polygon in stencil_polygons:
		if stencil_polygon != null:
			hidden_verts.clear()
			post_patch_extras.clear()
			var prev_hidden = false
			# TODO (sam) Is there a way to check if two exterior verts actually draw a line across the stencil polygon?
			# It would be nice to insert hidden verts and cut that line as it passes through.
			# OH I think we need to check dot product AND if the line between is with prev_stencil-next_stencil (projection not longer than basis)
			# NEED TO INCLUDE THE INSERTED VERTS (overwrite)
			#var prev_vert = Vector2.ZERO
			#var prev_on_stencil = Vector2.ZERO
			#var prev_closest_index = 0
			var self_i = 0

			while self_i < patchwork.size() + 1:
				var self_wrap_i = self_i % patchwork.size()
				if !hidden_verts.has(self_wrap_i):
					var self_vert = to_global(patchwork[self_wrap_i])
					var closest_index:int = 0
					var closest_colinearity = 0
					var closest_off_line = INF
					var closest_proj_on_stencil = Vector2.ZERO
					var closest_stencil_to_self = Vector2.ZERO
					var closest_stencil_to_stencil = Vector2.ZERO
					for stencil_i in stencil_polygon.polygon.size():
						var prev_stencil = stencil_polygon.polygon[stencil_i]
						prev_stencil = stencil_polygon.to_global(prev_stencil)
						var next_stencil = stencil_polygon.polygon[(stencil_i + 1) % stencil_polygon.polygon.size()]
						next_stencil = stencil_polygon.to_global(next_stencil)
						var stencil_to_stencil = next_stencil - prev_stencil
						var stencil_to_self = self_vert - prev_stencil
						#var self_to_stencil = next_stencil - self_vert
						#var within_line = stencil_to_self.project(stencil_to_stencil).length_squared() < stencil_to_stencil.length_squared()
						# TODO (sam) could we just do this with a dot product?
						#var off_line = abs(Vector3(stencil_to_self.x, stencil_to_self.y, 0).normalized().cross(Vector3(self_to_stencil.x, self_to_stencil.y, 0).normalized()).z)
						#print("cross ", off_line, " ", within_line)
						#if within_line && off_line < closest_off_line:
						var colinearity = stencil_to_self.normalized().dot(stencil_to_stencil.normalized())

						var stencil_to_proj_on_stencil = stencil_to_self.project(stencil_to_stencil)
						var proj_on_stencil = stencil_to_proj_on_stencil + prev_stencil
						var between_stencil = stencil_to_proj_on_stencil.dot(stencil_to_stencil) >= 0 && stencil_to_proj_on_stencil.length_squared() < stencil_to_stencil.length_squared()
						var off_line = (self_vert - proj_on_stencil).length_squared()
						#print("  line check ", off_line, " ", between_stencil, self_vert, prev_stencil)
						#print("  proj ", stencil_to_stencil, "|", stencil_to_self, "|", proj_on_stencil, " ", between_stencil)

						#if colinearity > closest_colinearity:
						if off_line < closest_off_line:
							if between_stencil:
								closest_index = stencil_i
								closest_colinearity = colinearity
								closest_off_line = off_line
								closest_stencil_to_self = stencil_to_self
								closest_stencil_to_stencil = stencil_to_stencil
								closest_proj_on_stencil = proj_on_stencil

					var stencil_normal = stencil_polygon.get_patchwork_normal(closest_index, true)
					#var proj_on_stencil = closest_stencil_to_self.project(closest_stencil_to_stencil)
					var vert_hidden = (self_vert - closest_proj_on_stencil).dot(stencil_normal) <= 0
					#print(self_i, "(", self_wrap_i - post_patch_extras.size(), ") ", closest_index, " ", vert_hidden, " ", stencil_normal.normalized(), " ", (self_vert - closest_proj_on_stencil).normalized())
					#print("  ", self_vert, " ", closest_proj_on_stencil)
					#print("")

					var hidden_index = 0
					while hidden_index < hidden_verts.size() && hidden_verts[hidden_index] < self_wrap_i:
						hidden_index += 1

					var extras_index = 0
					while extras_index < post_patch_extras.size() && post_patch_extras[extras_index] < self_wrap_i:
						extras_index += 1

					if self_wrap_i == 0:
						hidden_index = 0
						extras_index = 0

					if self_i != 0:
						if prev_hidden != vert_hidden:
							hidden_verts.insert(hidden_index, self_wrap_i)
							post_patch_extras.insert(extras_index, self_wrap_i)
							patchwork.insert(self_wrap_i, to_local(closest_proj_on_stencil))
							if vert_hidden:
								hidden_verts.insert(hidden_index + 1, self_wrap_i + 1)
							#print("insert vert at ", self_wrap_i)
							#vert_hidden = prev_hidden
							self_i += 1
						elif vert_hidden:
							hidden_verts.insert(hidden_index, self_wrap_i)
							hidden_index += 1

					prev_hidden = vert_hidden
					#prev_vert = self_vert
					#prev_on_stencil = closest_proj_on_stencil
					#prev_closest_index = closest_index
					self_i += 1
	
	#if hidden_verts.size() > 0:
	#	print(hidden_verts)

	if matching_collider != null:
		matching_collider.sync_polygon_data()

func get_patchwork_normal(index:int, global_direction:bool = false):
	if index >= patchwork.size():
		return Vector2.ZERO

	var start = patchwork[index]
	var end = patchwork[(index + 1) % patchwork.size()]
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


