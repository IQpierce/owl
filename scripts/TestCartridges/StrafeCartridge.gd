extends Node2D
class_name StrafeCartridge

@export var motion = Hopdart.Motion.Direct
@export_group("Direct Motion")
@export var initial_distance:float = 50
@export var finesse_distance:float = 100
@export_group("Impulse Motion")
@export var initial_impulse:float = 40
@export var finesse_impulse:float = 20
@export_group("")
@export var alignment = Hopdart.Alignment.Screen
@export_range(16, 1000) var initial_msec:int = 100
@export_range(16, 1000) var finesse_msec:int = 200
@export var cooldown_msec:int = 0

func apply(strafe:Hopdart):
	if strafe != null:
		strafe.motion = motion
		strafe.initial_distance = initial_distance
		strafe.finesse_distance = finesse_distance
		strafe.initial_impulse = initial_impulse
		strafe.finesse_impulse = finesse_impulse
		strafe.alignment = alignment
		strafe.initial_msec = initial_msec
		strafe.finesse_msec = finesse_msec
		strafe.cooldown_msec = cooldown_msec
