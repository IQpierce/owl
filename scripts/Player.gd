extends Creature

class_name Player

@export var thrust_speed := 10
@export var turn_speed := 10

var thrusting:bool

signal thrusting_state_change(enabled:bool)
signal shot_fired()

func _physics_process(delta):
	if Input.is_action_pressed("turn_left"):
		# Move as long as the key/button is pressed.
		angular_velocity -= delta * turn_speed	
	elif Input.is_action_pressed("turn_right"):
		# Move as long as the key/button is pressed.
		angular_velocity += delta * turn_speed	
	
	if Input.is_action_pressed("thrust"):
		var facing_dir:Vector2 = Vector2(0, 1).rotated(rotation)
		linear_velocity -= (facing_dir * delta * thrust_speed)
		
		if (!thrusting):
			thrusting_state_change.emit(true)
			thrusting = true			
	elif (thrusting):
		thrusting_state_change.emit(false)	
		thrusting = false
	
	if Input.is_action_pressed("shoot"):
		shot_fired.emit()
