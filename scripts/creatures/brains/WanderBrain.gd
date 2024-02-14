extends Brain

class_name WanderBrain

# When this brain thinks, it picks a new random point, given some constraints.

@export var min_dist_to_pick:float = 40
@export var max_dist_to_pick:float = 100
@export var locations_to_avoid:Array[Vector2]
@export_range(0, 1) var urgency:float
@export_range(-.5, 1) var avoidance_threshhold:float = 0	# Used for dot product comparison. The higher this is, the more tolerant we'll be of "moving towards" the locations_to_avoid.
@export var hack_max_velocity:float = 9000

var reference_node:Node2D

func _ready():
	
	super()
	
	reference_node = Node2D.new()
	add_child(reference_node)

func think():
	
	var target_world_location:Vector2 = Vector2.INF
	
	var MAX_TRIES:int = 500
	var num_tries:int = 0
	
	while !is_target_world_location_valid(target_world_location) \
		&& num_tries < MAX_TRIES:
			# @TODO: Support picking a random location within a zone, or set of zones...?
			target_world_location = controlled_creature.global_position + (Randomness.random_on_unit_circle() * randf_range(min_dist_to_pick, max_dist_to_pick))
			num_tries += 1
	
	if num_tries == MAX_TRIES:
		push_error(self, " could not find a wander position!")
		return
	
	on_target_location_changed.emit(target_world_location)
	
	# @TODO: Clean up this hack by properly abstracting out the "I want to go to there" intent from the "how fast/urgently should I be traversing there?" question.
	var target_velo:Vector2 = (target_world_location - controlled_creature.global_position).normalized() * urgency * hack_max_velocity
	on_target_velocity_changed.emit(target_velo)
	

func is_target_world_location_valid(target_location:Vector2) -> bool:
	if target_location.is_equal_approx(Vector2.INF):
		return false
	
	var target_delta:Vector2 = target_location - controlled_creature.global_position
	
	var delta_len_sqr:float = target_delta.length_squared()
	if delta_len_sqr > max_dist_to_pick * max_dist_to_pick || \
		delta_len_sqr < min_dist_to_pick * min_dist_to_pick:
		return false
	
	for location_to_avoid in locations_to_avoid:
		var avoidance_direction = location_to_avoid - controlled_creature.global_position
		if avoidance_direction.dot(target_delta) > avoidance_threshhold:
			return false
			
	# @TODO: Check that location is actually clear and reachable...?!
	
	return true
