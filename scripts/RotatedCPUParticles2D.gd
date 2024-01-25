extends CPUParticles2D

class_name RotatedCPUParticles2D

@export var emit_degrees:float

func _process(delta):
	if visible:
		# Unfortunately this also rotates already generated particles
		# Double unfortunately, altering CUSTOM.x (angle) in shader of GPU particles has the same effect
		angle_min = emit_degrees - (get_parent().rotation / PI * 180)
		angle_max = angle_min
