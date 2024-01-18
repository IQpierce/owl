extends Creature

class_name Player

@export var thrust_speed:float
@export var turn_speed:float
## Enables uses of parameters below
@export var test_feel:bool
## Cannot accelerate to a higher speed paralell current velocity. Acceleration perpendicular to velocity is still considered. This does not limit the speed caused by outside forces, but velocity will eventually settle back to this.
@export var max_speed:float
## Slow down when moving beyond max speed
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

#TODO (strapp) not a fan of the quick turnaround... probably just better to make turn faster when thruster is off
## Immediate turn after double tapping a turn ... honestly this doesn't feel good
@export var quick_turn_degrees = 0;

var camera:Camera2D
var thrusting:bool
var thrust_tap_time:int = 0;
var left_tap_time:int = 0;
var right_tap_time:int = 0;

signal thrusting_state_change(enabled:bool)
signal shot_fired()

func _physics_process(delta):
	if test_feel:
		process_input_refac(delta)
	else:
		process_input(delta)

func process_input(delta):
	if Input.is_action_pressed("turn_left"):
		# Move as long as the key/button is pressed.
		angular_velocity -= delta * turn_speed	
	elif Input.is_action_pressed("turn_right"):
		# Move as long as the key/button is pressed.
		angular_velocity += delta * turn_speed	
	
	if Input.is_action_pressed("thrust"):
		var facing_dir:Vector2 = Vector2.UP.rotated(rotation)
		#linear_velocity -= (facing_dir * delta * thrust_speed)
		apply_central_impulse(facing_dir * delta * thrust_speed)
		
		if (!thrusting):
			thrusting_state_change.emit(true)
			thrusting = true
	elif (thrusting):
		thrusting_state_change.emit(false)	
		thrusting = false
	
	if Input.is_action_pressed("shoot"):
		shot_fired.emit()

func process_input_refac(delta):
	# TODO (sam) Max Speed, alter turn speed when firing, figure out feel
	# Double tap to get 1.5 max speed for a bit 
	# Double tap turn to spin 180
	# Turning causes more drag when not accelerating

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
		if Input.is_action_just_pressed("turn_left"):
			if time_now - left_tap_time <= double_tap_msec:
				rotation -= quick_turn_degrees * PI / 180
				left_tap_time = 0
			left_tap_time = time_now
		else:
			angular_velocity -= delta * turn_speed
		linear_damp_factor *= turn_linear_damp_factor
	elif Input.is_action_pressed("turn_right"):
		if Input.is_action_just_pressed("turn_right"):
			if time_now - right_tap_time <= double_tap_msec:
				rotation += quick_turn_degrees * PI / 180
				right_tap_time = 0
			right_tap_time = time_now
		else:
			angular_velocity += delta * turn_speed
		linear_damp_factor *= turn_linear_damp_factor

	if heading_dir.rotated(angular_velocity * delta).dot(linear_velocity) >= heading_dir.dot(linear_velocity):
		turn_damp_factor *= turn_with_velocity_turn_factor;

	var cap_speed = max_speed * max_speed_factor;

	if true:#Input.is_action_pressed("thrust"):
		var thrust_delta = thrust_speed * delta;
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
				scale *= 0.9 #TESTING make obvious that thrust is capped
				
			acceleration = head_para_vel + head_perp_vel

		acceleration *= acceleration_factor
		if Input.is_action_just_pressed("thrust"):
			if time_now - thrust_tap_time <= double_tap_msec && acceleration.dot(linear_velocity) < 0:
				acceleration *= turn_around_acceleration_factor;
				thrust_tap_time = 0
			thrust_tap_time = time_now

		apply_central_impulse(acceleration * thrust_delta)

		if (!thrusting):
			thrusting_state_change.emit(true)
			thrusting = true
	else:
		if thrusting:
			thrusting_state_change.emit(false)
			thrusting = false

	if linear_velocity.length_squared() > (cap_speed * cap_speed):
		linear_damp_factor *= excessive_speed_linear_damp_factor;

	#print(linear_velocity)

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

