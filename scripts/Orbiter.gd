extends Area2D

@export var orbit_target:Node2D
@export var full_orbit_time_secs:float = 60

var orbit_start_time:float = NAN
var initial_orbit_distance:float = NAN
var initial_orbit_angle:float = NAN

func _process(delta):
	var current_time = Time.get_unix_time_from_system()
	
	if !orbit_target:
		return
	elif is_nan(orbit_start_time):
		var orbit_delta:Vector2 = global_position - orbit_target.global_position
		initial_orbit_distance = orbit_delta.length()
		initial_orbit_angle = orbit_delta.angle()
		orbit_start_time = current_time
	
	var orbit_time:float = current_time - orbit_start_time
	
	var orbit_angle_per_sec:float = (2*PI) / full_orbit_time_secs
	global_position = orbit_target.global_position + Vector2.RIGHT.rotated(initial_orbit_angle + orbit_time * orbit_angle_per_sec) * initial_orbit_distance
	
	


