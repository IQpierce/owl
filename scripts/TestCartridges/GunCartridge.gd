extends Node2D
class_name GunCartridge

@export var affect_motion_mode:Gun.AffectMotionMode = Gun.AffectMotionMode.Never
@export var shoot_turn_damp:float = 1
@export var cooldown_duration_secs:float

func apply(gun:Gun):
	if gun != null:
		gun.affect_motion_mode = affect_motion_mode
		gun.shoot_turn_damp = shoot_turn_damp
		gun.cooldown_duration_secs = cooldown_duration_secs
