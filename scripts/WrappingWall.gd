extends Area2D

@export var teleport_translation := Vector2(0,0)

func on_body_entered(body:Node2D):
	var physics_body:PhysicsBody2D = body as PhysicsBody2D
	if (physics_body):
		assert(!teleport_translation.is_zero_approx())
		physics_body.global_position += teleport_translation
		#TODO (sam) add alternative and later replace: if physics_body = world_camera.prey (or call it vip)
		var player = physics_body as Player
		if player && player.camera:
			player.camera.global_position += teleport_translation
		


