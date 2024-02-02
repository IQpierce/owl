extends Creature
class_name Player

#TODO (sam)all of these are cruft we want to remove after Player Refactor
# They should be handled by subcomponents... they only exist for now to prevent breaking other work
func set_camera(value:Camera2D):
	pass

func get_thrusting():
	return false

func get_thrust_speed():
	return 0
