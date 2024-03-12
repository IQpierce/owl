extends RigidBody2D

class_name Bullet


@export var damage_on_impact:float
@export var impact_force:float
@export var ignore_bodies:Array[PhysicsBody2D]

# TODO (sam) This is placeholder to see if the effect even makes sense
var camera_track:TrackThrusterCameraCartridge = null
var camera_pull_factor:float = 0

# TODO (sam) Is this something we should avoid giving per-frame behavior
func _physics_process(delta):
	if camera_track != null:
		var beyond_screen = OwlGame.instance.beyond_screen(global_position)
		if beyond_screen.length_squared() > 0:
			camera_track.prey_offset += beyond_screen * camera_pull_factor

func on_body_entered(other_body:Node):
	var other_body_physics:PhysicsBody2D = other_body as PhysicsBody2D
	if other_body_physics != null && ignore_bodies.count(other_body_physics) == 0:
		var other_body_rigid:RigidBody2D = other_body as RigidBody2D
		if other_body_rigid != null:
			# TODO (sam) What is this meant to do beyond what normal physics do?
			other_body_rigid.apply_impulse(
				linear_velocity.normalized() * impact_force, 
				global_position - other_body.global_position
			)
			
			var other_body_thing:Thing = other_body_rigid as Thing
			if (other_body_thing):
				other_body_thing.deal_damage(damage_on_impact, global_position)
	
		queue_free()

func self_destruct():
	queue_free()

