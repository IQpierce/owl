extends Node2D
class_name CameraCartridge

enum ProcessTiming { Physics, Idle }

@export var process_timing:ProcessTiming = ProcessTiming.Physics

# TODO(sam) Is there a way to build vars on the stack, or is this the only way to prevent repeated allocation
var plan:CameraRig.ExclusivePlan

func _ready():
	plan = CameraRig.ExclusivePlan.new()

func build_plan(delta:float, data_rig:CameraRig) -> CameraRig.ExclusivePlan:
	plan.copy_rig(data_rig)
	return plan

func request_debug(draw_rig:CameraRig) -> String:
	return ""
