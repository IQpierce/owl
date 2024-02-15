extends Node2D
class_name Centerpiece

@export var priority:int = 1
@export var notice_radius = 2500
@export var peripheral_radius = 200

var camera:CameraRig

func _ready():
	var game = OwlGame.instance.scene
	if game != null:
		camera = game.world_camera

func _physics_process(float):
	if camera != null:
		if priority > 0 && (camera.global_position - global_position).length_squared() < notice_radius * notice_radius:
			var to_periphery = (camera.global_position - global_position).normalized() * peripheral_radius
			camera.pique_curiousity(global_position + to_periphery, priority)
