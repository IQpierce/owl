extends Area2D

#var speed = 400
#var angular_speed = PI
# srpnow 
#func _process(delta):

@export var teleport_translation := Vector2(0,0)

func on_body_entered(body:Node2D):
	var physics_body:PhysicsBody2D = body as PhysicsBody2D
	if (physics_body):
		assert(!teleport_translation.is_zero_approx())
		physics_body.global_position += teleport_translation
		


