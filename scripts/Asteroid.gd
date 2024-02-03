extends Thing

class_name Asteroid

# Keys are ConsumablefType's, values are relevance for seeker brains.
@export var consumable_reservoir_nibbleable_relevance:Dictionary

func _ready():
	super()
	# Sam 1-31-24: When we spawn mini-asteroids, they sometimes spawn on top of each other, which cause physics system to
	# fall over and spam errors about get_supports. Disallowing collisions on their own layer for a couple frames appears
	# to prevent the issue; probably an initialization order thing.
	var real_collision_mask = collision_mask
	collision_mask = collision_mask & ~collision_layer
	await get_tree().physics_frame
	await get_tree().physics_frame
	collision_mask = real_collision_mask

func spawns_consumable_pickups_when_nibbled(consumable_type:GameEnums.ConsumableType) -> float:
	if consumable_reservoir_nibbleable_relevance.has(consumable_type):
		return consumable_reservoir_nibbleable_relevance[consumable_type]
	
	return 0
