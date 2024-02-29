extends Node2D
class_name ScalingGroup2D

enum ScaleMode { LineWidth, Transform }

@export var scale_mode:ScaleMode = ScaleMode.LineWidth
@export var colliders:Array[CollisionPolygon2D]
@export var line_geometry:Array[VectorPolygonRendering]

var initial_scale:Vector2 = Vector2.ONE
var colliders_scale_relative:Array[Vector2]
var camera_rig:CameraRig = null

func _ready():
	initial_scale = scale
	for i in colliders.size():
		if colliders[i] != null:
			colliders_scale_relative.append(colliders[i].scale / scale)

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
					geom.zoom_scaling = anti_zoom
					geom.queue_redraw()
	elif scale_mode == ScaleMode.Transform:
		scale = initial_scale * anti_zoom
		for i in colliders.size():
			if colliders[i] != null:
				colliders[i].scale = scale * colliders_scale_relative[i]
