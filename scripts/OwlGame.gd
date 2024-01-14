extends Node2D

class_name OwlGame

@export var player:Player

signal on_game_ended(won:bool)

var game_over:bool

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Engine.max_fps = 60
	
<<<<<<< HEAD
	player.died.connect(self.on_player_died)
	
func _process(delta):
	if Input.is_action_pressed("escape"):
		get_tree().quit()

func on_player_died(utterly:bool):
	game_over = true
	on_game_ended.emit(false)
=======
func reset_score():
	current_score = 0
>>>>>>> 102e6975787f34c5a28204c5ce07fc1aad82db18
	
