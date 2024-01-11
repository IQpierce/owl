extends Area2D

class_name Sun


func _on_body_entered(body:RigidBody2D):
	var body_thing:Thing = body as Thing
	if body_thing:
		body_thing.die()
	else:
		body.queue_free()
