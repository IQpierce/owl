extends Creature

class_name Player

@export var thrust_speed:float
@export var turn_speed:float
@export var test_feel:bool
@export var max_speed:float
@export var fire_turn_factor:float = 1;
@export var turn_linear_damp_factor: float = 1;

var thrusting:bool

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

	var turn_factor = 1;
	if Input.is_action_pressed("shoot"):
		shot_fired.emit()
		turn_factor = fire_turn_factor;
	
	var linear_damp_factor = 1;
	if Input.is_action_pressed("turn_left"):
		# Move as long as the key/button is pressed.
		angular_velocity -= delta * turn_speed * turn_factor
		linear_damp_factor = turn_linear_damp_factor
	elif Input.is_action_pressed("turn_right"):
		# Move as long as the key/button is pressed.
		angular_velocity += delta * turn_speed * turn_factor
		linear_damp_factor = turn_linear_damp_factor
	
	if Input.is_action_pressed("thrust"):
		var heading_dir:Vector2 = Vector2.UP.rotated(rotation)
		var thrust_delta = thrust_speed * delta;
		var acceleration = heading_dir * thrust_delta;

		if linear_velocity.length_squared() > 0:
			var velocity_dir = linear_velocity.normalized()
			var head_para_vel:Vector2 = heading_dir.project(velocity_dir)
			var head_perp_vel:Vector2 = heading_dir - head_para_vel

			var thrust_para_vel = head_para_vel * thrust_delta
			var potential_velocity:Vector2 = linear_velocity + thrust_para_vel
			if potential_velocity.length_squared() > (max_speed * max_speed) && head_para_vel.dot(velocity_dir) > 0:
				var excess = potential_velocity - (velocity_dir * max_speed)
				head_para_vel *= (thrust_para_vel - excess).length() / thrust_para_vel.length()
				scale *= 0.8 #TESTING make obvious that thrust is capped
				
			acceleration = head_para_vel + head_perp_vel

		apply_central_impulse(acceleration * thrust_delta)

		if (!thrusting):
			thrusting_state_change.emit(true)
			thrusting = true
	else:
		linear_velocity *= turn_linear_damp_factor;
		if thrusting:
			thrusting_state_change.emit(false)	
			thrusting = false
	

