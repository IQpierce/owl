extends Creature

class_name Player

@export var world:OwlGame
@export var thrust_speed:float
@export var turn_speed:float
## Cannot accelerate to a higher speed paralell current velocity. Acceleration perpendicular to velocity is still considered. This does not limit the speed caused by outside forces, but velocity will eventually settle back to this.
@export var max_speed:float = 3000
## NOTHING in the world can make you go faster
@export var hard_speed_limit:float = 7000 # TODO should this be world property that all things follow? Maybe a property on a parent?
## Ignore the hard_speed_limit so forces in the worldcan move you faster
@export var ignore_speed_limit:bool = false
## Slow down when moving beyond max speed
@export_range(0.25, 1) var thrust_at_max_speed:float = 0.5
@export var excessive_speed_linear_damp_factor:float = 1;
## Modifies deceleration while turning
@export var turn_linear_damp_factor:float = 1;
## Modifies turn speed while thrusters are enganged
@export var thrust_turn_factor:float = 1;
## Modifies turn speed while firing
@export var fire_turn_factor:float = 1;
## Modifies turn speed when turning towards direction of velocity (allows bias in favor of turning around)
@export var turn_with_velocity_turn_factor:float = 1;
## Modifies max speed while firing
@export var fire_max_speed_factor:float = 1;
## Modifies acceleration while firing
@export var fire_acceleration_factor:float = 1;
## Window to input double tap of a key
@export var double_tap_msec:float = 1;
## Extra Acceleration immediately after double tapping thrust while heading is anti-velocity
@export var turn_around_acceleration_factor:float = 1;

#@export var thrust_fire_factor:float = 1;

@onready var thrust = $Thrust


#TODO (strapp) not a fan of the quick turnaround... probably just better to make turn faster when thruster is off
## Immediate turn after double tapping a turn ... honestly this doesn't feel good
@export var quick_turn_degrees = 0;

var camera:Camera2D
var thrusting:bool
var turning_left:bool
var turning_right:bool
var thrust_tap_time:int = 0;
var left_tap_time:int = 0;
var right_tap_time:int = 0;

# TODO do we need the hard_speed_limit if we force you to stay in the bounds?
var last_inbounds_pos:Vector2
var camera_last_inbounds_pos:Vector2
var out_of_bounds:bool
var at_max_speed:bool

signal thrusting_state_change(enabled:bool)
signal turning_left_state_change(enabled:bool)
signal turning_right_state_change(enabled:bool)
signal shot_fired()

func _physics_process(delta):
	# TODO (sam) is this actually keeping us inbounds when we making a wonking collision
	#TODO Getting knocked out of bounds might have been a consequence of physics material on asteroids... removing that might fix
	#var pending_reposition = out_of_bounds
	#out_of_bounds = false
	#if world:
	#	if world.left_wall && position.x < world.left_wall.position.x:
	#		out_of_bounds = true
	#	if world.right_wall && position.x > world.right_wall.position.x:
	#		out_of_bounds = true
	#	if world.top_wall && position.y < world.top_wall.position.y:
	#		out_of_bounds = true
	#	if world.bottom_wall && position.y > world.bottom_wall.position.y:
	#		out_of_bounds = true

	#if out_of_bounds:
	#	if pending_reposition:
	#		if OS.has_feature("editor"):
	#			print("Out of Bounds at ", position, " - Moving back to ", last_inbounds_pos)
	#			#get_tree().paused = true
	#		position = last_inbounds_pos
	#		if camera:
	#			camera.position = camera_last_inbounds_pos
	#else:
	#	last_inbounds_pos = position
	#	if camera:
	#		camera_last_inbounds_pos = camera.position

	process_input_refac(delta)

func process_input_refac(delta):
	var time_now = Time.get_ticks_msec()

	var turn_damp_factor = 1;
	var linear_damp_factor = 1;
	var max_speed_factor = 1;
	var acceleration_factor = 1;

	var heading_dir:Vector2 = Vector2.UP.rotated(rotation)

	if Input.is_action_pressed("shoot"):
		shot_fired.emit()
		turn_damp_factor *= fire_turn_factor;
		max_speed_factor *= fire_max_speed_factor;
		acceleration_factor *= fire_acceleration_factor;

	if Input.is_action_pressed("turn_left"):
		if !turning_left:
			turning_left_state_change.emit(true)
			turning_left = true
	elif turning_left:
			turning_left_state_change.emit(false)
			turning_left = false

	if Input.is_action_pressed("turn_right"):
		if !turning_right:
			turning_right_state_change.emit(true)
			turning_right = true
	elif turning_right:
			turning_right_state_change.emit(false)
			turning_right = false

	if turning_left && !turning_right:
		if Input.is_action_just_pressed("turn_left"):
			if time_now - left_tap_time <= double_tap_msec:
				rotation -= quick_turn_degrees * PI / 180
				left_tap_time = 0
			left_tap_time = time_now
		else:
			angular_velocity -= delta * turn_speed
		if not thrusting:
			linear_damp_factor *= turn_linear_damp_factor
	if turning_right && !turning_left:
		if Input.is_action_just_pressed("turn_right"):
			if time_now - right_tap_time <= double_tap_msec:
				rotation += quick_turn_degrees * PI / 180
				right_tap_time = 0
			right_tap_time = time_now
		else:
			angular_velocity += delta * turn_speed
		if not thrusting:
			linear_damp_factor *= turn_linear_damp_factor

	if heading_dir.rotated(angular_velocity * delta).dot(linear_velocity) >= heading_dir.dot(linear_velocity):
		turn_damp_factor *= turn_with_velocity_turn_factor;

	var cap_speed = max_speed * max_speed_factor;
	at_max_speed = false

	if Input.is_action_pressed("thrust"):
		var speed_portion = clamp((linear_velocity.length() / max_speed) * heading_dir.dot(linear_velocity.normalized()), 0, 1)
		var thrust_lerp = (1 - speed_portion) + (speed_portion * thrust_at_max_speed)
		var thrust_delta = thrust_speed * thrust_lerp * delta;
		var acceleration = heading_dir * thrust_delta;

		if linear_velocity.length_squared() > 0:
			var velocity_dir = linear_velocity.normalized()
			var head_para_vel:Vector2 = heading_dir.project(velocity_dir)
			var head_perp_vel:Vector2 = heading_dir - head_para_vel

			var thrust_para_vel = head_para_vel * thrust_delta
			var potential_velocity:Vector2 = linear_velocity + thrust_para_vel
			if linear_velocity.length_squared() > (cap_speed * cap_speed):
				head_para_vel = Vector2.ZERO
			elif potential_velocity.length_squared() > (cap_speed * cap_speed) && head_para_vel.dot(velocity_dir) > 0:
				var excess = potential_velocity - (velocity_dir * cap_speed)
				head_para_vel *= (thrust_para_vel - excess).length() / thrust_para_vel.length()
				at_max_speed = true
				
			acceleration = head_para_vel + head_perp_vel

		acceleration *= acceleration_factor
		if Input.is_action_just_pressed("thrust"):
			if time_now - thrust_tap_time <= double_tap_msec && acceleration.dot(linear_velocity) < 0:
				acceleration *= turn_around_acceleration_factor;
				thrust_tap_time = 0
			thrust_tap_time = time_now

		apply_central_impulse(acceleration * thrust_delta)

		if !ignore_speed_limit && linear_velocity.length_squared() > hard_speed_limit * hard_speed_limit:
			linear_velocity = linear_velocity * hard_speed_limit

		if (!thrusting):
			thrusting_state_change.emit(true)
			thrust.play()
			thrusting = true
	else:
		if thrusting:
			thrusting_state_change.emit(false)
			thrust.stop()
			thrusting = false

	if linear_velocity.length_squared() > (cap_speed * cap_speed):
		linear_damp_factor *= excessive_speed_linear_damp_factor;

#todo is this not working
#todo could turning around be faster, like if you are turning against your velocity you turn faster
	if thrusting:
		turn_damp_factor *= thrust_turn_factor

	if linear_damp_factor <= 0.99: # Cannot trust 1 to mean 1 every frame apparantly; maybe it is the rigidbody damping
		linear_velocity *= linear_damp_factor

	angular_velocity *= turn_damp_factor

	# TODO (sam) need to force velocity to zero if near it, because there are some calculations that behave subtely different 
	#if linear_velocity.length_squared() < 0.000001:
	#	linear_velocity = Vector2.ZERO

