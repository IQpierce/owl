extends Node2D

# @TODO: Make this more of a "pure abstract" base class. It is intended to be overridden.

class_name Brain

@export var enabled:bool = true
@export var controlled_creature:Creature
@export var think_delta_secs:float = 1


signal on_target_velocity_changed(new_target:Vector2)

var last_think_time:float = NAN


func _process(delta):
	if enabled && is_nan(last_think_time) || Time.get_unix_time_from_system() >= last_think_time + think_delta_secs:
		think()

func think():
	push_warning("This is the base Brain.think(), it should be overridden!! Use a subclass of this one!!!")
	pass
	
