extends Node

# @TODO: Make this more of a "pure abstract" base class. It is intended to be overridden.

class_name Brain

@export var controlled_creature:Creature
@export var auto_think_delta_secs:float = 1

# @TODO - This is weirdly specific and should probably not be the language all brains speak
signal on_target_velocity_changed(new_target:Vector2)

var last_think_time:float = NAN


func _process(delta):
	if auto_think_delta_secs > 0 && is_nan(last_think_time) || Time.get_unix_time_from_system() >= last_think_time + auto_think_delta_secs:
		think()

func think():
	assert(false, "pure virtual, this should be overridden!!")
	
