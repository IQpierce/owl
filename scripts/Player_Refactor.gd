extends Player
class_name Player_Refactor

enum ControlMode { Dynamic, Roam, Tank }

# TODO (sam) This can be removed once locomotor does everything it needs, and camera follows it
@export var locomotor:Locomotor
# TODO if world_camera does not have a socket, take it as default ... make just make a script for that

@export var control_mode:ControlMode = ControlMode.Roam
@export var allow_mouse:bool = true
@export_range(0, 1) var mouse_sensitivity:float = 0
@export_range(0, 60) var mouse_gravity: float = 30
@export_group("TankControls")
@export_group("RoamControls")
@export_group("")

## Window to input double tap of a key
#@export var double_tap_msec:float = 1;
#var thrust_tap_time:int = 0;
#var left_tap_time:int = 0;
#var right_tap_time:int = 0;

var camera_rig:CameraRig
var mouse_position:Vector2 = Vector2.ZERO
var mouse_motion:Vector2 = Vector2.ZERO

signal shot_fired()

func _ready():
	var scene = OwlGame.instance.scene
	if scene != null:
		camera_rig = scene.world_camera as CameraRig

func _input(event:InputEvent):
	if event is InputEventMouseMotion:
		mouse_position = event.position
		mouse_motion = event.relative

func _physics_process(delta:float):
	if !process_gamepad(delta):
		process_keyboard_mouse(delta)

func process_gamepad(delta:float) -> bool:
	var gamepad_acting = false
	if control_mode == ControlMode.Roam || control_mode == ControlMode.Dynamic:
		var drive_factor = 0.0
		var want_dir = Vector2.ZERO
		var turn_fraction = 1.0

		if Input.is_action_pressed("roam_gamepad_thrust"):
			drive_factor += 1
		else:
			drive_factor += Input.get_action_strength("roam_gamepad_thrust_axis")

		want_dir.x = Input.get_axis("left_gamepad_primary", "right_gamepad_primary")
		want_dir.y = Input.get_axis("up_gamepad_primary", "down_gamepad_primary")
		gamepad_acting = gamepad_acting || drive_factor > 0 || want_dir.length_squared()

		if gamepad_acting && locomotor != null:
			locomotor.locomote_towards(drive_factor, global_position + want_dir, turn_fraction, delta)
	elif control_mode == ControlMode.Tank:
		var drive_factor = Input.get_action_strength("up_gamepad_primary")
		var turn_factor = Input.get_axis("left_gamepad_primary", "right_gamepad_primary")

		gamepad_acting = gamepad_acting || drive_factor > 0 || turn_factor > 0

		if gamepad_acting && locomotor != null:
			locomotor.locomote(drive_factor, turn_factor, delta)

	if Input.is_action_pressed("shoot_gamepad"):
		gamepad_acting = true
		shot_fired.emit()

	return gamepad_acting

func process_keyboard_mouse(delta:float):
	# OS-level commands and such should override player controls (eg. CMD-SHIFT-5 for screen record on macOS)
	if Input.is_action_pressed("ignore_input"):
		return

	var mouse_pressed = allow_mouse && Input.is_action_pressed("mouse_left_click")
	var mouse_moved = false
	var view_speed = 1

	if mouse_motion.length_squared() > 0:
		mouse_moved = true
		if camera_rig != null:
			var view_size = camera_rig.view_size()
			var slowest_view = min(view_size.x, view_size.y)
			var fastest_view = slowest_view / 64;
			view_speed = (mouse_sensitivity * slowest_view) + ((1 - mouse_sensitivity) * fastest_view)

	if control_mode == ControlMode.Roam:
		var drive_factor = 0.0
		var want_dir = Vector2.ZERO
		var turn_fraction = 1.0

		if Input.is_action_pressed("roam_thrust") || mouse_pressed:
			drive_factor += 1

		if Input.is_action_pressed("up_primary"):
			want_dir.y -= 1

		if Input.is_action_pressed("down_primary"):
			want_dir.y += 1

		if Input.is_action_pressed("left_primary"):
			want_dir.x -= 1

		if Input.is_action_pressed("right_primary"):
			want_dir.x += 1

		if mouse_moved:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
		#	var mouse_turn = clamp(mouse_motion.x * PI / view_speed, -1, 1)
		#	want_dir = Vector2.UP.rotated(global_rotation).rotated(mouse_turn)

		if allow_mouse:
			want_dir = get_global_mouse_position() - global_position
			var pos_on_canvas = get_global_transform_with_canvas().get_origin()
			Input.warp_mouse(pos_on_canvas + (mouse_position - pos_on_canvas).normalized() * 100)

		if locomotor != null:
			locomotor.locomote_towards(drive_factor, global_position + want_dir, turn_fraction, delta)

		#Input.warp_mouse(pos_on_canvas + Vector2.UP.rotated(global_rotation) * 100)

	elif control_mode == ControlMode.Tank || control_mode == ControlMode.Dynamic:
		var drive_factor = 0.0
		var turn_factor = 0.0

		if Input.is_action_pressed("up_primary") || mouse_pressed:
			drive_factor += 1

		if Input.is_action_pressed("left_primary"):
			turn_factor -= 1

		if Input.is_action_pressed("right_primary"):
			turn_factor += 1

		if mouse_moved:
			#var self_right = Vector2.RIGHT.rotated(global_rotation)
			#var mouse_strength = mouse_motion.project(self_right).length()
			#if mouse_motion.dot(self_right) < 0:
			#	mouse_strength *= -1;
			#turn_factor = clamp(mouse_strength / view_speed, -1, 1)
			turn_factor = clamp(mouse_motion.x / view_speed, -1, 1)

		if locomotor != null:
			locomotor.locomote(drive_factor, turn_factor, delta)

	if Input.is_action_pressed("shoot"):
		shot_fired.emit()



	var mouse_reduction = mouse_motion.normalized() * mouse_gravity * view_speed * delta
	if mouse_reduction.length_squared() > mouse_motion.length_squared():
		mouse_reduction = mouse_motion
	mouse_motion -= mouse_reduction



	#turn_damp_factor *= fire_turn_factor;
	#max_speed_factor *= fire_max_speed_factor;
	#acceleration_factor *= fire_acceleration_factor;

#		if Input.is_action_just_pressed("up_primary"):
#			if time_now - drive_tap_time <= double_tap_msec && acceleration.dot(body.linear_velocity) < 0:
#				acceleration *= turn_around_acceleration_factor;
#				thrust_tap_time = 0
#			thrust_tap_time = time_now
#	if turning_left && !turning_right:
#		if Input.is_action_just_pressed("left_primary"):
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
#		if Input.is_action_just_pressed("right_primary"):
#			if time_now - right_tap_time <= double_tap_msec:
#				#body.rotation += quick_turn_degrees * PI / 180
#				body.linear_velocity += Vector2.RIGHT.rotated(body.rotation) * side_boost
#				right_tap_time = 0
#			right_tap_time = time_now
#		else:
#			body.angular_velocity += delta * turn_speed
#		if !driving:
#			linear_damp_factor *= turn_linear_damp_factor
