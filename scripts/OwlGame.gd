extends Node2D

class_name OwlGame

@export var player:Player
@export var smearing_view:SubViewportContainer

signal on_game_ended(won:bool)

var game_over:bool

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Engine.max_fps = 60
	
	player.died.connect(self.on_player_died)

	var viewport_size = get_viewport().size
	print(viewport_size)

	if smearing_view:
		smearing_view.stretch = true
		smearing_view.custom_minimum_size = viewport_size
		smearing_view.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
		smearing_view.size = viewport_size
		smearing_view.position = Vector2.ZERO
		smearing_view.size_flags_horizontal = Control.SizeFlags.SIZE_EXPAND_FILL
		smearing_view.size_flags_vertical   = Control.SizeFlags.SIZE_EXPAND_FILL


	
#func _process(delta):
	# Escape PAUSES ... use F8 or CMD+. to quit preview
	#	if Input.is_action_pressed("escape"):
	#		get_tree().quit()

func on_player_died(utterly:bool):
	game_over = true
	on_game_ended.emit(false)
	
