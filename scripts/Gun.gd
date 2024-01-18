extends Node2D

@export var shot_proto:PackedScene
@export var shot_force:float
@export var cooldown_duration_secs:float
@export var inherit_velocity:RigidBody2D
@export var shot_parent:Node2D

var cooldown_timestamp:int

func is_waiting_on_cooldown():
	return Time.get_ticks_msec() < cooldown_timestamp

func shoot():
	print("try shoot")
	if (is_waiting_on_cooldown()):
		return



	print("shoot")
	
	var shot_instance:RigidBody2D = shot_proto.instantiate()
	shot_instance.global_position = global_position
	var initial_velocity:Vector2 = Vector2(0, -1).rotated(global_transform.get_rotation())
	initial_velocity *= shot_force
	initial_velocity += inherit_velocity.get_linear_velocity()
	shot_instance.set_linear_velocity(initial_velocity)
	shot_parent.owner.add_child(shot_instance)
	cooldown_timestamp = Time.get_ticks_msec() + (cooldown_duration_secs * 1000);
	
	
