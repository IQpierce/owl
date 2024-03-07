extends Thing

class_name Creature


signal on_consumed_pickup(consumed_pickup:Pickup)

func can_consume_pickup(pickup:Pickup) -> bool:
	return true

func consume_pickup(pickup:Pickup) -> bool:
	if (!can_consume_pickup(pickup)):
		return false
	
	_apply_pickup(pickup)
	on_consumed_pickup.emit(pickup)
	return true

func _apply_pickup(pickup:Pickup):
	pass
	
func get_consumable_units_contained(check_type:GameEnums.ConsumableType) -> float:
	if check_type == GameEnums.ConsumableType.Meat:
		return mass
	
	return 0

