extends Area2D

class_name DestructionZone

# NOTE: Destroys utterly!

signal on_destroyed_thing(destroyed_thing:Thing)
signal on_destroyed_body(destroyed_body:RigidBody2D)

func _on_body_entered(body:RigidBody2D):
	var body_thing:Thing = body as Thing
	if body_thing:
		body_thing.die(true)
		on_destroyed_thing.emit(body_thing)
	else:
		body.queue_free()
		on_destroyed_body.emit(body)
