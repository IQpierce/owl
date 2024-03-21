extends Creature

# TODO (sam) This is no good, we just need a simple way to stop mosquitos from attacking each other
func get_consumable_units_contained(check_type:GameEnums.ConsumableType) -> float:
	return 0
