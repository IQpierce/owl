extends Node2D
class_name RoamCartridge

@export var thrust_deadzone:float = 1
@export var thrust_smash_threshold:float = 1

func apply(player:Player):
	if player != null:
		player.thrust_deadzone = thrust_deadzone
		player.thrust_smash_threshold = thrust_smash_threshold
