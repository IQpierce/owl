extends Area2D

@export var teleport_translation := Vector2(0,0)
var camera:CameraRig
var jank_fighter:JankFighter

func _ready():
	var scene = OwlGame.instance.scene
	if scene != null:
		camera = scene.world_camera
		jank_fighter = scene.jank_fighter

func on_body_entered(body:Node2D):
	var physics_body:RigidBody2D = body as RigidBody2D
	if (physics_body):
		assert(!teleport_translation.is_zero_approx())
		if jank_fighter != null:
			jank_fighter.wipe_body_data(physics_body)
		physics_body.global_position += teleport_translation
		if camera != null && camera.get_prey() == body:
			camera.global_position += teleport_translation 
		


