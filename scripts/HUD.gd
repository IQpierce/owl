extends CanvasLayer

var game:OwlScene
@export var game_over_layer:CanvasLayer
@export var debug_fps_label:Label
@export var debug_time_speed_up_label:Label
@export var post_game_over_input_cooldown_secs:float = 2

var accept_input_timeout:float

func _ready():
	game = OwlGame.instance.scene
	game.on_game_ended.connect(self.on_game_over)

func _process(delta):
	
	if debug_fps_label.visible:
		debug_fps_label.text = "FPS: %.02f" % (Engine.get_frames_per_second())
		
	if accept_input_timeout <= 0 || accept_input_timeout < Time.get_unix_time_from_system():
		# special input code for HUD states, etc.
		
		if game.game_over && Input.is_anything_pressed():
			get_tree().reload_current_scene()
		
		# @TODO - From here on is debug/cheat functionality...
		# ...we should compile it out for "real" builds!
		if Input.is_action_just_pressed("debug_toggle_fps_display"):
			debug_fps_label.visible = !debug_fps_label.visible
		
		if Input.is_action_pressed("debug_time_speed_up"):
			debug_time_speed_up_label.visible = true
			Engine.time_scale = 5
		else:
			debug_time_speed_up_label.visible = false
			Engine.time_scale = 1

	

func on_game_over(won:bool):
	game_over_layer.visible = true
	accept_input_timeout = Time.get_unix_time_from_system() + post_game_over_input_cooldown_secs
	
