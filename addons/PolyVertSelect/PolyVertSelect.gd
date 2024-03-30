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
var select_start:Vector2 = Vector2(-1, -1)
var mouse_pos:Vector2 = Vector2.ZERO

const SELECT_RADIUS = 20

func _enter_tree():
	get_editor_interface().get_selection().selection_changed.connect(_on_selection_changed)

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
			shift_down = key_event.pressed && alt_down
			event_consumed = alt_down
		# TODO (sam) this should just be done through undo-redo
		if key_event.keycode == Key.KEY_P && key_event.pressed && alt_down && was_poly != null:
			var selection = get_editor_interface().get_selection()
			selection.clear()
			selection.add_node(was_poly)
			verts.clear()
			for vert in was_verts:
				verts.append(vert)
	
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
	
	print(min_pos, " ", max_pos, " ", verts)
		
