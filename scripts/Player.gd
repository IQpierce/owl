extends Creature
class_name Player

enum ControlMode { Dynamic, Roam, Tank }

@export var camera_leader:CameraCartridge
@export var camera_adjust_speed:float = 300
@export var hard_focus:HardFocusCameraCartridge = null
@export var locomotor:Locomotor
@export var gun:Gun
@export var hopdart:Hopdart
@export var warp_beam:WarpBeam
@export var control_mode:ControlMode = ControlMode.Dynamic
@export var idle_delay_secs:float = 2
@export var heartbeat_by_health_curve:Curve

@export_group("TankControls")
@export_range(0.0, 1.0) var down_turn_fraction:float = 1 #TODO (sam) currently this only affects keyboard
@export_range(0.0, 1.0) var initial_turn_fraction:float = 1
@export var precise_turn_degrees:float = 5
@export var precise_turn_damping:float = 0.5
@export_range(0, 90) var turn_band_degrees:float = 45

@export_group("RoamControls")
@export_range(-1, 1) var thrust_heading_alignment:float = 0
@export_range(0, 1) var thrust_deadzone:float = 0.75
@export_range(0, 1) var thrust_smash_threshold:float = 0.25

@export_group("Mouse")
@export var allow_mouse:bool = false
@export_range(0, 1) var mouse_sensitivity:float = 0
@export_range(0, 60) var mouse_gravity: float = 30

@export_group("Test Cartridges")
@export var drive_test:DriveCartridge
@export var turn_test:TurnCartridge
@export var roam_test:RoamCartridge
@export var gun_test:GunCartridge
@export var strafe_test:StrafeCartridge

@export_group("")

@onready var heartbeat = $Heartbeat
@onready var heartbeat_timer = $HeartbeatTimer


## Window to input double tap of a key
#@export var double_tap_msec:float = 1;
#var thrust_tap_time:int = 0;
#var left_tap_time:int = 0;
#var right_tap_time:int = 0;

var camera_rig:CameraRig
var time_since_input:float = 0
var idling:bool = false
var mouse_position:Vector2 = Vector2.ZERO
var mouse_motion:Vector2 = Vector2.ZERO
var known_turn:float = 0
var known_turn_gamepad:float = 0
var prev_frame_left_stick:float = 0
var rotating_towards:Vector2 = Vector2.ZERO

#TODO (sam) where should these actually live? On Thing?
var charge:float = 100
var max_charge:float = 100
var recharge_rate:float = 10
var recharge_delay:float = 1
var charge_use_time:int = 0
var score:int = 0

signal shot_fired(moving:bool, turning:bool)
signal warped_in()

func health_portion() -> float:
	return health / max_health

func charge_portion() -> float:
	return charge / max_charge

func score_total() -> int:
	return score

func _ready():
	var scene = OwlGame.instance.scene
	if scene != null:
		camera_rig = scene.world_camera as CameraRig
	
	if locomotor != null:
		locomotor.body = self
	if gun != null:
		gun.body = self
	if hopdart != null:
		hopdart.body = self

func _input(event:InputEvent):
	if event is InputEventMouseMotion:
		mouse_position = event.position
		mouse_motion = event.relative

func _process(delta:float):
	if heartbeat_timer:
		heartbeat_timer.wait_time = get_current_heartbeat_delta_time()
		
	# debug input
	# @TODO Compile this out for shipping builds!
	if Input.is_action_just_pressed("debug_self_harm"):
		deal_damage(1.0, global_position)

func get_current_heartbeat_delta_time() -> float:
	if heartbeat_by_health_curve == null:
		push_error("No heartbeat rate data available")
		return 2.5
	
	return heartbeat_by_health_curve.sample_baked(health / max_health)

func _physics_process(delta:float):
	apply_test_cartridges()

	if charge < max_charge:
		if Time.get_ticks_msec() - charge_use_time >= recharge_delay * 1000:
			charge = min(charge + recharge_rate * delta, max_charge)

	var gamepad_acting = process_gamepad(delta)
	var keyboard_acting = false
	if !gamepad_acting:
		keyboard_acting = process_keyboard_mouse(delta)
	
	if gamepad_acting || keyboard_acting:
		time_since_input = 0
		idling = false
		if camera_leader != null:
			camera_leader.recenter = false
	else:
		time_since_input += delta
	
	if time_since_input > idle_delay_secs && !idling:
		if camera_leader != null:
			idling = true
			camera_leader.recenter = true

	
func process_gamepad(delta:float) -> bool:
	var gamepad_acting = false
	var drive_factor = 0.0
	var any_turn = false
	if control_mode == ControlMode.Roam || control_mode == ControlMode.Dynamic:
		var want_dir = Vector2.ZERO
		var turn_fraction = 1.0

		if Input.is_action_pressed("drive_gamepad"):
			drive_factor += 1
		#else:
		#	drive_factor += Input.get_action_strength("roam_gamepad_thrust_axis")

		want_dir.x = Input.get_axis("left_gamepad_primary", "right_gamepad_primary")
		want_dir.y = Input.get_axis("up_gamepad_primary", "down_gamepad_primary")

		if want_dir.length_squared() == 0 && rotating_towards.length_squared() > 0:
			want_dir = rotating_towards
			rotating_towards -= rotating_towards.project(Vector2.UP.rotated(global_rotation))
			rotating_towards *= 1 - (angular_damp * delta)
			if rotating_towards.length_squared() < 0.01:
				rotating_towards = Vector2.ZERO
		else:
			rotating_towards = want_dir

		# TODO (sam) Testing if we can do turn-only and thrust-turn without an extra button (also might feel more intuitive)
		var want_length = clamp(want_dir.length(), 0, 1)
		var quick_change = want_length - prev_frame_left_stick > thrust_smash_threshold
		var far_push = want_length > thrust_deadzone
		var thrust_aligned = want_dir.normalized().dot(Vector2.UP.rotated(global_rotation)) >= thrust_heading_alignment
		if quick_change || far_push:
			if thrust_aligned:
				prev_frame_left_stick = 0
				drive_factor += 1
		else:
			prev_frame_left_stick = want_length
			if thrust_deadzone > 0:
				want_dir.x /= clamp(thrust_deadzone, 0, 1)
				want_dir.y /= clamp(thrust_deadzone, 0, 1)

		turn_fraction *= clamp(want_dir.length(), 0, 1)

		any_turn = want_dir.length_squared() > 0 && want_dir.normalized().dot(Vector2.UP.rotated(global_rotation))
		gamepad_acting = gamepad_acting || drive_factor > 0 || any_turn

		if gamepad_acting && locomotor != null:
			locomotor.locomote_towards(drive_factor, global_position + want_dir, turn_fraction, delta)

	elif control_mode == ControlMode.Tank:
		var precise_turn_radians = precise_turn_degrees * PI / 180

		# TODO (sam) drive_gamepad is hooked to bottom-face-button which is incorrect on switch... we need differentiate or calibrate
		if Input.is_action_pressed("drive_gamepad"):
			drive_factor += 1

		#var turn_factor = Input.get_axis("left_gamepad_primary", "right_gamepad_primary")
		var stick_pos = Vector2(Input.get_axis("left_gamepad_primary", "right_gamepad_primary"), Input.get_axis("up_gamepad_primary", "down_gamepad_primary"))
		var vert_turn_adjustment = 1
		var hori_turn_portion = clamp(Vector2(abs(stick_pos.x), stick_pos.y).normalized().dot(Vector2.RIGHT), 0, 1)
		var full_turn_threshold = cos(turn_band_degrees / 180.0 * PI)
		if hori_turn_portion < full_turn_threshold:
			vert_turn_adjustment = hori_turn_portion / full_turn_threshold
		if stick_pos.x < 0:
			vert_turn_adjustment *= -1
		var turn_factor = clamp(stick_pos.x + abs(stick_pos.y) * vert_turn_adjustment, -1, 1)

		#if any_turn:
		#	var about_face_portion = abs(known_turn_gamepad) / precise_turn_radians
		#	turn_factor *= ((1 - about_face_portion) * initial_turn_fraction) + (about_face_portion)

		any_turn = turn_factor != 0
		if any_turn:
			var about_face_portion = abs(known_turn_gamepad) / precise_turn_radians
			turn_factor *= ((1 - about_face_portion) * initial_turn_fraction) + (about_face_portion)

		gamepad_acting = gamepad_acting || drive_factor > 0 || any_turn

		if gamepad_acting && locomotor != null:
			locomotor.locomote(drive_factor, turn_factor, delta)

		if abs(angular_velocity) < precise_turn_radians && !any_turn:
			angular_velocity *= precise_turn_damping

		if !any_turn:
			known_turn_gamepad = 0
		else:
			known_turn_gamepad = clamp(known_turn_gamepad + angular_velocity * delta, -precise_turn_radians, precise_turn_radians)

	if Input.is_action_pressed("shoot_gamepad") || Input.get_action_strength("shoot_gamepad") > 0:
		gamepad_acting = true
		shot_fired.emit(drive_factor > 0, any_turn)

	if hopdart != null:
		var hopdart_dir = Vector2.ZERO
		hopdart_dir.x = Input.get_axis("left_gamepad_secondary", "right_gamepad_secondary")
		hopdart_dir.y = Input.get_axis("up_gamepad_secondary", "down_gamepad_secondary")

		if Input.is_action_pressed("shoulder_left_gamepad"):
			hopdart_dir = Vector2(-1, 0)
			if hopdart.alignment == Hopdart.Alignment.Screen:
				hopdart_dir = hopdart_dir.rotated(global_rotation)
		if Input.is_action_pressed("shoulder_right_gamepad"):
			hopdart_dir = Vector2(1, 0)
			if hopdart.alignment == Hopdart.Alignment.Screen:
				hopdart_dir = hopdart_dir.rotated(global_rotation)

		if hopdart_dir.length_squared() > 0:
			gamepad_acting = true
			hopdart.engage(hopdart_dir)

	if Input.is_action_pressed("dpad_left_gamepad"):
		camera_leader.prey_offset += Vector2(-1, 0) * camera_adjust_speed * delta
	if Input.is_action_pressed("dpad_right_gamepad"):
		camera_leader.prey_offset += Vector2(1, 0) * camera_adjust_speed * delta
	if Input.is_action_pressed("dpad_up_gamepad"):
		camera_leader.prey_offset += Vector2(0, -1) * camera_adjust_speed * delta
	if Input.is_action_pressed("dpad_down_gamepad"):
		camera_leader.prey_offset += Vector2(0, 1) * camera_adjust_speed * delta
	if Input.is_action_pressed("camera_reset_gamepad"):
		camera_leader.prey_offset = Vector2(0, 0)
	
	return gamepad_acting

func process_keyboard_mouse(delta:float) -> bool:
	# OS-level commands and such should override player controls (eg. CMD-SHIFT-5 for screen record on macOS)
	if Input.is_action_pressed("ignore_input"):
		return false

	var keyboard_acting = false
	var mouse_pressed = allow_mouse && Input.is_action_pressed("mouse_left_click")
	var mouse_moved = false
	var view_speed = 1
	var drive_factor = 0.0
	var any_turn = false

	if mouse_motion.length_squared() > 0:
		mouse_moved = true
		if camera_rig != null:
			var view_size = camera_rig.view_size()
			var slowest_view = min(view_size.x, view_size.y)
			var fastest_view = slowest_view / 1024;
			view_speed = (mouse_sensitivity * slowest_view) + ((1 - mouse_sensitivity) * fastest_view)

	var preping_warp = false
	if warp_beam != null:
		var zoom_speed = 1.05
		if Input.is_action_pressed("hyperspace") && try_discharge(10 * delta):
			keyboard_acting = true
			warp_beam.visible = true
			preping_warp = true
			angular_velocity = 0

			if warp_beam != null && warp_beam.target != null:
				if camera_rig != null && hard_focus != null && camera_rig.cartridge != hard_focus:
					hard_focus.prey = warp_beam.target
					hard_focus.zoom = camera_rig.relative_zoom()
					camera_rig.cartridge = hard_focus
				linear_velocity *= 0.95
		else:
			if warp_beam.target != null && warp_beam.visible && warp_beam.warp_ready:
				warp_in()
			warp_beam.visible = false

	if control_mode == ControlMode.Roam && !preping_warp:
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

		if want_dir.length_squared() > 0:
			any_turn = true

		if mouse_moved:
			Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED_HIDDEN)
		#	var mouse_turn = clamp(mouse_motion.x * PI / view_speed, -1, 1)
		#	want_dir = Vector2.UP.rotated(global_rotation).rotated(mouse_turn)

		if allow_mouse:
			want_dir = get_global_mouse_position() - global_position
			var pos_on_canvas = get_global_transform_with_canvas().get_origin()
			Input.warp_mouse(pos_on_canvas + (mouse_position - pos_on_canvas).normalized() * view_speed)

		keyboard_acting = keyboard_acting || drive_factor > 0 || any_turn

		if locomotor != null:
			locomotor.locomote_towards(drive_factor, global_position + want_dir, turn_fraction, delta)

		#Input.warp_mouse(pos_on_canvas + Vector2.UP.rotated(global_rotation) * 100)

	elif (control_mode == ControlMode.Tank || control_mode == ControlMode.Dynamic) && !preping_warp:
		var turn_factor = 0.0
		var turn_damp = 1.0
		var precise_turn_radians = precise_turn_degrees * PI / 180

		if Input.is_action_pressed("left_primary"):
			turn_factor -= 1
			any_turn = true

		if Input.is_action_pressed("right_primary"):
			turn_factor += 1
			any_turn = true

		if any_turn:
			var about_face_portion = abs(known_turn) / precise_turn_radians
			turn_factor *= ((1 - about_face_portion) * initial_turn_fraction) + (about_face_portion)

		if Input.is_action_pressed("up_primary") || mouse_pressed:
			drive_factor += 1

		# Allow player to hold DOWN to aim more precisely
		if Input.is_action_pressed("down_primary"):
			turn_factor *= down_turn_fraction

		if allow_mouse:
			#var self_right = Vector2.RIGHT.rotated(global_rotation)
			#var mouse_strength = mouse_motion.project(self_right).length()
			#if mouse_motion.dot(self_right) < 0:
			#	mouse_strength *= -1;
			#turn_factor += clamp(mouse_strength / view_speed, -1, 1)
			turn_factor += clamp(mouse_motion.x * TAU, -1, 1)
			if turn_factor != 0:
				any_turn = true

		keyboard_acting = keyboard_acting || drive_factor > 0 || any_turn

		if locomotor != null:
			locomotor.locomote(drive_factor, turn_factor, delta)

		if abs(angular_velocity) < precise_turn_radians && !any_turn:
			angular_velocity *= precise_turn_damping

		if !any_turn:
			known_turn = 0
		else:
			known_turn = clamp(known_turn + angular_velocity * delta, -precise_turn_radians, precise_turn_radians)

	if Input.is_action_pressed("shoot"):
		keyboard_acting = true
		shot_fired.emit(drive_factor > 0, any_turn)
	
	if hopdart != null:
		var hopdart_dir = Vector2.ZERO

		if Input.is_action_pressed("up_secondary"):
			hopdart_dir += Vector2.UP
		if Input.is_action_pressed("down_secondary"):
			hopdart_dir += Vector2.DOWN
		if Input.is_action_pressed("left_secondary"):
			hopdart_dir += Vector2.LEFT
		if Input.is_action_pressed("right_secondary"):
			hopdart_dir += Vector2.RIGHT

		if hopdart_dir.length_squared() > 0:
			keyboard_acting = true
			hopdart.engage(hopdart_dir)

	var mouse_reduction = mouse_motion.normalized() * mouse_gravity * view_speed * delta
	if mouse_reduction.length_squared() > mouse_motion.length_squared():
		mouse_reduction = mouse_motion
	mouse_motion -= mouse_reduction

	return keyboard_acting

func try_discharge(amount:float) -> bool:
	# TODO (sam) Is this a game that allows you to use charge you don't have?
	if charge > 0:
		charge -= amount
		charge_use_time = Time.get_ticks_msec()
		return true
	return false

func _apply_pickup(pickup:Pickup):
	score += 1

func drop_hard_focus():
	if hard_focus != null:
		hard_focus.prey = null
		if camera_rig != null && hard_focus != null && camera_rig.cartridge == hard_focus:
			camera_rig.cartridge = camera_leader

# TODO This probably wants to live elsewhere ... also very hardcoded at the moment
func warp_in():
	if hard_focus == null:
		return

	var layer = collision_layer
	var mask = collision_mask
	collision_layer = 0
	collision_mask = 0
	var end_zoom = 15.0
	var zoom_speed = 1.07
	var zoom_done = false
	warp_beam.get_geometry(warp_beam.target).undraw()
	warped_in.emit()

	while !zoom_done:
		hard_focus.zoom *= zoom_speed
		global_position = camera_rig.global_position + ((global_position - camera_rig.global_position) * 0.9)
		if camera_rig.relative_zoom() >= end_zoom:
			#camera_rig.zoom = Vector2(end_zoom, end_zoom)
			zoom_done = true
		await get_tree().physics_frame
	await get_tree().create_timer(0.25).timeout
	get_tree().change_scene_to_file("res://scenes/inner_warp_test.tscn")
	collision_layer = layer
	collision_mask = mask
	#if cartridge != null:
	#	global_position = cartridge.global_position + ((global_position - cartridge.global_position) * (old_zoom / zoom))

func apply_test_cartridges():
	if drive_test != null:
		drive_test.apply(self, locomotor)
	if turn_test != null:
		turn_test.apply(self, locomotor)
		turn_test.apply_player(self)
	if roam_test != null:
		roam_test.apply(self)
	if gun_test != null:
		gun_test.apply(gun)
	if strafe_test != null:
		strafe_test.apply(hopdart)
	
# Heartbeat stuff



func _on_heartbeat_timer_timeout():
	heartbeat.play()
