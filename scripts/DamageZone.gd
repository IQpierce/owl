extends Area2D

class_name DamageZone

@export var damage_per_sec:float = 1
@export var damage_cooldown_secs:float = 2
@export var things_to_ignore:Array[Thing]
@export var exclusive_damagees:Array[Thing]

signal on_damaged_thing(damaged_thing:Thing, damage_amt:float)
signal on_damaged_body(damaged_body:RigidBody2D, damage_amt:float)

var things_to_damage:Array[Thing]

func _ready():
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)

func _process(delta:float):
	var damage_amount:float = delta * damage_per_sec
	
	for thing_to_damage:Thing in things_to_damage:
		if thing_to_damage == null:
			continue
		
		# @TODO: Choose a better position? What if its center-point is not inside of our area...? That could look weird!
		thing_to_damage.deal_damage(damage_amount, thing_to_damage.global_position)

func _on_body_entered(body:RigidBody2D):
	var body_thing:Thing = body as Thing
	if exclusive_damagees.size() < 1 || exclusive_damagees.has(body_thing):
		if body_thing && things_to_ignore.count(body_thing) == 0:
			things_to_damage.append(body_thing)

func _on_body_exited(body:RigidBody2D):
	var body_thing:Thing = body as Thing
	if body_thing && things_to_ignore.count(body_thing) == 0:
		things_to_damage.erase(body_thing)
