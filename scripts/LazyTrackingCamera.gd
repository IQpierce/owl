extends Camera2D

# TODO REMOVE
@export var state_label:Label


@export var prey:Player #better name?
@export var track_threshold:float = 0
@export var lock_threshold:float = 0
@export var max_relative_speed:float = 1
@export var acceleration_factor:float = 1
@export var lead_distance = 0

#TODO expose vel_perp correction instead of just dividing by 2
#TODO expose lead_within_angle (and draw correctly) instead of requiring perpendicular
#TODO expose how long it takes for Follow to become Rest

var velocity:Vector2
var prey_velocity:Vector2
var prey_bearing:Vector2
var frames_decelerating = 0 #rename frames_prey_slowing

var track_rect:Rect2
var lock_rect:Rect2

enum TrackingState { Rest, Follow, Lead, Reserve }
var tracking = TrackingState.Rest

func _ready():
	prey.camera = self

func _draw():
	state_label.text = TrackingState.keys()[tracking]

	#draw_arc(Vector2(0, 0), lead_distance, 0, TAU, 60, Color.GRAY)
	if tracking == TrackingState.Lead:
		# Screen Center
		draw_arc(Vector2(0, 0), 10,  0, TAU, 60, Color.WHITE)

		# Desired Screen Center (focus)
		var relative_prey_pos = prey.position - position
		var relative_lead_pos = relative_prey_pos + (prey_bearing * lead_distance)
		draw_line(relative_lead_pos + Vector2(-10, -10), relative_lead_pos + Vector2(10, 10),  Color.WHITE)
		draw_line(relative_lead_pos + Vector2(-10, 10),  relative_lead_pos + Vector2(10, -10), Color.WHITE)

		# Maintain Tracking or Rest Threshold
		var prey_perp = Vector2(relative_prey_pos.y, -relative_prey_pos.x).normalized() * 100
		draw_dashed_line(relative_prey_pos - prey_perp, relative_prey_pos + prey_perp, Color.WHITE, 1.0, 10.0)

	if tracking != TrackingState.Lead:
		draw_rect(track_rect, Color.GRAY, false, 1.0)

	draw_rect(lock_rect, Color.GRAY, false, 3.0 * (tracking + 1))

func _physics_process(delta):
	var focus = position

	var view_size = get_viewport().size # TODO Is this bad to call every frame?
	var half_view_size = view_size / 2

	if prey != null:
		var to_prey = prey.position - position
		var prey_dist_sqr = to_prey.length_squared()

		track_rect = Rect2(
			track_threshold - half_view_size.x,
			track_threshold - half_view_size.y,
			view_size.x - track_threshold * 2,
			view_size.y - track_threshold * 2)
		lock_rect = Rect2(
			lock_threshold - half_view_size.x,
			lock_threshold - half_view_size.y,
			view_size.x - lock_threshold * 2,
			view_size.y - lock_threshold * 2)
	
		if tracking == TrackingState.Rest:
			#if prey_dist_sqr > track_threshold * track_threshold && prey.linear_velocity.dot(prey.position - position) > 0:
			if (abs(prey.position.x - position.x) > half_view_size.x - track_threshold || abs(prey.position.y - position.y) > half_view_size.y - track_threshold) && prey.linear_velocity.dot(prey.position - position) > 0:
				#velocity = prey.linear_velocity
				tracking = TrackingState.Follow
		elif tracking == TrackingState.Follow:
			if prey.linear_velocity.length_squared() < prey_velocity.length_squared():
				frames_decelerating += 1
				if frames_decelerating > 20:
					tracking = TrackingState.Rest
			else:
				frames_decelerating = 0
				if velocity.dot(prey.position - position) <= 0:
					tracking = TrackingState.Lead
				elif prey.linear_velocity.dot(prey_velocity) <= 0:
					tracking = TrackingState.Rest
		elif tracking == TrackingState.Lead:
			if prey.linear_velocity.dot(position - prey.position) <= 0:
				frames_decelerating += 1
				if frames_decelerating > 20: # TODO I'm not conviced this is doing anything
					tracking = TrackingState.Rest
			else:
			#if prey.linear_velocity.normalized().dot((position - prey.position).normalized()) <= cos(45):
				frames_decelerating = 0
				#tracking = TrackingState.Rest

		prey_velocity = prey.linear_velocity

		if tracking == TrackingState.Rest:
			#velocity = Vector2.ZERO
			velocity *= .99 #expose this
		else:
			#var prey_bearing = Vector2.UP.rotated(prey.rotation) #TODO should this just be ZERO so focus is just the still prey?
			prey_bearing = Vector2.ZERO
			var prey_speed = prey.linear_velocity.length()
			if prey_speed > 0:
				prey_bearing = prey.linear_velocity / prey_speed

			if tracking == TrackingState.Follow:
				focus = prey.position + (prey_bearing * lead_distance)
			elif tracking == TrackingState.Lead:
				focus = prey.position + (prey_bearing * lead_distance)
			var to_focus = focus - position
			var to_focus_length = to_focus.length()
			if to_focus_length > 0:
				var to_focus_dir = to_focus / to_focus_length

				if tracking == TrackingState.Follow:
					# AHHHHH stop following the edge when facing a cardinal direction
					#velocity += to_focus_dir * (prey.thrust_speed * acceleration_factor * delta)
					#velocity = to_focus_dir * velocity.length()
					#velocity = prey_velocity + to_focus_dir * (velocity.length() + prey.thrust_speed * acceleration_factor * delta)
					#velocity = prey_velocity + to_focus_dir * (prey.thrust_speed * acceleration_factor * delta)

					var to_track = Vector2(half_view_size.x - track_threshold, half_view_size.y - track_threshold)
					var to_lock  = Vector2(half_view_size.x -  lock_threshold, half_view_size.y -  lock_threshold)
					var threshold_portions = Vector2(
							clamp((abs(to_prey.x) - to_track.x) / (to_lock.x - to_track.x), 0, 1),
							clamp((abs(to_prey.y) - to_track.y) / (to_lock.y - to_track.y), 0, 1))
					var most_portion = max(threshold_portions.x, threshold_portions.y)
					velocity = to_focus_dir * max(velocity.length() + prey.thrust_speed * acceleration_factor * delta, prey_velocity.length() * max_relative_speed * most_portion)
					#if to_focus_dir.project(Vector2.RIGHT).dot((focus - (position + velocity * delta)).normalized()) < 0:
					#	position.x = prey.position.x
					#	velocity.x = 0
				elif tracking == TrackingState.Lead:
					velocity += to_focus_dir * (prey.thrust_speed * acceleration_factor * delta)
					var vel_para_to_focus = velocity.project(to_focus_dir)
					var vel_perp_to_focus = velocity - vel_para_to_focus
					#vel_para_to_focus += to_focus_dir * (prey.thrust_speed * acceleration_factor * delta)
					vel_perp_to_focus *= 0.9
					velocity = vel_para_to_focus + vel_perp_to_focus

				#var vel_rotation = min(PI / 6 * delta, acos(velocity.normalized().dot(to_focus_dir)))
				#var rotated_vel = velocity#.rotated(vel_rotation)
				#velocity = rotated_vel + (rotated_vel.normalized() * (prey.thrust_speed * acceleration_factor * delta))
				#velocity = to_focus_dir * (velocity.length() + (prey.thrust_speed * acceleration_factor * delta))
				#velocity = to_focus_dir * (velocity.normalized() + prey_speed * acceleration_factor)
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

	#if (position - prey.position).length_squared() > lock_threshold * lock_threshold:
	#	position = prey.position + ((position - prey.position).normalized() * lock_threshold)
	#if abs(prey.position.x - position.x) > half_view_size.x - lock_threshold:

	if prey.position.x - position.x < lock_threshold - half_view_size.x:
		velocity = prey.linear_velocity
		position.x = prey.position.x - (lock_threshold - half_view_size.x)
	elif prey.position.x - position.x > half_view_size.x - lock_threshold:
		velocity = prey.linear_velocity
		position.x = prey.position.x - (half_view_size.x - lock_threshold)

	if prey.position.y - position.y < lock_threshold - half_view_size.y:
		velocity = prey.linear_velocity
		position.y = prey.position.y - (lock_threshold - half_view_size.y)
	elif prey.position.y - position.y > half_view_size.y - lock_threshold:
		velocity = prey.linear_velocity
		position.y = prey.position.y - (half_view_size.y - lock_threshold)

	if OS.has_feature("editor"):
		queue_redraw()
