#TODO (sam) We may endup needing multiple cameras, so this would manage those NOT be one
extends Camera_Deprecated
class_name CameraRig

#@export_group("Debug")
@export var show_debug = true
@export var state_label:Label
#@export_group("Tracking")
@export var cartridge:CameraCartridge
@export var prey:Player
@export var ready_center:bool = true
#@export_group("Curiosity")
@export var leash_length:float = 400
@export var wonder_speed:float = 250

var velocity:Vector2
var idle_plan:Plan

func _ready():
	if ready_center && cartridge != null:
		global_position = cartridge.global_position

	idle_plan = Plan.new()
	idle_plan.copy_rig(self)

func _draw():
	# Only draw Debug display while in Editor
	show_debug = show_debug && OS.has_feature("editor")

	if cartridge != null:
		cartridge.draw_for_camera(global_position, show_debug)
		if state_label != null:
			if show_debug:
				state_label.visible = true
				state_label.text = cartridge.request_debug_message()
			else:
				state_label.visible = false

func _process(delta:float):
	if cartridge != null && cartridge.process_timing == CameraCartridge.ProcessTiming.Idle:
		apply_plans(delta)

func _physics_process(delta:float):
	if cartridge != null && cartridge.process_timing == CameraCartridge.ProcessTiming.Physics:
		apply_plans(delta)

func apply_plans(delta:float):
	idle_plan.copy_rig(self)

	var cartridge_plan:ExclusivePlan = null
	var hunt_pos = global_position
	var tracking_importance = 0

	if cartridge != null:
		cartridge_plan = cartridge.build_plan(delta, idle_plan)
		hunt_pos = cartridge_plan.position
		tracking_importance = cartridge_plan.exclusivity

	var wonder_pos = hunt_pos
	if center_priority > 0:
		wonder_pos = global_position
		var wonder_destination = attention_center

		var prey_to_destination = wonder_destination - prey.global_position
		if prey_to_destination.length_squared() > leash_length * leash_length:
			prey_to_destination = prey_to_destination.normalized() * leash_length

		wonder_destination = prey.global_position + prey_to_destination
		var to_wonder = wonder_destination - global_position
		if to_wonder.length_squared() > wonder_speed * wonder_speed:
			to_wonder = to_wonder.normalized() * wonder_speed

		wonder_pos += (to_wonder + velocity) * delta

	global_position = ((1 - tracking_importance) * wonder_pos) + (tracking_importance * hunt_pos)
	center_priority = 0

	queue_redraw()


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
	var exclusivity:float = 0
