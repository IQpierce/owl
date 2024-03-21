extends Node2D

# Rotates the body towards the given position, over time.

@export var controlled_body:RigidBody2D
@export var target_world_position:Vector2: set=set_target_world_position
@export var torque_power:float = 1
# TODO (sam) We should probably just remove this class and go directly to locomotor.
@export var locomotor:Locomotor = null

func _ready():
	assert(controlled_body != null)
	set_target_world_position(controlled_body.global_position + Vector2.UP.rotated(controlled_body.global_rotation))
	if locomotor != null:
		#locomotor.turn_force = torque_power
		locomotor.body = controlled_body

func _process(delta:float):
	
	if locomotor != null:
		# TODO It would be nice to consider the target's linear velocity as well and try to head them off ... maybe this should be in seeker brain
		var to_target = (target_world_position - controlled_body.global_position)
		if controlled_body.linear_velocity.dot(to_target) > 0:
			var to_para_vel = to_target.project(controlled_body.linear_velocity)
			var to_perp_vel = to_target - to_para_vel
			#target_world_position += to_perp_vel * delta
			#target_world_position = (global_position + Vector2.UP.rotated(global_rotation)) + to_perp_vel * delta
		#locomotor.locomote_towards(target_world_position, 1, delta)
		locomotor.turn_towards(target_world_position, 1, delta)
	else:
		var current_angle:float = controlled_body.get_global_transform().get_rotation() + rotation
		var desired_angle:float = (target_world_position - global_position).angle()
		# @TODO: Refined turning torque force math to not always be max/extreme
		if desired_angle < current_angle:
			controlled_body.apply_torque(-delta * torque_power)
		elif desired_angle > current_angle:
			controlled_body.apply_torque(delta * torque_power)
	

func set_target_world_position(new_world_position:Vector2):
	target_world_position = new_world_position
