extends Node2D

@export var current_score:int

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func reset_score():
	current_score = 0
	
