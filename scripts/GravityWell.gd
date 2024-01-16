@tool

extends Area2D

class_name GravityWell


@export var gravity_well_radius:float = 64.0:
	set(v):
		gravity_well_radius = v
		
		# propagate the radius to the actual collision data
		var collision_shape:CollisionShape2D = get_child(0) as CollisionShape2D
		var circle_2d:CircleShape2D = collision_shape.shape as CircleShape2D
		assert(circle_2d != null)
		circle_2d.radius = gravity_well_radius

