extends Node2D

class_name PhosphorEmulation

## Expected parent of scene components when loaded dynamically. This is most likely the innermost viewport.
@export var injection_viewport:SubViewport
## All the viewport containers that need to be synchronized with the game window and camera(s)
@export var viewport_containers: Array[SubViewportContainer]

@onready var hum = $Hum

#TODO (sam) expose all values Ben wants here, and just update in editor

func _ready():
	if injection_viewport != null:
		var disable_env = RenderingServer.ViewportEnvironmentMode.VIEWPORT_ENVIRONMENT_DISABLED
		RenderingServer.viewport_set_environment_mode(injection_viewport.get_viewport_rid(), disable_env)
	
	var hum_fade:Tween = create_tween();
	hum_fade.tween_property(hum, "volume_db", -17.826, .2).from(-80)




