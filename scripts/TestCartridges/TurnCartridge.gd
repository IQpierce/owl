extends Node2D
class_name TurnCartridge

@export var turn_force:float = 60
@export var angular_damp:float = 10
@export var drive_turn_factor:float = 0.8

func apply(body:RigidBody2D, locomotor:Locomotor):
	if body != null:
		body.angular_damp = angular_damp
	if locomotor != null:
		locomotor.turn_force = turn_force
		locomotor.drive_turn_factor = drive_turn_factor
