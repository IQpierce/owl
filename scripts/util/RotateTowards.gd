extends Node2D

# Rotates the body towards the given position, over time.

@export var controlled_body:RigidBody2D
@export var target_world_position:Vector2: set=set_target_world_position
@export var torque_power:float = 1

func _ready():
	assert(controlled_body != null)

func _process(delta:float):
	var current_angle:float = controlled_body.get_global_transform().get_rotation() + rotation
	var desired_angle:float = (target_world_position - global_position).angle()
	
	# @TODO: Refined turning torque force math to not always be max/extreme
	if desired_angle < current_angle:
		controlled_body.apply_torque(-delta * torque_power)
	elif desired_angle > current_angle:
		controlled_body.apply_torque(delta * torque_power)
	

func set_target_world_position(new_world_position:Vector2):
	target_world_position = new_world_position
