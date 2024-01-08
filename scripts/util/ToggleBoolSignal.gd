extends Node

@export var current_toggle_val:bool

signal toggle_value_changed(current_val:bool)

func toggle_value():
	current_toggle_val = !current_toggle_val
	toggle_value_changed.emit(current_toggle_val)



