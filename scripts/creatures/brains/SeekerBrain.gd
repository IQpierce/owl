extends Brain

class_name SeekerBrain


signal on_target_body_changed(body:CollisionObject2D)

signal on_seek_failure()


# Keys are float values indicating an amount of relevance (used to 
#  prioritize). Values are Array[CollisionObject2D]'s of all valid targets 
#  which share that level of relevance.
#  NOTE that this is dependent on the assumption that the calculation of a target's 
#  relevance never changes after we cache it in this dictionary!!!
var relevant_targets:Dictionary		

func think():
	process_seek_result(seek())
	
func process_seek_result(most_relevant_target:CollisionObject2D):
	if most_relevant_target != null:
		on_target_body_changed.emit(most_relevant_target)
		on_target_location_changed.emit(most_relevant_target.global_position)
		
		var relative_velocity_to_target:Vector2 = most_relevant_target.global_position - controlled_creature.global_position

		# TODO (sam) I really wish I could get the actual positioning I'm turning towards
		on_target_velocity_changed.emit(relative_velocity_to_target)
	else:
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
		var nearest_relevant_target:CollisionObject2D
		for relevant_target in most_relevant_targets:
			assert(relevant_target != null)
			var dist:float = (relevant_target.global_position - controlled_creature.global_position).length_squared()
			if is_nan(nearest_dist) || dist < nearest_dist:
				nearest_dist = dist
				nearest_relevant_target = relevant_target
		
		assert(nearest_relevant_target != null)
		
		return nearest_relevant_target
	
	return null

func is_body_relevant(body:CollisionObject2D):
	return get_body_relevance(body) > 0

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
	

