@tool
extends EditorPlugin

# TODO (maybe a different tool, graft polygons together (alt-g), and hack them apart (alt-h)

#var undo_redo:EditorUndoRedoManager = EditorUndoRedoManager.new()
var poly:Polygon2D = null
var was_poly:Polygon2D = null
var verts:PackedInt32Array
var was_verts:PackedInt32Array
var clicked_vert:int = -1
var hovered_vert:int = -1
var mouse_down:bool = false
var alt_down:bool = false
var shift_down:bool = false
var grafting:bool = false
var select_start:Vector2 = Vector2(-1, -1)
var mouse_pos:Vector2 = Vector2.ZERO
var graft_steps:Array[GraftStep]
var undo_redo:EditorUndoRedoManager

const SELECT_RADIUS = 20

func _enter_tree():
	get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)
	undo_redo = self.get_undo_redo()

func _exit_tree():
	get_editor_interface().get_selection().selection_changed.disconnect(_on_selection_changed)

func _on_selection_changed():
	if poly != null:
		was_poly = poly

	var selection = get_editor_interface().get_selection().get_selected_nodes()
	poly = null
	if selection.size() > 0:
		poly = selection[0] as Polygon2D

func _handles(object:Object) -> bool:
	# NOTE (sam) We could only handle Polygon2D if we can lose the "return to previous polygon" quality of life
	return true

func _edit(object:Object):
	pass

func _forward_canvas_draw_over_viewport(control:Control):
	if _any_select():
		var x_corner = Vector2(mouse_pos.x, select_start.y)
		var y_corner = Vector2(select_start.x, mouse_pos.y)
		control.draw_line(select_start, x_corner, Color.WHITE, -1)
		control.draw_line(select_start, y_corner, Color.WHITE, -1)
		control.draw_line(mouse_pos, x_corner, Color.WHITE, -1)
		control.draw_line(mouse_pos, y_corner, Color.WHITE, -1)

	if hovered_vert != null:
		control.draw_circle(_vert_in_viewport(hovered_vert), SELECT_RADIUS, Color.BLACK)

	for vert in verts:
		control.draw_circle(_vert_in_viewport(vert), SELECT_RADIUS, Color.WHITE)

func _forward_canvas_gui_input(event:InputEvent) -> bool:
	#print(event)
	var event_consumed = false
	var key_event = event as InputEventKey
	if key_event != null:
		if key_event.keycode == Key.KEY_ALT:
			alt_down = key_event.pressed
			event_consumed = true
			if !alt_down:
				# TODO (sam) Is this correct, or should verts be cleared when clicking nowhere?
				verts.clear()
		if key_event.keycode == Key.KEY_SHIFT:
			shift_down = key_event.pressed
			event_consumed = alt_down
		# TODO (sam) this should just be done through undo-redo
		if key_event.keycode == Key.KEY_F && key_event.pressed && alt_down && was_poly != null:
			var selection = get_editor_interface().get_selection()
			selection.clear()
			selection.add_node(was_poly)
			verts.clear()
			for vert in was_verts:
				verts.append(vert)
		# Reverse all vertices
		if key_event.keycode == Key.KEY_R && key_event.pressed && alt_down:
			_reverse_vertices(poly)
		# Wind in reverse order
		if key_event.keycode == Key.KEY_W && key_event.pressed && alt_down:
			_wind_vertices_backwards(poly)
		# Graft
		if key_event.keycode == Key.KEY_G && key_event.pressed && alt_down:
			var new_graft_step = GraftStep.new()
			var remove_sqr_dist = 1.0
			var selection = get_editor_interface().get_selection().get_selected_nodes()
			var base_poly = null
			var base_wind = Vector3(0, 0, 1)
			var ungrafted:Array[Polygon2D]
			for sel in selection:
				var graft_poly = sel as Polygon2D
				if graft_poly != null:
					if base_poly == null:
						base_poly = graft_poly
						new_graft_step.base_polygon = base_poly
						new_graft_step.base_vertices = base_poly.polygon
						if base_poly.polygon.size() > 2:
							var base_0 = Vector3(base_poly.polygon[0].x, base_poly.polygon[0].y, 0)
							var base_1 = Vector3(base_poly.polygon[1].x, base_poly.polygon[1].y, 0)
							var base_2 = Vector3(base_poly.polygon[2].x, base_poly.polygon[2].y, 0)
							base_wind = (base_1 - base_0).cross(base_2 - base_1)
							var sum_sqr_dist = 0
							for i in base_poly.polygon.size():
								sum_sqr_dist += (base_poly.polygon[(i + 1) % base_poly.polygon.size()] - base_poly.polygon[i]).length_squared()
							var avg_sqr_dist = sum_sqr_dist / base_poly.polygon.size()
							remove_sqr_dist = pow(sqrt(avg_sqr_dist) / 100, 2)
					ungrafted.append(graft_poly)

			while base_poly != null && ungrafted.size() > 1:
				var graft_idx = 1
				# TODO (sam) If holding shift ... find the nearest vert to the ending vert and pick that polygon, and order from that vert
				if shift_down:
					var base_end = base_poly.polygon[base_poly.polygon.size() - 1]
					var nearest_sqr_dist = (base_poly.polygon[0] - base_end).length_squared()
					var nearest_graft_i = 0
					var nearest_vert_i = 0
					for i in range(1, ungrafted.size(), 1):
						if ungrafted[i] != null:
							for j in ungrafted[i].polygon.size():
								var sqr_dist = (ungrafted[i].polygon[j] - base_end).length_squared()
								if sqr_dist < nearest_sqr_dist:
									nearest_sqr_dist = sqr_dist
									nearest_graft_i = i
									nearest_vert_i = j

					if nearest_sqr_dist > remove_sqr_dist:
						# TODO (sam) Are we ok with the assumption that doing doing this type of graft require polys to touch verts?
						break

					graft_idx = nearest_graft_i
					var new_graft_polygon = ungrafted[graft_idx].polygon
					for i in new_graft_polygon.size():
						new_graft_polygon[i] = ungrafted[graft_idx].polygon[(nearest_vert_i + i) % new_graft_polygon.size()]
					ungrafted[graft_idx].polygon = new_graft_polygon
				var graft_poly = ungrafted[graft_idx]
				if graft_poly == base_poly:
					# If our best polygon to graft is the one we started with, we are done and can ignore any stragglers.
					break
				ungrafted.remove_at(graft_idx)
				# TODO (sam) This assumes the polygons are all siblings with no children...
				# if you try to attach a parent to a child, Godot will not be happy
				if graft_poly != null:
					var new_polygon = base_poly.polygon
					var need_reorder = false
					if graft_poly.polygon.size() > 2:
						var graft_0 = Vector3(graft_poly.polygon[0].x, graft_poly.polygon[0].y, 0)
						var graft_1 = Vector3(graft_poly.polygon[1].x, graft_poly.polygon[1].y, 0)
						var graft_2 = Vector3(graft_poly.polygon[2].x, graft_poly.polygon[2].y, 0)
						var graft_wind = (graft_1 - graft_0).cross(graft_2 - graft_1)
						need_reorder = (base_wind.z < 0) != (graft_wind.z < 0)
					elif graft_poly.polygon.size() == 2:
						var to_graft_0 = (graft_poly.polygon[0] - base_poly.polygon[base_poly.polygon.size() - 1]).length_squared()
						var to_graft_1 = (graft_poly.polygon[1] - base_poly.polygon[base_poly.polygon.size() - 1]).length_squared()
						need_reorder = to_graft_1 < to_graft_0

					if need_reorder:
						_wind_vertices_backwards(graft_poly)

					#if new_polygon.size() > 1:
					#	var base_end = new_polygon[new_polygon.size() - 1] - new_polygon[new_polygon.size() - 2]
					#	var graft_start = graft_poly.polygon[0] - new_polygon[new_polygon.size() - 1]
					#	var connection_wind = Vector3(base_end.x, base_end.y, 0).cross(Vector3(graft_start.x, graft_start.y, 0))
					#	if (base_wind.z > 0) == (connection_wind.z > 0):
					#		new_polygon.remove_at(new_polygon.size() - 1)

					for vert in graft_poly.polygon:
						new_polygon.append(base_poly.to_local(graft_poly.to_global(vert)))

					base_poly.polygon = new_polygon
					# NOTE (sam) DO NOT call queue_free here, it will prevent future Saves.
					# Removing from tree and owner is sufficent to drop the uneeded polygon.
					new_graft_step.grafted_polygons.append(graft_poly)
					new_graft_step.grafted_parents.append(graft_poly.get_parent())
					new_graft_step.grafted_slots.append(graft_poly.get_index())
					new_graft_step.grafted_owners.append(graft_poly.owner)
					graft_steps.append(new_graft_step)
					graft_poly.get_parent().remove_child(graft_poly)
					graft_poly.owner = null

				# Merge extremely nearby vertices because they are likely just artifacts of grafting if base_poly != null && base_poly.polygon.size() > 2:
				var new_polygon = base_poly.polygon
				for i in range(new_polygon.size() - 1, 0, -1):
					if (new_polygon[i] - new_polygon[i - 1]).length_squared() < remove_sqr_dist:
						new_polygon.remove_at(i)
				if (new_polygon[new_polygon.size() - 1] - new_polygon[0]).length_squared() < remove_sqr_dist:
					new_polygon.remove_at(new_polygon.size() - 1)
				#var base_wrap = new_polygon[0] - new_polygon[new_polygon.size() - 1]
				#var base_start = new_polygon[1] - new_polygon[0]
				#var base_second = new_polygon[2] - new_polygon[1]
				#var wrap_wind = Vector3(base_wrap.x, base_wrap.y, 0).cross(Vector3(base_start.x, base_start.y, 0))
				#var real_wind = Vector3(base_start.x, base_start.y, 0).cross(Vector3(base_second.x, base_second.y, 0))
				#if (wrap_wind.z > 0) != (real_wind.z > 0):
				#	new_polygon.remove_at(new_polygon.size() - 1)
				base_poly.polygon = new_polygon

			undo_redo.create_action("Graft Polygons")
			undo_redo.add_undo_method(self, _undo_graft.get_method())
			undo_redo.commit_action()

		# Split
		if key_event.keycode == Key.KEY_S && key_event.pressed && alt_down:
			pass

	if poly != null:
		var mouse_button_event = event as InputEventMouseButton
		if mouse_button_event != null && mouse_button_event.button_index == 1:
			mouse_down = mouse_button_event.pressed && alt_down
			event_consumed = alt_down
			if mouse_down:
				select_start = event.position
				mouse_pos = select_start
				print(select_start, " ", poly.get_viewport_transform() * poly.to_global(poly.polygon[0]))
				var polygon_size = poly.polygon.size()
				clicked_vert = _vert_near_mouse()
				if clicked_vert >= 0:
					var clicked_vert_index = verts.find(clicked_vert)
					if clicked_vert_index < 0:
						verts.append(clicked_vert)
					else:
						verts.remove_at(clicked_vert_index)
					_cache_verts()
			else:
				select_start = Vector2(-1, -1)

		var mouse_motion_event = event as InputEventMouseMotion
		if mouse_motion_event != null:
			if alt_down:
				mouse_pos = event.position
				hovered_vert = _vert_near_mouse()
				if mouse_down && clicked_vert != -1:
					var verts_size = verts.size()
					for i in verts_size:
						poly.polygon[verts[i]] += poly.to_local(poly.get_viewport_transform().inverse() * event.relative)
						# TODO gotta add to undo stack when we stop dragging
				else:
					_group_select_verts()
			event_consumed = alt_down

	update_overlays()
	return event_consumed

func _vert_in_viewport(index:int) -> Vector2:
	if poly != null && index >= 0 && index < poly.polygon.size():
		return poly.get_viewport_transform() * poly.to_global(poly.polygon[index])
	return Vector2(-1, -1)

func _any_select() -> bool:
	return alt_down && poly != null && select_start.x >= 0 && select_start.y >= 0

func _cache_verts():
	if poly != null:
		was_poly = poly
		was_verts.clear()
		for vert in verts:
			was_verts.append(vert)

func _vert_near_mouse() -> int:
	var near_vert = -1
	if poly != null:
		var near_dist_sqr = INF
		var polygon_size = poly.polygon.size()
		var min_pos = Vector2(mouse_pos.x - SELECT_RADIUS, mouse_pos.y - SELECT_RADIUS)
		var max_pos = Vector2(mouse_pos.x + SELECT_RADIUS, mouse_pos.y + SELECT_RADIUS)
		for i in polygon_size:
			var vert_pos = _vert_in_viewport(i)
			if vert_pos.x >= min_pos.x && vert_pos.x <= max_pos.x && vert_pos.y >= min_pos.y && vert_pos.y <= max_pos.y:
				var dist_sqr = (vert_pos - mouse_pos).length_squared()
				if near_vert < 0 || dist_sqr < near_dist_sqr:
					near_vert = i
					near_dist_sqr = dist_sqr
	return near_vert

func _group_select_verts():
	if !_any_select():
		return

	var new_verts = PackedInt32Array()
	var lose_verts = PackedInt32Array()
	var polygon_size = poly.polygon.size()
	var min_pos = Vector2(min(select_start.x, mouse_pos.x), min(select_start.y, mouse_pos.y))
	var max_pos = Vector2(max(select_start.x, mouse_pos.x), max(select_start.y, mouse_pos.y))
	for i in polygon_size:
		var vert_pos = _vert_in_viewport(i)
		if vert_pos.x >= min_pos.x && vert_pos.x <= max_pos.x && vert_pos.y >= min_pos.y && vert_pos.y <= max_pos.y:
			if !verts.has(i):
				new_verts.append(i)
		else:
			if verts.has(i):
				lose_verts.append(i)

	if new_verts.size() > 0:
		_cache_verts()

	for vert in new_verts:
		verts.append(vert)

	for vert in lose_verts:
		verts.remove_at(verts.find(vert))

func _reverse_vertices(poly:Polygon2D):
	var new_polygon = poly.polygon
	new_polygon.reverse()
	poly.polygon = new_polygon

func _wind_vertices_backwards(poly:Polygon2D):
	var new_polygon = poly.polygon
	new_polygon.remove_at(0)
	new_polygon.reverse()
	new_polygon.insert(0, poly.polygon[0])
	poly.polygon = new_polygon

func _undo_graft():
	if graft_steps.size() > 0:
		var top_graft = graft_steps[graft_steps.size() - 1]
		graft_steps.remove_at(graft_steps.size() - 1)
		if top_graft.base_polygon != null:
			top_graft.base_polygon.polygon = top_graft.base_vertices
		for i in top_graft.grafted_polygons.size():
			if top_graft.grafted_polygons[i] != null:
				top_graft.grafted_parents[i].add_child(top_graft.grafted_polygons[i])
				top_graft.grafted_parents[i].move_child(top_graft.grafted_polygons[i], top_graft.grafted_slots[i])
				top_graft.grafted_polygons[i].owner = top_graft.grafted_owners[i]

class GraftStep:
	var base_polygon:Polygon2D
	var base_vertices:PackedVector2Array
	var grafted_polygons:Array[Polygon2D]
	var grafted_parents:Array[Node2D]
	var grafted_slots:PackedInt32Array
	var grafted_owners:Array[Node2D]
