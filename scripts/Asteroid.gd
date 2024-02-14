extends Thing

class_name Asteroid

# Keys are ConsumablefType's, values are relevance for seeker brains.
@export var consumable_reservoir_nibbleable_relevance:Dictionary

@export_category("Thing Roosting Inside")

@export_flags_2d_physics var collision_for_roosting_thing:int = 0

@export var creature_roosting_inside:Creature:
	get:
		return creature_roosting_inside
	set(new_creature):
		if new_creature != null:
			assert(creature_roosting_inside == null)
			creature_roosting_inside = new_creature
			
			creature_roosting_inside.freeze = true
			
			assert(saved_collision_for_roosting_thing == -1)
			saved_collision_for_roosting_thing = creature_roosting_inside.collision_layer
			creature_roosting_inside.collision_layer = collision_for_roosting_thing
			
			on_creature_started_roosting_inside.emit(creature_roosting_inside)
		else:
			var creature_getting_ejected:Creature = creature_roosting_inside
			assert(creature_getting_ejected != null)
			creature_roosting_inside = null
			
			creature_getting_ejected.freeze = false
			
			assert(saved_collision_for_roosting_thing != -1)
			creature_getting_ejected.collision_layer = saved_collision_for_roosting_thing
			saved_collision_for_roosting_thing = -1
			
			# @TODO give it some random velocity...?!	
			
			on_creature_stopped_roosting_inside.emit(creature_getting_ejected)

signal on_creature_started_roosting_inside(roosting_creature:Creature)
signal on_creature_stopped_roosting_inside(ejected_creature:Creature)

var saved_collision_for_roosting_thing:int = -1

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

func die(utterly:bool = false):
	if creature_roosting_inside != null:
		var ejection_parent:Node2D = get_parent()
		if ejection_parent == null:
			ejection_parent = get_tree().current_scene
		assert(ejection_parent != null)
		creature_roosting_inside.reparent(ejection_parent)
		
		creature_roosting_inside = null
	
	super(utterly)
