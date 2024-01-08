extends RigidBody2D

class_name Pickup

func on_picked_up(picker_upper:Node) -> void:
	queue_free()

