extends CameraCartridge
class_name TrackThrusterCameraCartridge

@export var locomotor:Locomotor = null
@export var hopdart:Hopdart = null
@export var track_threshold:float = 300
@export var lock_threshold:float = 100
@export var max_relative_speed:float = 1
@export var acceleration_factor:float = 1
@export var lead_distance = 0
@export_range(0, 1) var rest_vel_damp = 0.98
@export_range(0.5, 1) var lead_vel_perp_damp = 0.9
@export var follow_slow_to_rest_ms = 300
@export var lead_turn_to_rest_ms = 300

var prey:Thing
var prey_offset:Vector2
var old_prey_offset:Vector2
var prey_velocity:Vector2
var prey_bearing:Vector2
var fallback_start:int

var track_rect:Rect2
var lock_rect:Rect2

# TODO (sam) We might want a "Reserve" state that make returning to Lead easier for a brief period
enum TrackingState { Rest, Follow, Lead, Recenter }
var tracking = TrackingState.Rest

func build_plan(delta:float, data_rig:CameraRig) -> CameraRig.ExclusivePlan:
	#TODO (sam) instead of using prey we probably want to find the parent Thing or Node
	var prey = null
	if locomotor != null:
		prey = locomotor.body as Thing

	plan.copy_rig(data_rig)

	#TODO (sam) use the body that Locomotor is tracking
	plan.prey = prey

	if !visible || prey == null:
		return plan

	var prey_pos = prey.global_position + prey_offset
	var focus = prey_pos

	var view_size = data_rig.view_size()
	var half_view_size = view_size / 2

	if locomotor != null && prey != null:
		var to_prey = prey_pos - plan.position
		var prey_dist_sqr = to_prey.length_squared()
		var prey_heading = Vector2.UP.rotated(prey.global_rotation)
		prey_bearing = Vector2.ZERO
		var prey_speed = prey.linear_velocity.length()
		if prey_speed > 0:
			prey_bearing = prey.linear_velocity / prey_speed

		focus = prey_pos + (prey_bearing * lead_distance)
		var to_focus = focus - plan.position

		var to_prey_soon = prey_pos + (prey.linear_velocity * delta * 2) - plan.position

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
			var within_tracking_x = abs(prey_pos.x - plan.position.x) > half_view_size.x - track_threshold
			var within_tracking_y = abs(prey_pos.y - plan.position.y) > half_view_size.y - track_threshold
			if (within_tracking_x || within_tracking_y) && prey.linear_velocity.dot(prey_pos - plan.position) > 0:
				tracking = TrackingState.Follow
		elif tracking == TrackingState.Follow:
			if prey.linear_velocity.length_squared() < prey_velocity.length_squared():
				if Time.get_ticks_msec() - fallback_start >= follow_slow_to_rest_ms:
					tracking = TrackingState.Rest
			else:
				fallback_start = Time.get_ticks_msec()
				if plan.velocity.dot(prey_pos - plan.position) <= 0:
					if to_prey.project(prey_heading).dot(to_prey_soon.project(prey_heading)) <= 0:
						tracking = TrackingState.Lead
					else:
						tracking = TrackingState.Rest
				else:
					if prey.linear_velocity.dot(prey_velocity) <= 0:
						tracking = TrackingState.Rest
		elif tracking == TrackingState.Lead:
			if prey_heading.dot((plan.position - prey_pos).project(prey.linear_velocity.normalized())) <= 0:
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

		if recenter:
			plan.velocity = (to_focus).normalized() * min(min(plan.velocity.length() + 20, 200), to_focus.length())
			tracking = TrackingState.Rest

		if tracking == TrackingState.Rest:
			plan.velocity *= rest_vel_damp
			plan.position += prey_offset - old_prey_offset
		else:
			var to_focus_length = to_focus.length()
			if to_focus_length > 0:
				var to_focus_dir = to_focus / to_focus_length

				if tracking == TrackingState.Follow:
					# When Follow starts accelerate based on how far beyond tracking threshold the prey is.
					# As we attempt to take the lead though, accelerate regardless of tracking threshold
					var accelerated_speed = plan.velocity.length()# + prey.get_thrust_speed() * acceleration_factor * delta
					var prey_relative_speed = prey_velocity.length() * tracking_importance

					if locomotor.driving && prey_heading.dot(to_prey) > 0:
						accelerated_speed += locomotor.drive_force * acceleration_factor * delta
						prey_relative_speed *= max_relative_speed
					plan.velocity = to_focus_dir * max(accelerated_speed, prey_relative_speed)

					if plan.velocity.dot(prey_heading) < 0:
						plan.velocity = plan.velocity.normalized() * prey_velocity.length()
				elif tracking == TrackingState.Lead:
					# When leading accelerate normally, but manually narrow center the prey perpendicular to its bearing
					var to_fuzzy_focus = to_focus#to_focus.project(prey.linear_velocity)
					if hopdart != null && hopdart.engaged:
						# TODO (sam) I'd like to delay the camera following after a hopdart, but can't get it quite right
						var fuzzy_focus = (prey_pos - hopdart.sum_move) + (prey_bearing * lead_distance)
						to_fuzzy_focus = fuzzy_focus - global_position
					var to_fuzzy_focus_dir = to_fuzzy_focus.normalized()
					plan.velocity += to_fuzzy_focus_dir * (locomotor.drive_force * acceleration_factor * delta)
					var vel_para_to_fuzzy_focus = plan.velocity.project(to_fuzzy_focus_dir)
					var vel_perp_to_fuzzy_focus = plan.velocity - vel_para_to_fuzzy_focus
					vel_perp_to_fuzzy_focus *= lead_vel_perp_damp
					#vel_para_to_fuzzy_focus = vel_para_to_fuzzy_focus.normalized() * max(vel_para_to_fuzzy_focus.length(), prey.linear_velocity.length())
					plan.velocity = vel_para_to_fuzzy_focus + vel_perp_to_fuzzy_focus
					#print(plan.velocity)
			else:
				plan.velocity = prey.linear_velocity

			var new_speed = plan.velocity.length()
			var max_speed = prey_speed * max_relative_speed
			if new_speed > max_speed:
				plan.velocity = (plan.velocity / new_speed) * max_speed

		# If very close to focus, just jump to it; otherwise, move at velocity
		var delta_vel = plan.velocity * delta
		if (focus - (plan.position + delta_vel)).dot(focus - plan.position) < 0:
			plan.position = focus
		else:
			plan.position += delta_vel

	# Prevent prey from moving off-screen on X
	if prey.global_position.x - plan.position.x < lock_threshold - half_view_size.x:
		plan.velocity = prey.linear_velocity
		plan.position.x = prey.global_position.x - (lock_threshold - half_view_size.x)
	elif prey.global_position.x - plan.position.x > half_view_size.x - lock_threshold:
		plan.velocity = prey.linear_velocity
		plan.position.x = prey.global_position.x - (half_view_size.x - lock_threshold)

	# Prevent prey from moving off-screen on Y
	if prey.global_position.y - plan.position.y < lock_threshold - half_view_size.y:
		plan.velocity = prey.linear_velocity
		plan.position.y = prey.global_position.y - (lock_threshold - half_view_size.y)
	elif prey.global_position.y - plan.position.y > half_view_size.y - lock_threshold:
		plan.velocity = prey.linear_velocity
		plan.position.y = prey.global_position.y - (half_view_size.y - lock_threshold)

	old_prey_offset = prey_offset
	return plan

func request_debug(drawee_rig:CameraRig) -> String:
	if drawee_rig != null:
		# Screen Center
		drawee_rig.draw_arc(Vector2.ZERO, 10, 0, TAU, 60, Color.WHITE)

		if tracking == TrackingState.Lead:
			#Lead Target
			#if prey_heading.dot((plan.position - prey.global_position).project(prey.linear_velocity.normalized())) <= 0:

			# Desired Screen Center (focus)
			var prey = get_parent() as Thing
			var relative_prey_pos = prey.global_position - drawee_rig.global_position
			var relative_lead_pos = relative_prey_pos + (prey_bearing * lead_distance)
			drawee_rig.draw_line(relative_lead_pos + Vector2(-10, -10), relative_lead_pos + Vector2(10, 10),  Color.WHITE)
			drawee_rig.draw_line(relative_lead_pos + Vector2(-10, 10),  relative_lead_pos + Vector2(10, -10), Color.WHITE)

			# Maintain Tracking or Rest Threshold
			var prey_perp = Vector2(relative_prey_pos.y, -relative_prey_pos.x).normalized() * 100
			drawee_rig.draw_dashed_line(relative_prey_pos - prey_perp, relative_prey_pos + prey_perp, Color.WHITE, 1.0, 10.0)

		if tracking != TrackingState.Lead:
			drawee_rig.draw_rect(track_rect, Color.GRAY, false, 2.0)

		drawee_rig.draw_rect(lock_rect, Color.GRAY, false, 4.0 * (tracking + 1))
	return TrackingState.keys()[tracking]
