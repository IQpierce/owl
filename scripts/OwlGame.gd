extends Node2D
class_name OwlGame

@export var muted:bool:
	set(v):
		muted = v
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)

@export var emulate_phosphor_monitor:bool = true
@export var draw_line_thickness  = 1#0.5
@export var draw_point_thickness = 0.45
#could we render fills FIRST as a normal material then render lines with against the stencil... will this cause lines to never render under their own color?... what if lines were just double thick?
@export var draw_line_color:Color  = Color(0.92, 0.00, 0.92)
@export var draw_point_color:Color = Color(1.00, 1.00, 1.00)
@export_group("Debug")
@export var draw_normals:int = 0
@export_group("")

enum LOD {
	Ignore = 0,
	Draw,
	ThinkSmall,
}

const _lod_distances:Array[float] = [
	INF,   # Ignore
	2000,  # Draw
	5000,  # Think Small
]

const MAX_LOD_STEPS:int = 100

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

# TODO (sam) Should we cache this value per-frame?
var can_occlude:bool:
	get:
		if scene != null && scene.occlusion_fills != null:
			return true
		return false

func _init():
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

static func within_lod_steps(node:Node2D, lod:LOD) -> int:
	var threshold = _lod_distances[lod]
	if node == null || threshold <= 0:
		return MAX_LOD_STEPS + 1
	if instance == null || instance.scene == null || instance.scene.world_camera == null:
		return 1
	var to_node = node.global_position - instance.scene.world_camera.global_position
	return (max(abs(to_node.x), abs(to_node.y)) / threshold ) as int + 1

static func in_first_lod(node:Node2D, lod:LOD) -> bool:
	return within_lod_steps(node, lod) == 1
