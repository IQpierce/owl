extends Area2D

class_name StickyZone

@export var ignore_things:Array[RigidBody2D]

signal on_new_thing_stuck(stuck_thing:RigidBody2D)
signal on_thing_unstuck(unstuck_thing:RigidBody2D)
signal on_became_empty_of_stuck_things()

var stuck_things:Dictionary	# keys are RigidBody2D's, values are Vector2 offsets of where they stuck to us.

func _ready():
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)

func _on_body_entered(body:PhysicsBody2D):
	var rigid_body:RigidBody2D = body as RigidBody2D
	if rigid_body:
		if !stuck_things.has(rigid_body) && \
			is_valid_body_for_sticking(rigid_body):
			
			var offset:Vector2 = body.global_position - global_position
			stuck_things[rigid_body] = offset
			
			on_new_thing_stuck.emit(rigid_body)
	
func _on_body_exited(body:PhysicsBody2D):
	var rigid_body:RigidBody2D = body as RigidBody2D
	if rigid_body:
		if stuck_things.has(rigid_body):
			assert(is_valid_body_for_sticking(rigid_body))
			
			stuck_things.erase(rigid_body)
			
			on_thing_unstuck.emit(rigid_body)
			
			if stuck_things.is_empty():
				on_became_empty_of_stuck_things.emit()
	
func is_valid_body_for_sticking(body:RigidBody2D):
	return !ignore_things.has(body)

