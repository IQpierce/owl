extends Thing

class_name Creature


signal on_consumed_pickup(consumed_pickup:Pickup)

func can_consume_pickup(pickup:Pickup) -> bool:
	return true

func consume_pickup(pickup:Pickup) -> bool:
	if (!can_consume_pickup(pickup)):
		return false
	
	on_consumed_pickup.emit(pickup)
	return true

