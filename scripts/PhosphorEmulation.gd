extends Node2D

class_name PhosphorEmulation

@export var post_process:WorldEnvironment = null
## Expected parent of scene components when loaded dynamically. This is most likely the innermost viewport.
@export var injection_viewport:SubViewport
## All the viewport containers that need to be synchronized with the game window and camera(s)
@export var viewport_containers:Array[SubViewportContainer]

@onready var hum = $Hum

#TODO (sam) expose all values Ben wants here, and just update in editor

func _ready():
	if !OwlGame.instance.emulate_phosphor_monitor || ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility":
		if post_process != null:
			post_process.queue_free()
		if injection_viewport != null:
			injection_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS

	var disable_env = RenderingServer.ViewportEnvironmentMode.VIEWPORT_ENVIRONMENT_DISABLED
	if injection_viewport != null:
		RenderingServer.viewport_set_environment_mode(injection_viewport.get_viewport_rid(), disable_env)
	
	var hum_fade:Tween = create_tween();
	hum_fade.tween_property(hum, "volume_db", -17.826, .2).from(-80)




