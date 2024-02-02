extends Node2D
class_name CameraCartridge

enum ProcessTiming { Physics, Idle }

@export var process_timing:ProcessTiming = ProcessTiming.Physics

# TODO(sam) Is there a way to build vars on the stack, or is this the only way to prevent repeated allocation
var plan:CameraRig.ExclusivePlan

func _ready():
	plan = CameraRig.ExclusivePlan.new()

func build_plan(delta:float, base_plan:CameraRig.Plan) -> CameraRig.ExclusivePlan:
	plan.copy(base_plan)
	return plan

func request_debug_message() -> String:
	return ""

func draw_for_camera(camera_position:Vector2, show_debug:bool):
	pass
