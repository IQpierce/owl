extends Node2D

class_name VisionConeValidator

signal on_any_valid_body_seen(body:PhysicsBody2D)
signal on_valid_bodies_no_longer_seen()

var current_valid_bodies:Array[PhysicsBody2D]

func _ready():
	self.body_entered.connect(on_body_entered_vision_cone)
	self.body_exited.connect(on_body_exited_vision_cone)

func on_body_entered_vision_cone(body:PhysicsBody2D):
	if is_body_valid(body):
		current_valid_bodies.append(body)
		on_any_valid_body_seen.emit()

func on_body_exited_vision_cone(body:PhysicsBody2D):
	if is_body_valid(body):
		current_valid_bodies.erase(body)
		if current_valid_bodies.is_empty():
			on_valid_bodies_no_longer_seen.emit()

func is_body_valid(body:PhysicsBody2D) -> bool:
	# @TODO: Actual logic/filtering to be sure we want to stab this thing?
	return true
