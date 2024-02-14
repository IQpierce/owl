extends Node2D

@export var left_half:PhysicsBody2D
@export var right_half:PhysicsBody2D
@export var speed_factor:float = 1
@export var rotate_factor:float = 15

func _process(delta:float):
	# @TODO: Implement a better animation for the mouth-nibble
	var mouth_flap_angle:float = sin(Time.get_unix_time_from_system() * speed_factor)
	left_half.rotate(mouth_flap_angle * deg_to_rad(rotate_factor))
	right_half.rotate(-mouth_flap_angle * deg_to_rad(rotate_factor))

