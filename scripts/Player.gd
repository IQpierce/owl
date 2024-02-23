extends Creature
class_name Player

enum ControlMode { Dynamic, Roam, Tank }

@export var camera_cartridge:CameraCartridge
@export var hard_focus:HardFocusCameraCartridge = null
@export var locomotor:Locomotor
@export var hopdart:Hopdart
@export var warp_beam:WarpBeam
@export var control_mode:ControlMode = ControlMode.Dynamic
@export var allow_mouse:bool = false
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

#TODO (sam) where should these actually live? On Thing?
var charge:float = 100
var max_charge:float = 100
var recharge_rate:float = 10
var recharge_delay:float = 1
var charge_use_time:int = 0
var score:int = 0

signal shot_fired()
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

	if hopdart != null:
		hopdart.body = self

func _input(event:InputEvent):
	if event is InputEventMouseMotion:
		mouse_position = event.position
		mouse_motion = event.relative

func _physics_process(delta:float):
	if charge < max_charge:
		if Time.get_ticks_msec() - charge_use_time >= recharge_delay * 1000:
			charge = min(charge + recharge_rate * delta, max_charge)

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

	if hopdart != null:
		var hopdart_dir = Vector2.ZERO
		hopdart_dir.x = Input.get_axis("left_gamepad_secondary", "right_gamepad_secondary")
		hopdart_dir.y = Input.get_axis("up_gamepad_secondary", "down_gamepad_secondary")

		if hopdart_dir.length_squared() > 0:
			gamepad_acting = true
			hopdart.engage(hopdart_dir)

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
			var fastest_view = slowest_view / 1024;
			view_speed = (mouse_sensitivity * slowest_view) + ((1 - mouse_sensitivity) * fastest_view)

	var preping_warp = false
	if warp_beam != null:
		var zoom_speed = 1.05
		if Input.is_action_pressed("hyperspace") && try_discharge(10 * delta):
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
			Input.warp_mouse(pos_on_canvas + (mouse_position - pos_on_canvas).normalized() * view_speed)

		if locomotor != null:
			locomotor.locomote_towards(drive_factor, global_position + want_dir, turn_fraction, delta)

		#Input.warp_mouse(pos_on_canvas + Vector2.UP.rotated(global_rotation) * 100)

	elif (control_mode == ControlMode.Tank || control_mode == ControlMode.Dynamic) && !preping_warp:
		var drive_factor = 0.0
		var turn_factor = 0.0

		if Input.is_action_pressed("up_primary") || mouse_pressed:
			drive_factor += 1

		if Input.is_action_pressed("left_primary"):
			turn_factor -= 1

		if Input.is_action_pressed("right_primary"):
			turn_factor += 1

		if allow_mouse:
			#var self_right = Vector2.RIGHT.rotated(global_rotation)
			#var mouse_strength = mouse_motion.project(self_right).length()
			#if mouse_motion.dot(self_right) < 0:
			#	mouse_strength *= -1;
			#turn_factor += clamp(mouse_strength / view_speed, -1, 1)
			turn_factor += clamp(mouse_motion.x * TAU, -1, 1)

		if locomotor != null:
			locomotor.locomote(drive_factor, turn_factor, delta)

	if Input.is_action_pressed("shoot"):
		shot_fired.emit()
	
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
			hopdart.engage(hopdart_dir)

	var mouse_reduction = mouse_motion.normalized() * mouse_gravity * view_speed * delta
	if mouse_reduction.length_squared() > mouse_motion.length_squared():
		mouse_reduction = mouse_motion
	mouse_motion -= mouse_reduction

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
	print("drop hard _focus")
	if hard_focus != null:
		hard_focus.prey = null
		if camera_rig != null && camera_rig.cartridge == hard_focus:
			camera_rig.cartridge = camera_cartridge

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
