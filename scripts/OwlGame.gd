extends Node2D

class_name OwlGame

@export var hide_mouse:bool = true
@export var player:Player

signal on_game_ended(won:bool)

var game_over:bool

func _ready():
	Engine.max_fps = 60
	
	if hide_mouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	player.died.connect(self.on_player_died)
	
func _process(delta):
	if Input.is_action_pressed("escape"):
		get_tree().quit()

func on_player_died(utterly:bool):
	game_over = true
	on_game_ended.emit(false)
	
