extends Node2D
class_name StencilStack

## All the viewport containers that need to be synchronized with the game window and camera(s)
@export var viewport_containers: Array[SubViewportContainer]

func _ready():
	# TODO (sam) does this need to be done in OwlScene instead
	#var view_size = get_viewport().size
	#for viewport_container in viewport_containers:
	#	viewport_container.stretch = true
	#	viewport_container.custom_minimum_size = view_size
	#	viewport_container.set_anchors_preset(Control.LayoutPreset.PRESET_FULL_RECT)
	#	viewport_container.size = view_size
	#	viewport_container.position = Vector2.ZERO
	#	viewport_container.size_flags_horizontal = Control.SizeFlags.SIZE_EXPAND_FILL
	#	viewport_container.size_flags_vertical   = Control.SizeFlags.SIZE_EXPAND_FILL
	pass
