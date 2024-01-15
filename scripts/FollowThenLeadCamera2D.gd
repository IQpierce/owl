extends Camera2D

@export var target:Player
@export var follow_threshold:float = 0
@export var max_speed_factor:float = 2
@export var acceleration_factor:float = 1

enum FollowMode { EXACT, EXACT_BEYOND_RADIUS, ATTEMPT_LEAD }
@export var follow_mode:FollowMode = FollowMode.EXACT

var velocity:Vector2

func _ready():
	target.camera = self

func _physics_process(delta):
	if target != null:
		var to_target = target.position - position
		var target_dist_sqr = to_target.length_squared()

		if follow_mode == FollowMode.EXACT:
			position = target.position
		elif follow_mode == FollowMode.EXACT_BEYOND_RADIUS:
			if target_dist_sqr > follow_threshold * follow_threshold:
				position = target.position - (to_target.normalized() * follow_threshold)
		elif follow_mode == FollowMode.ATTEMPT_LEAD:
			var max_speed = target.max_speed * max_speed_factor
			var acceleration = target.thrust_speed * acceleration_factor

			#TODO (sam) turning gets the camera stuck way behind. should it be more choosey about when to match velocity?
			if target.thrusting:
				if target_dist_sqr > follow_threshold * follow_threshold:
					velocity = target.linear_velocity #could this be smoother on turns
				else:
					velocity += target.linear_velocity.normalized() * acceleration * delta
					if velocity.length_squared() > max_speed * max_speed:
						velocity = velocity.normalized() * max_speed
			else:
				if to_target.dot(velocity) < 0:
					velocity = Vector2.ZERO
				elif to_target.dot(target.position - (position + (velocity * delta))) <= 0:
					position = target.position #should there be a bounce-back?
					velocity = Vector2.ZERO
				elif velocity.length_squared() < target.linear_velocity.length_squared():
					velocity = target.linear_velocity

			position += velocity * delta
