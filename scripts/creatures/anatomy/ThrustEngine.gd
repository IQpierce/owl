extends Node2D

class_name ThrustEngine

@export var target_body:RigidBody2D
@export var target_velocity:Vector2: set = set_target_velocity
@export var force_position:Vector2
@export var power:float = 1
# TODO (sam) We should probably just remove this class and go directly to locomotor.
@export var locomotor:Locomotor = null

func _ready():
	assert(target_body != null)
	if locomotor != null:
		#locomotor.drive_force = power
		locomotor.body = target_body

func _process(delta:float):
	
	var target_body_world_space_velocity:Vector2 = target_body.linear_velocity
	var velocity_delta = target_velocity - target_body_world_space_velocity
	
	#TODO (sam) We can remove the extra delta here applying force already incorporates delta twice before position
	if locomotor != null:
		var heading = Vector2.UP.rotated(target_body.global_rotation)
		var slow_down = heading.dot(velocity_delta) < 0
		var head_dot_want = 0
		if target_velocity.length_squared() > 0:
			head_dot_want = clamp(heading.dot(target_velocity.normalized()), 0, 1)
			#print(head_dot_want)
		var drive_factor = 0
		# TODO MAYBE it depends on distance, like as I get closer I should stop to turn more ... or even back up for a wind up
		#if head_dot_delta > 0.7:#0.9:
		if !slow_down && head_dot_want > 0.9:
			#print("GO ", head_dot_want)
			drive_factor = head_dot_want
			#locomotor.locomote(drive_factor, 0, delta)
		locomotor.drive(drive_factor, 1, delta)
		#else:
		#	target_body.linear_velocity = Vector2.ZERO
	else:
		if velocity_delta.is_zero_approx():
			return
		# Apply force to achieve the target velocity.
		target_body.apply_force(velocity_delta.normalized() * power * delta, force_position)
	

func set_target_velocity(new_velocity:Vector2):
	target_velocity = new_velocity
