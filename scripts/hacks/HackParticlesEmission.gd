extends GPUParticles2D

class_name HackParticlesEmission

# Why is this needed? Maybe because our particle system has a weird lifetime.

func _ready():
	emitting = true
