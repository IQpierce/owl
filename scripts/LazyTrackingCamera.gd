extends Camera2D

@export var prey:Player #better name?
@export var track_threshold:float = 0
@export var lock_threshold:float = 0
@export var max_relative_speed:float = 1
@export var acceleration_factor:float = 1
@export var lead_distance = 0

var velocity:Vector2

enum TrackingState { Rest, Follow, Lead }
var tracking = TrackingState.Rest

func _ready():
	prey.camera = self

func _physics_process(delta):
	var focus = position

	if prey != null:
		var to_prey = prey.position - position
		var prey_dist_sqr = to_prey.length_squared()
	
		if tracking == TrackingState.Rest:
			if prey_dist_sqr > track_threshold * track_threshold:
				#velocity = prey.linear_velocity
				tracking = TrackingState.Follow
		elif tracking == TrackingState.Follow:
			if velocity.dot(prey.position - position) <= 0:
				tracking = TrackingState.Lead
		elif tracking == TrackingState.Lead:
			if prey.linear_velocity.dot(position - prey.position) <= 0:
				tracking = TrackingState.Rest

		if tracking == TrackingState.Rest:
			velocity = Vector2.ZERO
		else:
			#var prey_bearing = Vector2.UP.rotated(prey.rotation) #TODO should this just be ZERO so focus is just the still prey?
			var prey_bearing = Vector2.ZERO
			var prey_speed = prey.linear_velocity.length()
			if prey_speed > 0:
				prey_bearing = prey.linear_velocity / prey_speed

			focus = prey.position + (prey_bearing * lead_distance)
			var to_focus = focus - position
			var to_focus_length = to_focus.length()
			if to_focus_length > 0:
				var to_focus_dir = to_focus / to_focus_length
				velocity += to_focus_dir * (prey.thrust_speed * acceleration_factor * delta)
			else:
				velocity = prey.linear_velocity
			var speed = velocity.length()
			#if speed > 0:
			#	var bearing = velocity / speed
			#	if speed < prey_speed:
			#		velocity = bearing * prey_speed
			#else:
			#	velocity = prey.linear_velocity
			var max_speed = prey_speed * max_relative_speed
			if speed > max_speed:
				velocity = (velocity / speed) * max_speed


	var delta_vel = velocity * delta
	if (focus - (position + delta_vel)).dot(focus - position) < 0:
		position = focus
	else:
		position += delta_vel

	if (position - prey.position).length_squared() > lock_threshold * lock_threshold:
		position = prey.position + ((position - prey.position).normalized() * lock_threshold)
