extends Player
class_name Player_Refactor

# TODO (sam) This can be removed once locomotor does everything it needs, and camera follows it
@export var locomotor:Locomotor

var camera:Camera2D

func set_camera(value:Camera2D):
	camera = value

func get_thrusting():
	return locomotor.thrusting

func get_thrust_speed():
	return locomotor.thrust_speed
