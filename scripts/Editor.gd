@tool

extends Node

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	if not Engine.is_editor_hint():
		if Input.is_action_just_pressed("escape"):
			get_tree().paused = !get_tree().paused
