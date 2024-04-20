extends Creature

@export var seeker:SeekerBrain = null
@export var proboscis:DamageZone = null

func _process(delta:float):
	super._process(delta)
	if seeker != null && proboscis != null:
		if proboscis.exclusive_damagees.size() != 1:
			proboscis.exclusive_damagees.clear()
			proboscis.exclusive_damagees.append(null)
		proboscis.exclusive_damagees[0] = seeker.last_seeked_target

# TODO (sam) This is no good, we just need a simple way to stop mosquitos from attacking each other
func get_consumable_units_contained(check_type:GameEnums.ConsumableType) -> float:
	return 0
