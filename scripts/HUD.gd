extends CanvasLayer

@export var debug_fps_label:Label

func _ready():
	pass # Replace with function body.


func _process(delta):
	
	# TODO - This part is debug/cheat functionality...
	# ...should compile out of "real" builds!
	if Input.is_action_just_pressed("debug_toggle_fps_display"):
		debug_fps_label.visible = !debug_fps_label.visible
	
	if debug_fps_label.visible:
		debug_fps_label.text = "FPS: %.02f" % (Engine.get_frames_per_second())
