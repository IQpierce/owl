@tool

extends Node2D
class_name Tool_PhosphorEmulation

enum DataDirection { NONE, TO_NODES, FROM_NODES }

@export var data_direction:DataDirection
@export_group("World Environment")
@export var world_env:WorldEnvironment
@export_range(0.0, 8) var glow_intensity:float
@export_range(0.0, 2) var glow_strength:float
@export_range(0.0, 1) var glow_bloom:float
@export_group("ColorRect - Post Processing")
@export var cr_post_processing:ColorRect
@export_range(0.0, 1) var trails_post_processing:float
@export_group("ColorRect - Never Clear")
@export var cr_never_clear:ColorRect
@export_range(0.0, 1) var trails_never_clear:float
@export_group("")

func _process(delta):
	if data_direction == DataDirection.TO_NODES:
		if world_env != null:
			world_env.environment.glow_intensity = glow_intensity
			world_env.environment.glow_strength = glow_strength
			world_env.environment.glow_bloom = glow_bloom
		if cr_post_processing != null:
			cr_post_processing.material.set_shader_parameter("Trails", trails_post_processing)
		if cr_never_clear != null:
			cr_never_clear.material.set_shader_parameter("Trails", trails_never_clear)
	elif data_direction == DataDirection.FROM_NODES:
		if world_env != null:
			glow_intensity = world_env.environment.glow_intensity
			glow_strength = world_env.environment.glow_strength
			glow_bloom = world_env.environment.glow_bloom
		if cr_post_processing != null:
			trails_post_processing = cr_post_processing.material.get_shader_parameter("Trails")
		if cr_never_clear != null:
			trails_never_clear = cr_never_clear.material.get_shader_parameter("Trails")

	
