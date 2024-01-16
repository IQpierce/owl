extends Camera2D

@export var target:Player
@export var follow_threshold:float = 0
@export var max_speed_factor:float = 2
@export var acceleration_factor:float = 1
@export var lead_distance = 0
@export var max_distance_from_target = 0
@export var ease_distance = 100

enum FollowMode { EXACT, EXACT_BEYOND_RADIUS, LOOSEY_GOOSE, LEAD_BEYOND_RADIUS }
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
		elif follow_mode == FollowMode.LOOSEY_GOOSE:
			var max_speed = target.max_speed * max_speed_factor
			var acceleration_mag = target.thrust_speed * acceleration_factor

			var position_hard_set = false

			#TODO (sam) turning gets the camera stuck way behind. should it be more choosey about when to match velocity?
			if target.thrusting:
				# TODO dot > 0 might not be specific enough
				#if velocity.dot(target.position - position) > 0 && target_dist_sqr > follow_threshold * follow_threshold:
				#	velocity = target.linear_velocity #could this be smoother on turns
				#else:
				#	velocity += target.linear_velocity.normalized() * acceleration * delta
				#	if velocity.length_squared() > max_speed * max_speed:
				#		velocity = velocity.normalized() * max_speed
				var lead_pos = target.position + (Vector2.UP.rotated(target.rotation) * lead_distance);
				var to_offset = lead_pos - position
				var acceleration = to_offset.normalized() * acceleration_mag
				velocity += acceleration * delta
				var delta_vel = velocity * delta
				var new_pos = position + delta_vel
				var move_para_offset = delta_vel.project(lead_pos - target.position)
				var move_perp_offset = delta_vel - move_para_offset
				#if to_offset.dot(lead_pos - (position + move_para_offset)) < 0:
				#	move_para_offset = Vector2.ZERO #TODO this is wrong
				#if to_offset.dot(lead_pos - (position + move_perp_offset)) < 0:
				#	move_perp_offset = Vector2.ZERO #TODO this is wrong
				#TODO do we need to care about max_speed
				position = new_pos

				#TODO should this be done even when thrusters are off?
				#var from_target = position - target.position
				#if false:#ease_distance > 0:
				#	var eased_max_distance = max_distance_from_target - ease_distance
				#	if from_target.length_squared() > eased_max_distance * eased_max_distance:
				#		var from_target_length = from_target.length()
				#		var dist_to_eased = from_target_length - eased_max_distance
				#		var eased_portion = clamp(dist_to_eased / ease_distance, 0, 1)
				#		var lerp_t = ((1 - eased_portion) * from_target_length) + (eased_portion * (eased_max_distance + (eased_portion * eased_portion * ease_distance)))
				#		position = target.position + ((from_target / from_target.length()) * lerp_t)
				#else:
				#	if from_target.length_squared() > max_distance_from_target * max_distance_from_target:
				#		position = target.position + (from_target.normalized() * max_distance_from_target)
			else:
				if to_target.dot(velocity) < 0:
					velocity = Vector2.ZERO
				elif to_target.dot(target.position - (position + (velocity * delta))) <= 0:
					position = target.position #should there be a bounce-back?
					velocity = Vector2.ZERO
				elif velocity.length_squared() < target.linear_velocity.length_squared():
					velocity = target.linear_velocity
				position += velocity * delta
		elif follow_mode == FollowMode.LEAD_BEYOND_RADIUS:
			print("you want LazyTrackingCamera")


