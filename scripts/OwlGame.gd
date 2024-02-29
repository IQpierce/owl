extends Node2D
class_name OwlGame

@export var muted:bool:
	set(v):
		muted = v
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)

@export var emulate_phosphor_monitor:bool = true
@export var draw_line_thickness  = 0.5
@export var draw_point_thickness = 0.45

static var instance

var zooming:bool = false

var scene:OwlScene:
	get:
		if scene == null:
			var scene_parent = get_tree().get_root()
			for child in scene_parent.get_children():
				if child is OwlScene:
					scene = child
		return scene

func _ready():
	instance = self
	Engine.max_fps = 60
	muted = false

func _process(delta:float):
	if Input.is_action_just_pressed("toggle_mute"):
		muted = !muted

func world_camera() -> CameraRig:
	if instance.scene != null:
		return instance.scene.world_camera
	return null

func anti_zoom() -> float:
	var scene = instance.scene
	if scene != null && scene.world_camera != null:
		if scene.world_camera.zoom.x != 0 && scene.world_camera.zoom.y != 0:
			return scene.world_camera.anti_zoom()
	return 1

func beyond_screen(global_pos:Vector2) -> Vector2:
	var scene = instance.scene
	var beyond = Vector2.ZERO
	if scene != null && scene.world_camera != null:
		beyond = abs(global_pos - scene.world_camera.global_position) - (scene.world_camera.view_size() / 2)
		if beyond.x > 0:
			beyond.x *= -1 if global_pos.x < scene.world_camera.global_position.x else 1
		else:
			beyond.x = 0
		if beyond.y > 0:
			beyond.y *= -1 if global_pos.y < scene.world_camera.global_position.y else 1
		else:
			beyond.y = 0
	return beyond
