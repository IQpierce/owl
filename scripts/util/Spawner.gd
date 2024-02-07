extends Node2D

class_name Spawner

# Always spawns in the "positive y" (down) direction.

@export var free_after_spawn:bool = false
@export var spawn_protos:Array[PackedScene]	# Each spawn, one of these is chosen randomly. TODO: Avoid repeats

@export var num_to_spawn:int = 1	

@export var spawn_random_angle:float = 60	# A random range (in degrees) around the "positive y" vector for our initial spawn position/velocity

@export var min_spawn_dist:float = 1.0	# min possible distance from origin point (along the spawn vector) 
@export var max_spawn_dist:float = 8.0	# max possible distance from origin point (along the spawn vector) 

@export var min_initial_velocity:float = 40.0
@export var max_initial_velocity:float = 80

func spawn(spawn_owner:Node2D):
	assert(spawn_owner != null)	
	
	# Wait until we know we are done with collision, otherwise we get warnings on every spawn
	await get_tree().process_frame

	for i in num_to_spawn:
		var spawn_proto:PackedScene = spawn_protos[randi() % spawn_protos.size()]
		var spawned_instance:CollisionObject2D = spawn_proto.instantiate()
		spawn_owner.add_child(spawned_instance)
		
		var spawn_angle_degrees:float = randf_range(-spawn_random_angle*0.5, spawn_random_angle*0.5)
		var spawn_dist:float = randf_range(min_spawn_dist, max_spawn_dist)
		
		var spawn_velocity_direction:Vector2 = (global_position - global_transform.origin)
		
		# add our random degrees/angle
		spawn_velocity_direction = Vector2.RIGHT.rotated(spawn_velocity_direction.angle() + deg_to_rad(spawn_angle_degrees))
		
		spawned_instance.global_position = global_position + (spawn_velocity_direction * spawn_dist)
		
		# initialize velocity, if possible
		var spawned_instance_as_rigidbody:RigidBody2D = spawned_instance as RigidBody2D
		if spawned_instance_as_rigidbody:
			var spawn_velocity_power:float = randf_range(min_initial_velocity, max_initial_velocity)
			spawned_instance_as_rigidbody.set_axis_velocity(spawn_velocity_direction * spawn_velocity_power)

		if free_after_spawn:
			queue_free

	
