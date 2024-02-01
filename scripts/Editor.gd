@tool

extends Node

var was_editor_paused: bool

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta:float):
	if not Engine.is_editor_hint():
		if Input.is_action_just_pressed("escape"):
			get_tree().quit()
		if Input.is_action_just_pressed("editor_pause"):
			get_tree().paused = !get_tree().paused
		
		if was_editor_paused != get_tree().paused:
			if get_tree().paused:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

		was_editor_paused = get_tree().paused


	# TODO Attempting to repaint Inspector to see property changes but no dice
	if OS.has_feature("editor"):
		notify_property_list_changed()
