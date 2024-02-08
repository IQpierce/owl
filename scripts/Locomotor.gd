extends Node2D
class_name Locomotor

static var stop_below_speed: = 15

@export var drive_force:float
@export var turn_force:float
## Cannot accelerate to a higher speed paralell current velocity. Acceleration perpendicular to velocity is still considered. This does not limit the speed caused by outside forces, but velocity will eventually settle back to this.
@export var max_speed:float = 3000
## NOTHING in the world can make you go faster
@export var hard_speed_limit:float = 7000 # TODO should this be world property that all things follow? Maybe a property on a parent?
## Ignore the hard_speed_limit so forces in the worldcan move you faster
@export var ignore_speed_limit:bool = false
## Slow down when moving beyond max speed
@export_range(0.25, 1) var drive_at_max_speed:float = 0.5
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

var body:Thing
var camera:Camera2D
var driving:bool
var turning_left:bool
var turning_right:bool
var at_max_speed:bool

signal driving_state_change(enabled:bool)
signal turning_left_state_change(enabled:bool)
signal turning_right_state_change(enabled:bool)

func _ready():
	body = get_parent() as Thing
	if body == null:
		push_warning("Locomotor expects Thing node to be direct parent")

func locomote(drive_factor:float, turn_factor:float, delta:float):
	if body == null:
		return

	var time_now = Time.get_ticks_msec()

	var turn_damp_factor = 1.0
	var linear_damp_factor = 1.0
	var max_speed_factor = 1.0
	var acceleration_factor = drive_factor

	var heading_dir:Vector2 = Vector2.UP.rotated(body.rotation)

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

	if heading_dir.rotated(body.angular_velocity * delta).dot(body.linear_velocity) >= heading_dir.dot(body.linear_velocity):
		turn_damp_factor *= turn_with_velocity_turn_factor;

	var cap_speed = max_speed * max_speed_factor;
	at_max_speed = false

	if drive_factor > 0:
		var speed_portion = clamp((body.linear_velocity.length() / max_speed) * heading_dir.dot(body.linear_velocity.normalized()), 0, 1)
		var drive_lerp = (1 - speed_portion) + (speed_portion * drive_at_max_speed)
		var drive_delta = drive_force * drive_lerp * delta;
		var acceleration = heading_dir * drive_delta;

		if body.linear_velocity.length_squared() > 0:
			var velocity_dir = body.linear_velocity.normalized()
			var head_para_vel:Vector2 = heading_dir.project(velocity_dir)
			var head_perp_vel:Vector2 = heading_dir - head_para_vel

			var drive_para_vel = head_para_vel * drive_delta
			var potential_velocity:Vector2 = body.linear_velocity + drive_para_vel
			if body.linear_velocity.length_squared() > (cap_speed * cap_speed):
				head_para_vel = Vector2.ZERO
			elif potential_velocity.length_squared() > (cap_speed * cap_speed) && head_para_vel.dot(velocity_dir) > 0:
				var excess = potential_velocity - (velocity_dir * cap_speed)
				head_para_vel *= (drive_para_vel - excess).length() / drive_para_vel.length()
				at_max_speed = true
				
			acceleration = head_para_vel + head_perp_vel

		acceleration *= acceleration_factor

		body.apply_central_impulse(acceleration * drive_delta)

		if !ignore_speed_limit && body.linear_velocity.length_squared() > hard_speed_limit * hard_speed_limit:
			body.linear_velocity = body.linear_velocity * hard_speed_limit

		if (!driving):
			driving = true
			driving_state_change.emit(true)
	else:
		if driving:
			driving = false
			driving_state_change.emit(false)

	if body.linear_velocity.length_squared() > (cap_speed * cap_speed):
		linear_damp_factor *= excessive_speed_linear_damp_factor;

	if !driving && turn_factor != 0:
		linear_damp_factor *= turn_linear_damp_factor

	if driving:
		turn_damp_factor *= drive_turn_factor

	if linear_damp_factor <= 0.99: # Cannot trust 1 to mean 1 every frame apparantly; maybe it is the rigidbody damping
		body.linear_velocity *= linear_damp_factor

	body.angular_velocity += turn_force * turn_factor * delta
	body.angular_velocity *= turn_damp_factor
	

	# TODO (sam) need to force velocity to zero if near it, because there are some calculations that behave subtely different 
	if !driving && body.linear_velocity.length_squared() < stop_below_speed * stop_below_speed:
		body.linear_velocity = Vector2.ZERO

