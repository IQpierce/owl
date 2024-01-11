extends Node2D

@export var rotate_angle_per_sec:float


func _process(delta):
	rotate(rotate_angle_per_sec * delta)
