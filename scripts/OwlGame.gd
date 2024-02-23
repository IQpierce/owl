extends Node2D
class_name OwlGame

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
