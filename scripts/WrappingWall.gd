extends Area2D

@export var teleport_translation := Vector2(0,0)
var camera:Camera_Deprecated

func _ready():
	var scene = OwlGame.instance.scene
	if scene != null:
		camera = scene.world_camera

func on_body_entered(body:Node2D):
	var physics_body:PhysicsBody2D = body as PhysicsBody2D
	if (physics_body):
		assert(!teleport_translation.is_zero_approx())
		physics_body.global_position += teleport_translation
		if camera != null && camera.get_prey() == body:
			camera.global_position += teleport_translation 
		


