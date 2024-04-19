extends Brain

class_name SeekerBrain

var last_seeked_target:CollisionObject2D = null
var last_seeked_position:Vector2 = global_position

@export var debug_seek:bool = false

signal on_target_body_changed(body:CollisionObject2D)

signal on_seek_failure()


# Keys are float values indicating an amount of relevance (used to 
#  prioritize). Values are Array[CollisionObject2D]'s of all valid targets 
#  which share that level of relevance.
#  NOTE that this is dependent on the assumption that the calculation of a target's 
#  relevance never changes after we cache it in this dictionary!!!
var relevant_targets:Dictionary		

func _process(delta:float):
	if debug_seek:
		queue_redraw()
	#print("      ", name, last_seeked_target)

func think():
	process_seek_result(seek())
	
func process_seek_result(most_relevant_target:CollisionObject2D, quick_process = false):
	var seek_pos = last_seeked_position
	#print(name, ": ", most_relevant_target, " | ", last_seeked_target, " | ", last_seeked_position)
	if most_relevant_target == null:
		if last_seeked_target != null:
			# TODO (sam) Considering dt here would be nice but we don't have access to it.
			var seek_dist_sqr = (seek_pos - controlled_creature.global_position).length_squared()
			if seek_dist_sqr > controlled_creature.linear_velocity.length_squared() / 10:
				most_relevant_target = last_seeked_target
			else:
				last_seeked_target = null
	else:
		seek_pos = most_relevant_target.global_position
		last_seeked_target = most_relevant_target
		last_seeked_position = last_seeked_target.global_position

	if most_relevant_target != null:
		if true:#!quick_process:
			on_target_body_changed.emit(most_relevant_target)

		on_target_location_changed.emit(seek_pos)
		
		var relative_velocity_to_target:Vector2 = seek_pos - controlled_creature.global_position

		# TODO (sam) I really wish I could get the actual positioning I'm turning towards
		on_target_velocity_changed.emit(relative_velocity_to_target)
	else:
		if !quick_process:
			on_seek_failure.emit()
			
			# @TODO: Should these lines still exist? They should really be consequences of failure
			on_target_body_changed.emit(null)
			on_target_location_changed.emit(controlled_creature.global_position)
			on_target_velocity_changed.emit(Vector2.ZERO)

# @returns the most relevant target, if any relevant targets exist at all.
func seek() -> CollisionObject2D:
	var most_relevance_seen:float = NAN
	var most_relevant_targets:Array[CollisionObject2D]
	
	# @TODO: This could be optimized, probably by "remembering" the highest relevance
	for relevance_value in relevant_targets:
		if is_nan(most_relevance_seen) || relevance_value > most_relevance_seen:
			most_relevance_seen = relevance_value
			most_relevant_targets = relevant_targets[relevance_value]
	
	if most_relevant_targets != null && most_relevant_targets.size() > 0:
		var nearest_dist:float = NAN
		var nearest_relevant_target:CollisionObject2D = null
		for relevant_target in most_relevant_targets:
			assert(relevant_target != null)
			var dist:float = (relevant_target.global_position - controlled_creature.global_position).length_squared()
			if (is_nan(nearest_dist) || dist < nearest_dist) && is_body_detectable(relevant_target):
				nearest_dist = dist
				nearest_relevant_target = relevant_target
		
		#assert(nearest_relevant_target != null)
		
		return nearest_relevant_target
	
	return null

func is_body_relevant(body:CollisionObject2D):
	return get_body_relevance(body) > 0

func is_body_detectable(body:CollisionObject2D) -> bool:
	if body != null:
		var space_state = get_world_2d().direct_space_state
		var raycast = PhysicsRayQueryParameters2D.create(controlled_creature.global_position, body.global_position)
		var hit = space_state.intersect_ray(raycast)
		# TODO (sam) We might need a way to check if the hit is a "child" body of the body we want
		if hit.has("collider"):
			return hit["collider"] == body
	return false

func on_body_enters_awareness(body:CollisionObject2D):
	if body == controlled_creature:
		return
	
	var relevance:float = get_body_relevance(body)
	if relevance > 0:
		add_relevant_target(body, relevance)

func on_body_exits_awareness(body:CollisionObject2D):
	if body == controlled_creature:
		return
	
	var relevance:float = get_body_relevance(body)
	if relevance > 0:
		remove_relevant_target(body, relevance)

func add_relevant_target(new_target:CollisionObject2D, relevance:float):
	assert(is_body_relevant(new_target))
	
	if (relevance <= 0):
		push_warning("Ignoring empty target: ", new_target)
		return
	
	if !relevant_targets.has(relevance):
		relevant_targets[relevance] = [ new_target ] as Array[CollisionObject2D]
	else:
		relevant_targets[relevance].append(new_target)

func remove_relevant_target(removing_target:CollisionObject2D, relevance:float):
	assert(is_body_relevant(removing_target))
	
	if !relevant_targets.has(relevance):
		push_error("Could not find target ", removing_target, " in the relevant list of relevancies")
		return
	
	var relevant_targets_array:Array[CollisionObject2D] = relevant_targets[relevance]
	assert(relevant_targets_array.size() > 0)
	relevant_targets_array.erase(removing_target)
	

func get_body_relevance(body:CollisionObject2D) -> float:
	assert(false, "pure virtual function - must override!")
	return 0
	
func _draw():
	if debug_seek:
		if last_seeked_target != null:
			draw_line(Vector2.ZERO, to_local(last_seeked_position), OwlGame.instance.draw_point_color)
			draw_dashed_line(to_local(last_seeked_position), to_local(last_seeked_target.global_position), OwlGame.instance.draw_point_color)
		
