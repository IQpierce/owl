extends SeekerBrain

class_name ResourceSeekerBrain

@export var target_resource_type:GameEnums.ResourceType


func get_body_relevance(body:CollisionObject2D) -> float:
	if body.has_method("get_resource_units_contained"):
		return body.get_resource_units_contained(target_resource_type)
	
	return 0
	


