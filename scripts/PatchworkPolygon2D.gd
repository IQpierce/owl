@tool

extends Polygon2D
class_name PatchworkPolygon2D

#TODO (sam) Maybe remove InjectedPolygon and just make Patchwork injectable
# and instead of an array of children, just keep a parent... If I don't have a parent, I do the draw

#TODO (sam) We can remove patchwork field and always just edit raw polygon data, but children must define all verts 
#  this is to allow for Polygon to draw its fill so we can properly stencil
@export var ccw_convexity:bool = true
# TODO (sam) This is pretty gross, but Godot doesn't support exporting arbitrary data class, so we're stuck with this or a dictionary.
@export var injected_polygons:Array[InjectedPolygon2D]

@export var editor_line_width:int = 0
@export var refresh_svg:bool = false
@export var write_svg:bool = false
@export var svg:CompressedTexture2D = null
@export var svg_scale:float = 1.0
@export var svg_children:Array[PatchworkPolygon2D]

var _missed_draw:bool = false
var raw_polygon:PackedVector2Array
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

func _process(delta:float):
	if Engine.is_editor_hint():
		if refresh_svg:
			load_svg()
			refresh_svg = false
		if write_svg:
			save_svg()
			write_svg = false

func _draw():
	if Engine.is_editor_hint():
		var vertex_count = polygon.size()
		var line_width = OwlGame.instance.draw_line_thickness / ((global_scale.x + global_scale.y) / 2.0)
		if editor_line_width > 0:
			line_width = editor_line_width
		for i in vertex_count:
			draw_line(polygon[i], polygon[(i + 1) % vertex_count], Color.WHITE, line_width)

		return

	if !OwlGame.in_first_lod(self, OwlGame.LOD.Draw):
		_missed_draw = true
		return

	_missed_draw = false
	var normals_length = OwlGame.instance.draw_normals
	if normals_length > 0:
		var draw_scale = (abs(global_scale.x) + abs(global_scale.y)) / 2
		if draw_scale > 0:
			var normal_color = Color.GRAY
			normal_color.g8 = 0
			for i in polygon.size():
				if !hidden_verts.has(i) || !hidden_verts.has((i + 1) % polygon.size()):
					var start = polygon[i]
					var end = polygon[(i + 1) % polygon.size()]
					var mid = (start + end) / 2
					var normal = get_patchwork_normal(i) / draw_scale * normals_length
					draw_line(mid, mid + normal, normal_color, 1 / draw_scale, true)

func build_patchwork():
	if Engine.is_editor_hint():
		return

	# We need at least one vertex to attach to, and we don't want to build before we've hit _ready.
	if raw_polygon.size() < 1:
		return

	patch_pairs.clear()
	var polygon_size = raw_polygon.size()
	var inject_count = injected_polygons.size()

	if inject_count == 0:
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

# TODO (sam) maybe everything below this should be moved to an EditorPlugin
func load_svg():
	if Engine.is_editor_hint() && svg != null:
		print("load svg ", svg.resource_path)
		var svg_file = FileAccess.open(svg.resource_path, FileAccess.READ)
		if svg_file.get_error() != OK:
			print("Failed to load ", svg.resource_path, " with code ", svg_file.get_error())
		var svg_text = svg_file.get_as_text()
		svg_file.close()
		#print(svg_text)
		#var find_index = 0
		#var file_len = svg_text.size()
		#while find_index >= 0 && find_index < file_len:
		#	print(svg_text
		var paths = svg_text.split("<path ", false)
		for i in range(paths.size() - 1, -1, -1):
			#if paths[i].size() < 2 || paths[i][0] != 'd' || paths[i][1] != '=':
			var stripped_path = paths[i].strip_edges()
			if stripped_path.begins_with("d="):
				paths[i] = stripped_path.get_slice("\"", 1).strip_edges()
				var moves = paths[i].split("M", false)
				for j in range(moves.size() - 1, 0, -1):
					paths.insert(i + 1, str("M", moves[j]))
				paths[i] = str("M", moves[0])
			else:
				paths.remove_at(i)

		#print(paths)

		for i in svg_children.size():
			if svg_children[i] != null:
				svg_children[i].get_parent().remove_child(svg_children[i])
				svg_children[i].owner = null
		svg_children.clear()

		polygon = PackedVector2Array()
		var write_polygon = self
		var coordinates:Array[PathCoordinate] = []
		var full_coord_idx = 0
		var cache_to_type = PathCoordinate.ToType.Move
		var need_space = false
		for path in paths:
			var find_start = 0
			var path_len = path.length()
			while find_start < path_len:
				#print(find_start)#, path.substr(find_start))
				if false:#need_space:
					pass
				else:
					#TODO (sam) Currently only supporting absolute coordinates, relative is denoted with lower case
					var m_idx = path.find("M", find_start)
					var l_idx = path.find("L", find_start)
					var c_idx = path.find("C", find_start)
					var h_idx = path.find("H", find_start)
					var v_idx = path.find("V", find_start)
					var __idx = path.find(" ", find_start)
					#print("coord from ", find_start, ": ", m_idx, " ", l_idx, " ", c_idx, " ", h_idx, " ", v_idx, " ", __idx)

					if m_idx < 0:
						m_idx = path_len
					if l_idx < 0:
						l_idx = path_len
					if c_idx < 0:
						c_idx = path_len
					if h_idx < 0:
						h_idx = path_len
					if v_idx < 0:
						v_idx = path_len
					if __idx < 0:
						__idx = path_len
					
					var coord_start = path_len
					if m_idx < path_len && m_idx < l_idx && m_idx < c_idx && m_idx < h_idx && m_idx < v_idx && m_idx < __idx:
						cache_to_type = PathCoordinate.ToType.Move
						coord_start = m_idx + 1
					elif l_idx < path_len && l_idx < c_idx && l_idx < h_idx && l_idx < v_idx && l_idx < __idx:
						cache_to_type = PathCoordinate.ToType.Line
						coord_start = l_idx + 1
					elif c_idx < path_len && c_idx < h_idx && c_idx < v_idx && c_idx < __idx:
						cache_to_type = PathCoordinate.ToType.Curve
						coord_start = c_idx + 1
					elif h_idx < path_len && h_idx < v_idx && h_idx < __idx:
						cache_to_type = PathCoordinate.ToType.Horizontal
						coord_start = h_idx + 1
					elif v_idx < path_len && v_idx < __idx:
						cache_to_type = PathCoordinate.ToType.Vertical
						coord_start = v_idx + 1
					elif __idx < path_len:
						coord_start = __idx + 1

					if coord_start < path_len:
						#print("found coord ", coord_start, " ", cache_to_type)#, " | ", path.substr(coord_start))
						#if coordinates.size() > full_coord_idx:
						#	coordinates[coordinates.size() - 1].y = path.substr(find_start, coord_start).to_float()
						#	full_coord_idx = coordinates.size()

						if cache_to_type == PathCoordinate.ToType.Horizontal:
							var coord = PathCoordinate.new()
							coord.to_type = cache_to_type
							coord.x = path.substr(coord_start).to_float()
							coord.y = coordinates[coordinates.size() - 1].y
							coordinates.append(coord)
							full_coord_idx = coordinates.size()
							find_start = coord_start + 1
						elif cache_to_type == PathCoordinate.ToType.Vertical:
							var coord = PathCoordinate.new()
							coord.to_type = cache_to_type
							coord.y = path.substr(coord_start).to_float()
							coord.x = coordinates[coordinates.size() - 1].x
							coordinates.append(coord)
							full_coord_idx = coordinates.size()
							find_start = coord_start + 1
						else:
							var coord = PathCoordinate.new()
							coord.to_type = cache_to_type
							coord.x = path.substr(coord_start).to_float()
							__idx = path.find(" ", coord_start)
							#if coordinates.size() > full_coord_idx:
							#	full_coord_idx = coordinates.size()
							if __idx >= 0:
								find_start = __idx + 1
								coord.y = path.substr(find_start).to_float()
							else:
								find_start = path_len
							coordinates.append(coord)
						#print("find from", find_start)
						#need_space = true
						#for coord in coordinates:
						#	print(coord.to_type, ": ", coord.x, " ", coord.y)
					else:
						#print("end path")
						full_coord_idx = coordinates.size()
						find_start = path_len
						break

			if write_polygon.polygon.size() > 0:
				write_polygon = write_polygon.duplicate()
				write_polygon.svg = null
				write_polygon.injected_polygons.clear()
				svg_children.append(write_polygon)
				write_polygon.name = str(name, "_Child", svg_children.size())
				add_child(write_polygon)
				write_polygon.owner = owner
				#print(write_polygon.get_parent())

			var new_polygon = PackedVector2Array()
			var coords_size = coordinates.size()
			#print("coord count ", coords_size)
			for c_i in coords_size:
				new_polygon.append(Vector2(coordinates[c_i].x, coordinates[c_i].y))
			write_polygon.polygon = new_polygon
			#write_polygon = null
			coordinates.clear()
			full_coord_idx = 0

	for i in range(svg_children.size(), -1 -1):
		if svg_children[i] == null:
			svg_children.remove_at(i)

# TODO move this to PolygonSVG plugin
func save_svg():
	if Engine.is_editor_hint() && svg != null:
		var in_svg_file = FileAccess.open(svg.resource_path, FileAccess.READ)
		print("save svg from ", svg.resource_path)
		if in_svg_file.get_error() != OK:
			print("Failed to load ", svg.resource_path, " with code ", in_svg_file.get_error())
		var svg_text = in_svg_file.get_as_text()
		in_svg_file.close()

		var start_idx = 0
		while start_idx >= 0:
			var path_open_idx = svg_text.find("<path", max(start_idx - 1, 0))
			if path_open_idx < 0:
				break
			var path_close_idx = svg_text.find("/>", path_open_idx)
			if path_close_idx >= 0:
				path_close_idx += 2
			else:
				path_close_idx = svg_text.find("</path>", path_open_idx)
				if path_close_idx >= 0:
					path_close_idx += 7

			if path_close_idx >= 0:
				# TODO (sam) There is probably a better way to slice up the string.
				svg_text = str(svg_text.substr(0, path_open_idx), svg_text.substr(path_close_idx).strip_edges())
			start_idx = path_open_idx
			
		var add_path_idx = start_idx
		var poly_string = _stringify_polygon(self)
		svg_text = str(svg_text.substr(0, add_path_idx), poly_string, svg_text.substr(add_path_idx))
		add_path_idx += poly_string.length()
		for poly_child in svg_children:
			if poly_child != null:
				poly_string = _stringify_polygon(poly_child)
				svg_text = str(svg_text.substr(0, add_path_idx), poly_string, svg_text.substr(add_path_idx))
				add_path_idx += poly_string.length()

		var old_svg_path = svg.resource_path
		#var old_svg_path = svg.resource_path.substr(0, svg.resource_path.length() - 4) + "_new.svg"
		var out_svg_file = FileAccess.open(old_svg_path, FileAccess.WRITE)
		print("to ", old_svg_path)
		if out_svg_file.get_error() != OK:
			print("Failed to save ", svg.resource_path, " with code ", out_svg_file.get_error())
		out_svg_file.store_string(svg_text)
		out_svg_file.close()

func _stringify_polygon(poly:Polygon2D) -> String:
	if poly.polygon.size() < 1:
		return ""
	else:
		var output = "<path d=\""
		output += str("M", poly.polygon[0].x, " ", poly.polygon[0].y)
		for i in range(1, poly.polygon.size() + 1, 1):
			var vert = poly.polygon[i % poly.polygon.size()]
			var prev = poly.polygon[(i - 1) % poly.polygon.size()]
			if vert == prev:
				continue
			elif vert.x == prev.x:
				output += str("V", vert.y)
			elif vert.y == prev.y:
				output += str("H", vert.x)
			else:
				output += str("L", vert.x, " ", vert.y)
		output += "\" stroke=\"#0038FF\" stroke-width=\"4\"/>\n"
		return output

class PathCoordinate:
	enum ToType { Move, Line, Curve, Horizontal, Vertical }
	var to_type:ToType
	var x:float
	var y:float
