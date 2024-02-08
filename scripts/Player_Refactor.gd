extends Player
class_name Player_Refactor

enum ControlMode { Tank, Roam }

# TODO (sam) This can be removed once locomotor does everything it needs, and camera follows it
@export var locomotor:Locomotor
# TODO if world_camera does not have a socket, take it as default ... make just make a script for that

@export var control_mode:ControlMode = ControlMode.Tank
@export_group("TankControls")
@export_group("RoamControls")
@export_group("")

## Window to input double tap of a key
#@export var double_tap_msec:float = 1;
#var thrust_tap_time:int = 0;
#var left_tap_time:int = 0;
#var right_tap_time:int = 0;

var camera:Camera2D

signal shot_fired()

func _physics_process(delta:float):
	var acceleration_fraction = 1.0
	var max_speed_fraction = 1.0
	var turn_factor = 0.0

	var drive_factor = 0.0

	if Input.is_action_pressed("thrust"):
		drive_factor += 1

	if Input.is_action_pressed("turn_left"):
		turn_factor -= 1

	if Input.is_action_pressed("turn_right"):
		turn_factor += 1

	if Input.is_action_pressed("shoot"):
		shot_fired.emit()
		#turn_damp_factor *= fire_turn_factor;
		#max_speed_factor *= fire_max_speed_factor;
		#acceleration_factor *= fire_acceleration_factor;

	if locomotor != null:
		locomotor.locomote(drive_factor, turn_factor, delta)

#		if Input.is_action_just_pressed("thrust"):
#			if time_now - drive_tap_time <= double_tap_msec && acceleration.dot(body.linear_velocity) < 0:
#				acceleration *= turn_around_acceleration_factor;
#				thrust_tap_time = 0
#			thrust_tap_time = time_now
#	if turning_left && !turning_right:
#		if Input.is_action_just_pressed("turn_left"):
#			if time_now - left_tap_time <= double_tap_msec:
#				#body.rotation -= quick_turn_degrees * PI / 180
#				body.linear_velocity -= Vector2.RIGHT.rotated(body.rotation) * side_boost
#				left_tap_time = 0
#			left_tap_time = time_now
#		else:
#			body.angular_velocity -= delta * turn_speed
#		if !driving:
#			linear_damp_factor *= turn_linear_damp_factor
#	if turning_right && !turning_left:
#		if Input.is_action_just_pressed("turn_right"):
#			if time_now - right_tap_time <= double_tap_msec:
#				#body.rotation += quick_turn_degrees * PI / 180
#				body.linear_velocity += Vector2.RIGHT.rotated(body.rotation) * side_boost
#				right_tap_time = 0
#			right_tap_time = time_now
#		else:
#			body.angular_velocity += delta * turn_speed
#		if !driving:
#			linear_damp_factor *= turn_linear_damp_factor
