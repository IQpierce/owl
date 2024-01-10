extends RigidBody2D

class_name Thing

@export var health:float
@export var max_health:float
@export var emit_per_damage:Dictionary	# This is a dictionary whose keys are PackedScene's which represent instances which will be spawned/emitted whenever an amount of damage is dealt. Damage will accumulate, and when the threshhold is crossed (represented by the key value - a float), 1 instance will be emitted.

# @TODO - These should really be on each element of the emit_per_damage dictionary, not a global thing, since the motion/vfx we want might be very different for each!
@export var emission_angle_range:float
@export var emission_dist_min:float
@export var emission_dist_max:float
@export var emit_velocity_min:float
@export var emit_velocity_max:float

var accumulated_emission_damage:Dictionary	# This is a dictionary whose keys align exactly with those of emit_per_damage, and whose values represent the accumulated damage taken - reset and modulo'ed by the maximum represented by the float val of the emit_per_damage row



func _ready():
	reset_accumulated_damage()
	

func reset_health():
	health = max_health
	reset_accumulated_damage()

	
func reset_accumulated_damage():
	for emission_key in emit_per_damage:
		accumulated_emission_damage[emission_key] = float(0)


func deal_damage(dmg_amt:float, global_position:Vector2):
	health -= dmg_amt
	
	for emission_key in emit_per_damage:
		var dmg_max:float = emit_per_damage[emission_key]	# This is the threshhold for how much damage we take before we emit 1 instance of the PackedScene.
		var accumulated_dmg:float = accumulated_emission_damage[emission_key] + dmg_amt
		
		# Emit when the accumulated + current damage crosses the threshhold.
		while accumulated_dmg > dmg_max:
			emit(emission_key, global_position)
			accumulated_dmg -= dmg_max
		
		# Save the remaining "leftover" accumulated damage
		accumulated_emission_damage[emission_key] = accumulated_dmg
	
	if (health <= 0):
		health = 0
		die()

func emit(packed_scene:PackedScene, global_position:Vector2):
	
	var emit_owner:Node = owner
	
	if (owner == null):
		emit_owner = get_tree().current_scene
	
	assert(emit_owner != null)	
		
	var emitted_instance:CollisionObject2D = packed_scene.instantiate()
	emit_owner.add_child(emitted_instance)
	
	var emission_angle_degrees:float = randf_range(-emission_angle_range*0.5, emission_angle_range*0.5)
	var emission_dist:float = randf_range(emission_dist_min, emission_dist_max)
	
	var emission_velocity_direction:Vector2 = (global_position - global_transform.origin)
	
	# add our random degrees/angle
	emission_velocity_direction = Vector2.RIGHT.rotated(emission_velocity_direction.angle() + deg_to_rad(emission_angle_degrees))
	
	emitted_instance.global_position = global_position + (emission_velocity_direction * emission_dist) 
	var emitted_instance_as_rigidbody:RigidBody2D = emitted_instance as RigidBody2D
	if emitted_instance:
		var emission_velocity_power:float = randf_range(emit_velocity_min, emit_velocity_max)
		
		emitted_instance_as_rigidbody.apply_impulse(emission_velocity_direction * emission_velocity_power)

func die():
	# todo: play cool vfx / sfx
	queue_free()
