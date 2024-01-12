extends Node2D

@export var current_score:int

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Engine.max_fps = 60
	
func _process(delta):
	if Input.is_action_pressed("escape"):
		get_tree().quit()

func reset_score():
	current_score = 0
	
