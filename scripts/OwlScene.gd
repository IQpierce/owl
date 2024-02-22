extends Node2D

class_name OwlScene

@export var jank_fighter:JankFighter
@export var hide_mouse:bool = true
@export var fishbowl_mode:bool = false
@export var player:Player
@export var world_camera:CameraRig
@export var fishbowl_camera:Camera2D
@export var fishbowl_mode_auto_reset_secs:float = 60 * 30


@export var muted:bool = false:
	set(v):
		muted = v
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)

@export var emulate_phosphor_monitor:bool = true
## PhosphorEmulation we need to render everything under to pretend the game is rendered in suspended phospor.
@export var phosphor_emulation_proto:PackedScene

signal on_game_ended(won:bool)

var game_over:bool
var fishbowl_mode_auto_reset_timestamp:float = NAN

func _ready():
	Engine.max_fps = 60
	
	if hide_mouse:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	player.died.connect(self.on_player_died)

	var default_view_size = Vector2(1920, 1080)
	var view_size = get_viewport().size
	if OS.has_feature("editor"):
		print("Zoom ", view_size.x, "x",view_size.y, " to show ", default_view_size.x, "x", default_view_size.y, "(ish)")

	if emulate_phosphor_monitor && phosphor_emulation_proto != null:
		var scene_children = get_children();
		var phosphor_emu:PhosphorEmulation = phosphor_emulation_proto.instantiate()
		add_child(phosphor_emu)
		for viewport_container in phosphor_emu.viewport_containers:
			viewport_container.stretch = true
			viewport_container.custom_minimum_size = view_size
			viewport_container.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
			viewport_container.size = view_size
			viewport_container.position = Vector2.ZERO
			viewport_container.size_flags_horizontal = Control.SizeFlags.SIZE_EXPAND_FILL
			viewport_container.size_flags_vertical   = Control.SizeFlags.SIZE_EXPAND_FILL
		
		var intermediary:Node2D = Node2D.new()
		phosphor_emu.injection_viewport.add_child(intermediary)
		intermediary.name = "WorldContainer"
		for child in scene_children:
			child.reparent(intermediary)

	var default_view_diagonal = default_view_size.length()
	var view_diagonal = view_size.length()
	
	if world_camera != null:
		world_camera.init_zoom(view_diagonal / default_view_diagonal, true)
	
	if fishbowl_camera != null:
		fishbowl_camera.zoom *= view_diagonal / default_view_diagonal
	
	if fishbowl_mode && fishbowl_mode_auto_reset_secs > 0:
		fishbowl_mode_auto_reset_timestamp = Time.get_unix_time_from_system() + fishbowl_mode_auto_reset_secs

func _process(delta):
	if Input.is_action_just_pressed("toggle_mute"):
		muted = !muted
	
	if fishbowl_mode:
		if fishbowl_camera:
			if world_camera:
				world_camera.enabled = false
			fishbowl_camera.enabled = true
		
		if !is_nan(fishbowl_mode_auto_reset_timestamp) && \
			Time.get_unix_time_from_system() >= fishbowl_mode_auto_reset_timestamp:
				# reset!
				get_tree().reload_current_scene()
	elif fishbowl_camera:
		if world_camera:
			world_camera.enabled = true
		fishbowl_camera.enabled = false
		

func on_player_died(utterly:bool):
	game_over = true
	on_game_ended.emit(false)
	
func get_default_camera_cartridge() -> CameraCartridge:
	if player != null:
		return player.camera_cartridge
	return null
