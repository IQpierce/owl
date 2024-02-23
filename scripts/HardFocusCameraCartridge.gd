extends CameraCartridge
class_name HardFocusCameraCartridge

@export var prey:Node2D = null
@export var exclusivity:float = 1
@export var lock_speed:float = -1

var locked:bool = false
var zoom:float = 1

func build_plan(delta:float, data_rig:CameraRig) -> CameraRig.ExclusivePlan:
	plan.copy_rig(data_rig)
	plan.velocity = Vector2.ZERO

	if !locked:
		if lock_speed <= 0:
			locked = true
		else:
			var to_prey = prey.global_position - plan.position
			var speed_delta = lock_speed * delta
			if to_prey.length_squared() > speed_delta * speed_delta:
				to_prey = to_prey.normalized() * speed_delta
			else:
				locked = true
			plan.position += to_prey

	if locked:
		plan.position = prey.position
		plan.zoom = zoom

	return plan

