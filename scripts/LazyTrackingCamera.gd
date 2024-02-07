extends Camera_Deprecated
class_name LazyTrackingCamera

@export_group("Debug")
@export var show_debug = true
@export var state_label:Label
@export_group("Tracking")
@export var prey:Player
@export var center_on_initialize:bool = true
#@export var track_radius = 400
@export var track_threshold:float = 300
@export var lock_threshold:float = 100
@export var max_relative_speed:float = 1
@export var acceleration_factor:float = 1
@export var lead_distance = 0
@export_range(0, 1) var rest_vel_damp = 0.98
@export_range(0.5, 1) var lead_vel_perp_damp = 0.9
@export var follow_slow_to_rest_ms = 300
@export var lead_turn_to_rest_ms = 300
@export_group("Curiosity")
@export var leash_length:float = 400
@export var wonder_speed:float = 250


var velocity:Vector2
var prey_velocity:Vector2
var prey_bearing:Vector2
var fallback_start:int

var track_rect:Rect2
var lock_rect:Rect2

# TODO (sam) We might want a "Reserve" state that make returning to Lead easier for a brief period
enum TrackingState { Rest, Follow, Lead }
var tracking = TrackingState.Rest

func get_prey() -> Node2D:
	return prey

func _ready():
	if prey:
		prey.set_camera(self)
		
		if center_on_initialize:
			global_position = prey.global_position

func _draw():
	if show_debug && prey:
		if state_label:
			state_label.visible = true
			state_label.text = TrackingState.keys()[tracking]

		if tracking == TrackingState.Lead:
			# Screen Center
			draw_arc(Vector2(0, 0), 10, 0, TAU, 60, Color.WHITE)

			# Desired Screen Center (focus)
			var relative_prey_pos = prey.position - position
			var relative_lead_pos = relative_prey_pos + (prey_bearing * lead_distance)
			draw_line(relative_lead_pos + Vector2(-10, -10), relative_lead_pos + Vector2(10, 10),  Color.WHITE)
			draw_line(relative_lead_pos + Vector2(-10, 10),  relative_lead_pos + Vector2(10, -10), Color.WHITE)

			# Maintain Tracking or Rest Threshold
			var prey_perp = Vector2(relative_prey_pos.y, -relative_prey_pos.x).normalized() * 100
			draw_dashed_line(relative_prey_pos - prey_perp, relative_prey_pos + prey_perp, Color.WHITE, 1.0, 10.0)

		if tracking != TrackingState.Lead:
			draw_rect(track_rect, Color.GRAY, false, 2.0)
			#draw_arc(Vector2(0, 0), track_radius, 0, TAU, 60, Color.GRAY)

		draw_rect(lock_rect, Color.GRAY, false, 4.0 * (tracking + 1))
	else:
		if state_label:
			state_label.visible = false

func _physics_process(delta):
	if !visible || prey == null:
		return

	var focus = position

	var view_size = get_viewport().size # TODO Is this bad to call every frame?
	view_size = Vector2(view_size.x / zoom.x, view_size.y / zoom.y)
	var half_view_size = view_size / 2

	if prey != null:
		var to_prey = prey.position - position
		var prey_dist_sqr = to_prey.length_squared()
		var prey_heading = Vector2.UP.rotated(prey.rotation)
		prey_bearing = Vector2.ZERO
		var prey_speed = prey.linear_velocity.length()
		if prey_speed > 0:
			prey_bearing = prey.linear_velocity / prey_speed

		focus = prey.position + (prey_bearing * lead_distance)
		var to_focus = focus - position

		var to_prey_soon = prey.position + (prey.linear_velocity * delta * 2) - position

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
			var within_tracking_x = abs(prey.position.x - position.x) > half_view_size.x - track_threshold
			var within_tracking_y = abs(prey.position.y - position.y) > half_view_size.y - track_threshold
			if (within_tracking_x || within_tracking_y) && prey.linear_velocity.dot(prey.position - position) > 0:
			#if to_prey.length_squared() > track_radius * track_radius:
				tracking = TrackingState.Follow
		elif tracking == TrackingState.Follow:
			if prey.linear_velocity.length_squared() < prey_velocity.length_squared():
				if Time.get_ticks_msec() - fallback_start >= follow_slow_to_rest_ms:
					tracking = TrackingState.Rest
			else:
				fallback_start = Time.get_ticks_msec()
				if velocity.dot(prey.position - position) <= 0:
					if to_prey.project(prey_heading).dot(to_prey_soon.project(prey_heading)) <= 0:
						tracking = TrackingState.Lead
					else:
						tracking = TrackingState.Rest
				else:
					if prey.linear_velocity.dot(prey_velocity) <= 0:
						tracking = TrackingState.Rest
		elif tracking == TrackingState.Lead:
			if prey_heading.dot(position - prey.position) <= 0:
				if Time.get_ticks_msec() - fallback_start >= lead_turn_to_rest_ms:
					tracking = TrackingState.Rest
			else:
				fallback_start = Time.get_ticks_msec()

		prey_velocity = prey.linear_velocity

		var to_track = Vector2(half_view_size.x - track_threshold, half_view_size.y - track_threshold)
		#var to_track = Vector2(track_radius, track_radius)#Vector2(half_view_size.x - track_threshold, half_view_size.y - track_threshold)
		var to_lock  = Vector2(half_view_size.x -  lock_threshold, half_view_size.y -  lock_threshold)
		var threshold_portions = Vector2(
				clamp((abs(to_prey.x) - to_track.x) / (to_lock.x - to_track.x), 0, 1),
				clamp((abs(to_prey.y) - to_track.y) / (to_lock.y - to_track.y), 0, 1))
		var tracking_importance = max(threshold_portions.x, threshold_portions.y)

		if tracking == TrackingState.Rest:
			velocity *= rest_vel_damp
		else:
			var to_focus_length = to_focus.length()
			if to_focus_length > 0:
				var to_focus_dir = to_focus / to_focus_length

				if tracking == TrackingState.Follow:
					# When Follow starts accelerate based on how far beyond tracking threshold the prey is.
					# As we attempt to take the lead though, accelerate regardless of tracking threshold
					var accelerated_speed = velocity.length()# + prey.get_thrust_speed() * acceleration_factor * delta
					var prey_relative_speed = prey_velocity.length() * tracking_importance

					if prey.get_thrusting() && prey_heading.dot(to_prey) > 0:
						accelerated_speed += prey.get_thrust_speed() * acceleration_factor * delta
						prey_relative_speed *= max_relative_speed
					velocity = to_focus_dir * max(accelerated_speed, prey_relative_speed)

					#TODO (sam) I would like the Follow to be reduces/eliminated if you are not traveling towards the near end of the screen
					#var to_prey_dir = to_prey.normalized()
					#if to_prey_dir.x < 0:
					#	velocity.x *= clamp(prey_bearing.dot(Vector2.LEFT), 0, 1)
					#elif to_prey_dir.x > 0:
					#	velocity.x *= clamp(prey_bearing.dot(Vector2.RIGHT), 0, 1)
					#if to_prey_dir.y < 0:
					#	velocity.y *= clamp(prey_bearing.dot(Vector2.UP), 0, 1)
					#elif to_prey_dir.y > 0:
					#	velocity.y *= clamp(prey_bearing.dot(Vector2.DOWN), 0, 1)

					if velocity.dot(prey_heading) < 0:
						velocity = velocity.normalized() * prey_velocity.length()
				elif tracking == TrackingState.Lead:
					# When leading accelerate normally, but manually narrow center the prey perpendicular to its bearing
					velocity += to_focus_dir * (prey.get_thrust_speed() * acceleration_factor * delta)
					var vel_para_to_focus = velocity.project(to_focus_dir)
					var vel_perp_to_focus = velocity - vel_para_to_focus
					vel_perp_to_focus *= lead_vel_perp_damp
					velocity = vel_para_to_focus + vel_perp_to_focus
			else:
				velocity = prey.linear_velocity

			var new_speed = velocity.length()
			var max_speed = prey_speed * max_relative_speed
			if new_speed > max_speed:
				velocity = (velocity / new_speed) * max_speed

		# If very close to focus, just jump to it; otherwise, move at velocity
		var hunt_pos = global_position
		var delta_vel = velocity * delta
		if (focus - (hunt_pos + delta_vel)).dot(focus - position) < 0:
			hunt_pos = focus
		else:
			hunt_pos += delta_vel

		var wonder_pos = hunt_pos
		if center_priority > 0:
			wonder_pos = global_position
			var wonder_destination = attention_center

			var prey_to_destination = wonder_destination - prey.global_position
			if prey_to_destination.length_squared() > leash_length * leash_length:
				prey_to_destination = prey_to_destination.normalized() * leash_length

			wonder_destination = prey.global_position + prey_to_destination
			var to_wonder = wonder_destination - global_position
			if to_wonder.length_squared() > wonder_speed * wonder_speed:
				to_wonder = to_wonder.normalized() * wonder_speed

			wonder_pos += (to_wonder + velocity) * delta

		global_position = ((1 - tracking_importance) * wonder_pos) + (tracking_importance * hunt_pos)
		center_priority = 0

	# Prevent prey from moving off-screen on X
	if prey.position.x - position.x < lock_threshold - half_view_size.x:
		velocity = prey.linear_velocity
		position.x = prey.position.x - (lock_threshold - half_view_size.x)
	elif prey.position.x - position.x > half_view_size.x - lock_threshold:
		velocity = prey.linear_velocity
		position.x = prey.position.x - (half_view_size.x - lock_threshold)

	# Prevent prey from moving off-screen on Y
	if prey.position.y - position.y < lock_threshold - half_view_size.y:
		velocity = prey.linear_velocity
		position.y = prey.position.y - (lock_threshold - half_view_size.y)
	elif prey.position.y - position.y > half_view_size.y - lock_threshold:
		velocity = prey.linear_velocity
		position.y = prey.position.y - (half_view_size.y - lock_threshold)

	# Only draw Debug display while in Editor
	if OS.has_feature("editor"):
		queue_redraw()
