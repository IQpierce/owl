extends Node2D
class_name CameraCartridge

enum ProcessTiming { Physics, Idle }

@export var process_timing:ProcessTiming = ProcessTiming.Physics

# TODO(sam) Is there a way to build vars on the stack, or is this the only way to prevent repeated allocation
var plan:CameraRig.ExclusivePlan

func _ready():
	plan = CameraRig.ExclusivePlan.new()

func build_plan(delta:float, idle_plan:CameraRig.Plan) -> CameraRig.ExclusivePlan:
	plan.copy(idle_plan)
	plan.prey = self
	return plan

func request_debug(camera_position:Vector2) -> String:
	global_position = camera_position
	global_rotation = 0
	queue_redraw()
	return ""
