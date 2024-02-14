extends SeekerBrain

class_name ConsumableSeekerBrain

@export var target_consumable_type:GameEnums.ConsumableType


func get_body_relevance(body:CollisionObject2D) -> float:
	if body.has_method("get_consumable_units_contained"):
		return body.get_consumable_units_contained(target_consumable_type)
	
	return 0
	


