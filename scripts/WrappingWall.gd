extends Area2D

@export var teleport_translation := Vector2(0,0)

func on_body_entered(body:Node2D):
	var physics_body:PhysicsBody2D = body as PhysicsBody2D
	if (physics_body):
		assert(!teleport_translation.is_zero_approx())
		physics_body.global_position += teleport_translation
		var player = physics_body as Player
		if player:
			player.camera.global_position += teleport_translation
		


