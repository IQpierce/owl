extends Node2D

class_name ThrustEngine

@export var target_body:RigidBody2D
@export var target_velocity:Vector2: set = set_target_velocity
@export var force_position:Vector2
@export var power:float = 1

func _ready():
	assert(target_body != null)

func _process(delta:float):
	
	var target_body_world_space_velocity:Vector2 = target_body.linear_velocity
	var velocity_delta = target_velocity - target_body_world_space_velocity
	
	if velocity_delta.is_zero_approx():
		return
	
	# Apply force to achieve the target velocity.
	target_body.apply_force(velocity_delta.normalized() * power * delta, force_position)
	

func set_target_velocity(new_velocity:Vector2):
	target_velocity = new_velocity
