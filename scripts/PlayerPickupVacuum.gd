extends Area2D

class_name PlayerPickupVacuum


func _on_body_entered(body:RigidBody2D):
	# pickups that have "fallen asleep" won't be affected by our gravity well... 
	# wake them up!
	body.sleeping = false
	body.freeze = false
