extends Node2D
class_name DriveCartridge

@export var drive_force:float = 800
@export var max_speed:float = 1000
@export var linear_damp:float = 2

func apply(body:RigidBody2D, locomotor:Locomotor):
	if body != null:
		body.linear_damp = linear_damp
	if locomotor != null:
		locomotor.drive_force = drive_force
		locomotor.max_speed = max_speed
