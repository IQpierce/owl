#TODO (sam) We may endup needing multiple cameras, so this would manage those NOT be one
extends Camera_Deprecated
class_name CameraRig

@export_group("Debug")
@export var show_debug = true
@export var state_label:Label
@export_group("Tracking")
@export var cartridge:CameraCartridge
@export var ready_center:bool = true
@export_group("Curiosity")
@export var leash_length:float = 400
@export var curious_speed:float = 250

var velocity:Vector2
var viewport:Viewport
var prey:Node2D

func get_prey() -> Node2D:
	return prey

func view_size() -> Vector2:
	if viewport == null:
		viewport = get_viewport()
	var view_size = viewport.size
	view_size = Vector2(view_size.x / zoom.x, view_size.y / zoom.y)
	return view_size

func _ready():
	if cartridge == null:
		cartridge = OwlGame.instance.get_default_camera_cartridge()

	if ready_center && cartridge != null:
		global_position = cartridge.global_position

func _draw():
	# Only draw Debug display while in Editor
	show_debug = show_debug && OS.has_feature("editor")
	if show_debug:
		if cartridge != null:
			var debug_msg = cartridge.request_debug(self)
			if state_label != null:
				state_label.visible = true
				state_label.text = debug_msg
			else:
				state_label.visible = false

func _process(delta:float):
	if cartridge != null && cartridge.process_timing == CameraCartridge.ProcessTiming.Idle:
		apply_plans(delta)

func _physics_process(delta:float):
	if cartridge != null && cartridge.process_timing == CameraCartridge.ProcessTiming.Physics:
		apply_plans(delta)

func apply_plans(delta:float):
	var old_zoom = zoom

	#TODO REMOVE
	#var zoom_speed = 1.05
	#if Input.is_action_pressed("hyperspace") || Input.is_action_pressed("hyperspace_gamepad"):
	#	if Input.is_action_pressed("ignore_input"):
	#		zoom /= Vector2(zoom_speed, zoom_speed)
	#	else:
	#		zoom *= Vector2(zoom_speed, zoom_speed)
	#		var player = OwlGame.instance.scene.player
	#		# TODO EXTRA REMOVE... also turn Player's collision back on and reattach it's camera cartridge
	#		player.global_position = global_position + ((player.global_position - global_position) * 0.95)
	#	zoom.x = clamp(zoom.x, initial_zoom.x, 15)
	#	zoom.y = clamp(zoom.y, initial_zoom.y, 15)
	#	if cartridge != null:
	#		global_position = cartridge.global_position + ((global_position - cartridge.global_position) * (old_zoom / zoom))

	#OwlGame.instance.zooming = old_zoom != zoom
	#if zoom != initial_zoom:
	#	return
	# END REMOVE

	var cartridge_plan:ExclusivePlan = null
	var hunt_pos = global_position
	var tracking_importance = 0

	prey = self
	if cartridge != null:
		cartridge_plan = cartridge.build_plan(delta, self)
		if cartridge_plan != null:
			hunt_pos = cartridge_plan.position
			tracking_importance = cartridge_plan.exclusivity
			prey = cartridge_plan.prey

	#TODO (sam) should this also be handled in cartridge
	var curious_pos = hunt_pos
	if center_priority > 0:
		curious_pos = global_position
		var curious_destination = attention_center

		#TODO(sam) cartridge should return the position of the prey/vip not itself
		var prey_to_destination = curious_destination - prey.global_position
		if prey_to_destination.length_squared() > leash_length * leash_length:
			prey_to_destination = prey_to_destination.normalized() * leash_length

		curious_destination = cartridge.global_position + prey_to_destination
		var to_curious = curious_destination - global_position
		if to_curious.length_squared() > curious_speed * curious_speed:
			to_curious = to_curious.normalized() * curious_speed

		# TODO shouldn't wander velocity care about the plan's weight
		curious_pos += (to_curious + velocity) * delta

	global_position = ((1 - tracking_importance) * curious_pos) + (tracking_importance * hunt_pos)
	center_priority = 0

	#TODO (sam) how should I be combining velocities?
	velocity = cartridge_plan.velocity

	OwlGame.instance.zooming = old_zoom != zoom

	queue_redraw()


# Maybe just remove these and pass down the rig
class Plan:
	var position:Vector2 = Vector2.ZERO
	var velocity:Vector2 = Vector2.ZERO
	var zoom:Vector2 = Vector2.ONE

	func copy(other:Plan):
		position        = other.position
		velocity        = other.velocity
		zoom            = other.zoom

	func copy_rig(rig:CameraRig):
		position = rig.global_position
		velocity = rig.velocity
		zoom = rig.zoom

class CommonPlan extends Plan:
	var position_weight:float = 0
	var velocity_weight:float = 0
	var zoom_weight:float = 0

class ExclusivePlan extends Plan:
	var prey:Node2D
	var exclusivity:float = 0
