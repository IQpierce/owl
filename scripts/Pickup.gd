extends RigidBody2D

class_name Pickup

@export var resource_type:GameEnums.ResourceType
@export var resource_units:float = 0

func on_picked_up(picker_upper:Node) -> void:
	queue_free()

func get_resource_units_contained(check_type:GameEnums.ResourceType) -> float:
	if resource_type == check_type:
		return resource_units
	else:
		return 0
