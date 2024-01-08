extends RigidBody2D

@export var damage_on_impact:float
@export var impact_force:float

func on_body_entered(other_body:Node):
	
	var other_body_rigid:RigidBody2D = other_body as RigidBody2D
	if (other_body_rigid):
		other_body_rigid.apply_impulse(linear_velocity.normalized() * impact_force, global_position)
		
		var other_body_thing:Thing = other_body_rigid as Thing
		if (other_body_thing):
			other_body_thing.deal_damage(damage_on_impact, global_position)
	
	queue_free()

func self_destruct():
	queue_free()

