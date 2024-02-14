extends Node2D
class_name Anatomy2D

enum ScaleMode { LineWidth, Transform }

@export var scale_mode:ScaleMode = ScaleMode.LineWidth
@export var collider:CollisionPolygon2D = null
@export var line_geometry:Array[VectorPolygonRendering]

var initial_scale:Vector2 = Vector2.ONE
var collider_scale_relative:Vector2 = Vector2.ONE
var camera_rig:CameraRig = null

func _ready():
	initial_scale = scale
	if collider != null:
		collider_scale_relative = collider.scale / scale

	var scene = OwlGame.instance.scene
	if scene != null:
		camera_rig = scene.world_camera as CameraRig

func _process(delta:float):
	if OwlGame.instance.zooming:
		counter_zoom()

#func _physics_process(delta:float):
#	if OwlGame.instance.zooming:
#		counter_zoom()

func counter_zoom():
	var anti_zoom = OwlGame.instance.anti_zoom()
	if scale_mode == ScaleMode.LineWidth:
		if line_geometry != null:
			for geom in line_geometry:
				if geom != null:
					geom.point_draw_radius = geom.initial_point_radius * anti_zoom
					geom.draw_line_width = geom.initial_line_width * anti_zoom
					geom.queue_redraw()
	elif scale_mode == ScaleMode.Transform:
		scale = initial_scale * anti_zoom
		if collider != null:
			collider.scale = scale * collider_scale_relative
