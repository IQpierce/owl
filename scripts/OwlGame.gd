extends Node2D

class_name OwlGame

@export var player:Player
@export var smearing_view:SubViewportContainer
@export var world_camera:Camera2D

signal on_game_ended(won:bool)

var game_over:bool

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Engine.max_fps = 60
	
	player.died.connect(self.on_player_died)

	var default_view_size = Vector2(1920, 1080)
	var view_size = get_viewport().size
	print("Zoom ", view_size.x, "x",view_size.y, " to show ", default_view_size.x, "x", default_view_size.y, "(ish)")

	if smearing_view:
		smearing_view.stretch = true
		smearing_view.custom_minimum_size = view_size
		smearing_view.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
		smearing_view.size = view_size
		smearing_view.position = Vector2.ZERO
		smearing_view.size_flags_horizontal = Control.SizeFlags.SIZE_EXPAND_FILL
		smearing_view.size_flags_vertical   = Control.SizeFlags.SIZE_EXPAND_FILL

	if world_camera:
		var default_view_diagonal = default_view_size.length()
		var view_diagonal = view_size.length()
		world_camera.zoom *= view_diagonal / default_view_diagonal

func on_player_died(utterly:bool):
	game_over = true
	on_game_ended.emit(false)
	
