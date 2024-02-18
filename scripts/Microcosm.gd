extends Node2D

class_name Microcosm

# @TODO: Support other objectives/criteria/goals for resolving an encounter?
@export var bodies_to_eliminate:Array[RigidBody2D]
@export var autopopulate_elimination_targets_from_group:bool = true

signal on_dispelled(bodies_still_inside:Array[RigidBody2D])

var dispelled:bool = false

func _ready():
	if autopopulate_elimination_targets_from_group:
		var eliminate_targets:Array[Node] = get_tree().get_nodes_in_group("EliminateTarget")
		for eliminate_target:Node in eliminate_targets:
			var eliminate_body:RigidBody2D = eliminate_target as RigidBody2D
			if eliminate_body != null:
				bodies_to_eliminate.append(eliminate_body)
				
				var eliminate_thing:Thing = eliminate_body as Thing
				if eliminate_thing:
					var eliminate_pickup:Pickup = eliminate_body as Pickup
					if eliminate_pickup != null:
						eliminate_pickup.die.connect(func ():on_thing_eliminated(eliminate_thing))
				else:
					var eliminate_pickup:Pickup = eliminate_body as Pickup
					if eliminate_pickup != null:
						eliminate_pickup.on_pickup.connect(func (picker_upper:Creature):on_pickup_eliminated(eliminate_pickup, picker_upper))
				
			else:
				push_error("Non-rigidbody tagged with EliminateTarget: ", eliminate_target)

func _process(delta:float):
	if !dispelled:
		check_resolution_state()

func on_pickup_eliminated(pickup:Pickup, picker_upper:Creature):
	bodies_to_eliminate.erase(pickup)

func on_thing_eliminated(thing:Thing):
	bodies_to_eliminate.erase(thing)

func check_resolution_state():
	var filtered_bodies:Array = bodies_to_eliminate.filter(is_body_still_valid)
	bodies_to_eliminate.assign(filtered_bodies)
	
	if bodies_to_eliminate.is_empty():
		dispel()

func is_body_still_valid(body:RigidBody2D) -> bool:
	if !is_instance_valid(body):
		return false
	
	var body_thing:Thing = body as Thing
	if body_thing != null:
		return !body_thing.dead
	else:
		var body_pickup:Pickup = body as Pickup
		if body_pickup != null:
			return !body_pickup.is_queued_for_deletion()
	
	assert(false)
	return false

func dispel():
	assert(!dispelled)
	dispelled = true
	
	on_dispelled.emit()
	
