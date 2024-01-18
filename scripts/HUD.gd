extends CanvasLayer

@export var game:OwlGame
@export var game_over_layer:CanvasLayer
@export var debug_fps_label:Label
@export var post_game_over_input_cooldown_secs:float = 2

var accept_input_timeout:float

func _ready():
	game.on_game_ended.connect(self.on_game_over)

func _process(delta):
	
	if debug_fps_label.visible:
		debug_fps_label.text = "FPS: %.02f" % (Engine.get_frames_per_second())
		
	if accept_input_timeout <= 0 || accept_input_timeout < Time.get_unix_time_from_system():
		# special input code for HUD states, etc.
		
		if game.game_over && Input.is_anything_pressed():
			get_tree().reload_current_scene()
		
		# @TODO - This part is debug/cheat functionality...
		# ...we should compile it out for "real" builds!
		if Input.is_action_just_pressed("debug_toggle_fps_display"):
			debug_fps_label.visible = !debug_fps_label.visible
	

func on_game_over(won:bool):
	game_over_layer.visible = true
	accept_input_timeout = Time.get_unix_time_from_system() + post_game_over_input_cooldown_secs
	
