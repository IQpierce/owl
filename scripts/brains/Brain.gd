extends Node2D

# @TODO: Make this more of a "pure abstract" base class. It is intended to be overridden.

class_name Brain

@export var controlled_creature:Creature
@export var auto_think_delta_secs:float = 0

# @TODO - This is weirdly specific and should probably not be the language all brains speak
signal on_target_location_changed(world_location:Vector2)
signal on_target_velocity_changed(new_relative_velocity:Vector2)

var last_auto_think_time:float = NAN

func _ready():
	assert(controlled_creature != null)

func _process(delta):
	if auto_think_delta_secs > 0 && \
		(	is_nan(last_auto_think_time) || \
			Time.get_unix_time_from_system() >= last_auto_think_time + auto_think_delta_secs
		):
		think()
		last_auto_think_time = Time.get_unix_time_from_system()

func think():
	assert(false, "pure virtual, this should be overridden!!")
	
