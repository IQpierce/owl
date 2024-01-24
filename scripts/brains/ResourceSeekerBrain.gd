extends Brain

class_name ResourceSeekerBrain

@export var target_resource_type:GameEnums.ResourceType

signal on_new_target_body_chosen(body:CollisionObject2D)
signal on_new_target_location_chosen(world_location:Vector2)
signal on_new_target_velocity_chosen(relative_velocity:Vector2)

# Keys are float values indicating the amount of resource sought (used to 
#  prioritize). Values are Array[CollisionObject2D]'s for all valid targets 
#  containing that amount of the target resource.
#  NOTE that this is dependent on the assumption that the # of resources in a 
#  target never changes after we cache it in this dictionary!!!
var relevant_targets:Dictionary		

func think():
	
	var most_resource_units_seen:float = NAN
	var most_relevant_targets:Array[CollisionObject2D]
	for resource_units in relevant_targets:
		if is_nan(most_resource_units_seen) || resource_units > most_resource_units_seen:
			most_resource_units_seen = resource_units
			most_relevant_targets = relevant_targets[resource_units]
	
	if most_relevant_targets != null && most_relevant_targets.size() > 0:
		# @TODO: Some kind of randomness?
		var most_relevant_target:CollisionObject2D = most_relevant_targets[0]
		assert(most_relevant_target != null)
		
		on_new_target_body_chosen.emit(most_relevant_target)
		on_new_target_location_chosen.emit(most_relevant_target.global_position)
		
		var relative_velocity_to_target:Vector2 = most_relevant_target.global_position - controlled_creature.global_position
		on_new_target_velocity_chosen.emit(relative_velocity_to_target)
		return
	
	# if we get here, there were no relevant targts	
	on_new_target_body_chosen.emit(null)
	on_new_target_location_chosen.emit(controlled_creature.global_position)
	on_new_target_velocity_chosen.emit(Vector2.ZERO)

func on_body_enters_awareness(body:CollisionObject2D):
	if body.has_method("get_resource_units_contained") && \
		body.get_resource_units_contained(target_resource_type) > 0:
			add_relevant_target(body)

func on_body_exits_awareness(body:CollisionObject2D):
	if body.has_method("get_resource_units_contained") && \
		body.get_resource_units_contained(target_resource_type) > 0:
			remove_relevant_target(body)

func add_relevant_target(new_target:CollisionObject2D):
	assert(new_target.has_method("get_resource_units_contained"))
	
	var resource_units:float = new_target.get_resource_units_contained(target_resource_type)
	
	if (resource_units <= 0):
		push_warning("Ignoring empty resource: ", new_target)
		return
	
	if !relevant_targets.has(resource_units):
		relevant_targets[resource_units] = [ new_target ] as Array[CollisionObject2D]
	else:
		relevant_targets[resource_units].append(new_target)

func remove_relevant_target(removing_target:CollisionObject2D):
	assert(removing_target.has_method("get_resource_units_contained"))
	
	var resource_units:float = removing_target.get_resource_units_contained(target_resource_type)
	
	if !relevant_targets.has(resource_units):
		push_error("Could not find target ", removing_target, " in the relevant list of relevancies")
		return
	
	var relevant_targets_array:Array[CollisionObject2D] = relevant_targets[resource_units]
	assert(relevant_targets_array.size() > 0)
	relevant_targets_array.erase(removing_target)
	

