extends Thing

class_name Asteroid

# Keys are ResourceType's, values are relevance for seeker brains.
@export var resource_container_nibbleable_relevance:Dictionary


func spawns_resource_containers_when_nibbled(resource_type:GameEnums.ResourceType) -> float:
	if resource_container_nibbleable_relevance.has(resource_type):
		return resource_container_nibbleable_relevance[resource_type]
	
	return 0
