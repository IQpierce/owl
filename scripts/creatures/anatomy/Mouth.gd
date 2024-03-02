extends Node2D

@export var left_half:PhysicsBody2D
@export var left_poly:PatchworkPolygon2D
@export var right_half:PhysicsBody2D
@export var right_poly:PatchworkPolygon2D
@export var speed_factor:float = 1
@export var rotate_factor:float = 15

func _process(delta:float):
	# @TODO: Implement a better animation for the mouth-nibble
	var mouth_flap_angle:float = sin(Time.get_unix_time_from_system() * speed_factor)
	left_half.rotate(mouth_flap_angle * deg_to_rad(rotate_factor))
	right_half.rotate(-mouth_flap_angle * deg_to_rad(rotate_factor))

	# TODO (sam) This is really not great to do every frame... maybe it won't be bad if we ensure both self and stencil are low vert count
	# Maybe make beak include the mouth-line and stencil against that instead of creature's head
	if left_poly != null:
		left_poly.build_patchwork()
	if right_poly != null:
		right_poly.build_patchwork()


