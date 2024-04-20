extends Node2D
class_name Locomotor

static var stop_below_speed: = 15

@export var drive_force:float = 400
@export var turn_force:float = 50
## Cannot accelerate to a higher speed paralell current velocity. Acceleration perpendicular to velocity is still considered. This does not limit the speed caused by outside forces, but velocity will eventually settle back to this.
@export var max_speed:float = 3000
## NOTHING in the world can make you go faster
@export var hard_speed_limit:float = 7000 # TODO should this be world property that all things follow? Maybe a property on a parent?
## Ignore the hard_speed_limit so forces in the worldcan move you faster
@export var ignore_speed_limit:bool = false
@export_range(0, 1) var peak_band_min:float = 0.5
@export_range(0, 1) var peak_band_max:float = 0.75
@export_range(0.25, 1) var drive_outside_band:float = 0.5
## Slow down when moving beyond max speed
@export var excessive_speed_linear_damp_factor:float = 1;
## Modifies deceleration while turning
@export var turn_linear_damp_factor:float = 1;
## Modifies turn speed while driving
@export var drive_turn_factor:float = 1;
## Modifies turn speed while firing
@export var fire_turn_factor:float = 1;
## Modifies turn speed when turning towards direction of velocity (allows bias in favor of turning around)
@export var turn_with_velocity_turn_factor:float = 1;
## Modifies max speed while firing
@export var fire_max_speed_factor:float = 1;
## Modifies acceleration while firing
@export var fire_acceleration_factor:float = 1;
# TODO BEN had an idea for strafing... could be double OR use right-stick as boosts (in any direction)
# might want to look into the  _integrate_forces() callback
@export var side_boost:float

var _body:Thing
var camera:Camera2D
var driving:bool
var turning_left:bool
var turning_right:bool
var at_max_speed:bool
var _body_lock_rotation:bool

var body:Thing:
	get:
		return _body
	set(value):
		_body = value
		_body_lock_rotation = _body.lock_rotation

signal driving_state_change(enabled:bool)
signal turning_left_state_change(enabled:bool)
signal turning_right_state_change(enabled:bool)

func _compute_turn(turn_towards_global:Vector2, turn_fraction:float, delta:float) -> float:
	if _body == null:
		return 0.0

	var turn_factor = 0
	turn_fraction = max(turn_fraction, 0)
	var to_turn_towards = (turn_towards_global - _body.global_position)
	if to_turn_towards.length_squared() > 0:
		to_turn_towards = to_turn_towards.normalized()
		var up = Vector2.UP.rotated(_body.global_rotation)
		var right = Vector2.RIGHT.rotated(_body.global_rotation)
		var axis = 1
		if right.dot(to_turn_towards) < 0:
			axis = -1
		var angle = acos(up.dot(to_turn_towards)) * axis
		var max_angular_speed = turn_force * delta
		#print("delta ", delta)
		turn_factor = clamp(angle / max_angular_speed, -1, 1)
		#print(angle / PI * 180, " / ", max_angular_speed / PI * 180, " = ", turn_factor)
	return turn_factor * turn_fraction

func turn(turn_factor:float, turn_drift:float, delta:float):
	if _body == null:
		return

	#var turn_drift = 1.0

	var heading_dir:Vector2 = Vector2.UP.rotated(_body.global_rotation)

	if turn_factor < 0:
		if !turning_left:
			turning_left_state_change.emit(true)
			turning_left = true
	elif turning_left:
			turning_left_state_change.emit(false)
			turning_left = false

	if turn_factor > 0:
		if !turning_right:
			turning_right_state_change.emit(true)
			turning_right = true
	elif turning_right:
			turning_right_state_change.emit(false)
			turning_right = false

	if heading_dir.rotated(_body.angular_velocity * delta).dot(_body.linear_velocity) >= heading_dir.dot(_body.linear_velocity):
		turn_drift *= turn_with_velocity_turn_factor;

	# Godot Phyics applies damp as val *= 1.0 - step * damp (where step is essentially delta)
	# We can combine that damp with ours to approximate a true max_turn_speed and the artificially reduce that
	var approx_ang_damp = (1 - (delta * _body.angular_damp)) * turn_drift
	var new_turn_speed = _body.angular_velocity + turn_force * turn_factor * delta
	if (_body.angular_velocity > 0 && turn_factor < 0) || (_body.angular_velocity < 0 && turn_factor > 0):
		# Allow some finesse when changing direction to avoid ping-ponging
		_body.angular_velocity *= 0.5
		turn_factor *= 0.5

	if abs(_body.angular_velocity) < 0.001:
		_body.angular_velocity = 0

	if abs(new_turn_speed * approx_ang_damp * turn_factor) > abs(_body.angular_velocity):
		_body.angular_velocity = new_turn_speed
	_body.angular_velocity *= turn_drift
	#if turn_factor == 0:
	#	_body.angular_velocity *= 0.75
	#print(_body.angular_velocity, " | ", approx_ang_damp)

func turn_towards(turn_towards_global:Vector2, turn_fraction:float, delta:float):
	var turn_factor = _compute_turn(turn_towards_global, turn_fraction, delta)
	turn(turn_factor, 1, delta)

func drive(drive_factor:float, drive_drift:float, delta:float, relative_direction:Vector2 = Vector2.UP):
	if _body == null:
		return

	var time_now = Time.get_ticks_msec()
	var anti_zoom = OwlGame.instance.anti_zoom()

	var max_speed_factor = 1.0
	var acceleration_factor = drive_factor

	var heading_dir:Vector2 = relative_direction.normalized().rotated(_body.global_rotation)

	var cap_speed = max_speed * max_speed_factor * anti_zoom
	at_max_speed = false

	if drive_factor > 0:
		var speed_portion = clamp((_body.linear_velocity.length() / max_speed) * heading_dir.dot(_body.linear_velocity.normalized()), 0, 1)
		var band_portion = 1.0
		if speed_portion < peak_band_min:
			band_portion = speed_portion / peak_band_min
		elif speed_portion > peak_band_max:
			band_portion = (1 - speed_portion) / (1 - peak_band_max)
		var drive_lerp = ((1 - band_portion) * drive_outside_band) + band_portion
		var drive_delta = drive_force * drive_lerp * delta;
		var acceleration = heading_dir * drive_delta;

		if _body.linear_velocity.length_squared() > 0:
			var velocity_dir = _body.linear_velocity.normalized()
			var head_para_vel:Vector2 = heading_dir.project(velocity_dir)
			var head_perp_vel:Vector2 = heading_dir - head_para_vel

			var drive_para_vel = head_para_vel * drive_delta
			var potential_velocity:Vector2 = _body.linear_velocity + drive_para_vel
			if _body.linear_velocity.length_squared() > (cap_speed * cap_speed):
				head_para_vel = Vector2.ZERO
			elif potential_velocity.length_squared() > (cap_speed * cap_speed) && head_para_vel.dot(velocity_dir) > 0:
				var excess = potential_velocity - (velocity_dir * cap_speed)
				head_para_vel *= (drive_para_vel - excess).length() / drive_para_vel.length()
				at_max_speed = true
				
			acceleration = head_para_vel + head_perp_vel

		acceleration *= acceleration_factor

		_body.apply_central_impulse(acceleration * drive_delta * anti_zoom)

		var hard_speed_cap = hard_speed_limit * anti_zoom
		if !ignore_speed_limit && _body.linear_velocity.length_squared() > hard_speed_cap * hard_speed_cap:
			_body.linear_velocity = _body.linear_velocity * hard_speed_cap

		if (!driving):
			driving = true
			driving_state_change.emit(true)
	else:
		if driving:
			driving = false
			driving_state_change.emit(false)

	if _body.linear_velocity.length_squared() > (cap_speed * cap_speed):
		drive_drift *= excessive_speed_linear_damp_factor;

	if drive_drift <= 0.99: # Cannot trust 1 to mean 1 every frame apparantly; maybe it is the rigidbody damping
		_body.linear_velocity *= drive_drift

	# TODO (sam) need to force velocity to zero if near it, because there are some calculations that behave subtely different 
	var min_speed = stop_below_speed * anti_zoom
	if !driving && _body.linear_velocity.length_squared() < min_speed * min_speed:
		_body.linear_velocity = Vector2.ZERO

func locomote(drive_factor:float, turn_factor:float, delta:float, relative_direction:Vector2 = Vector2.UP):
	var drive_drift = 1.0
	var turn_drift = 1.0

	if !driving && turn_factor != 0:
		drive_drift *= turn_linear_damp_factor

	if driving:
		turn_drift *= drive_turn_factor

	# TODO (sam) Are we cool checking exactly Zero here or do we need is_equal_approx
	# TODO (sam) Is there a way to separate this between turn and drive?
	if turn_factor != 0 || drive_factor != 0:
		_body.lock_rotation = true
	else:
		_body.lock_rotation = _body_lock_rotation
	
	drive(drive_factor, drive_drift, delta, relative_direction)
	turn(turn_factor, turn_drift, delta)

func locomote_towards(drive_factor:float, turn_towards_global:Vector2, turn_fraction:float, delta:float):
	var turn_factor = _compute_turn(turn_towards_global, turn_fraction, delta)
	locomote(drive_factor, turn_factor, delta)
