extends RigidBody2D

class_name Thing

@export var spawned_per_damage:Dictionary	# keys are NodePath's which represent Spawners which will be triggered whenever an amount of damage is dealt. The damage threshold (a float) is the key value.
@export var spawned_on_death:Array[Spawner]

@export var health:float = 1
@export var max_health:float = 1

@export var corpse_children:Array[Node2D]	# Which of our child Node2D's persist beyond our death

@onready var damaged_sfx:AudioStreamPlayer2D = $DamagedSFX
@onready var died_sfx:AudioStreamPlayer2D = $DiedSFX

signal damaged(dmg_amt, global_position)
signal died()

var accumulated_damage_by_spawner:Dictionary	# whose keys align exactly with those of spawn_per_damage, and whose values represent the accumulated damage taken - reset and modulo'ed by the maximum represented by the float val of the emit_per_damage row


func _ready():
	reset_accumulated_damage()

func reset_health():
	health = max_health
	reset_accumulated_damage()

	
func reset_accumulated_damage():
	for spawn_key:NodePath in spawned_per_damage:
		accumulated_damage_by_spawner[spawn_key] = float(0)


func deal_damage(dmg_amt:float, global_position:Vector2):
	health -= dmg_amt
	
	for spawner_key:NodePath in spawned_per_damage:
		var spawner:Spawner = get_node(spawner_key)
		
		assert(spawner != null)
		
		var dmg_max:float = spawned_per_damage[spawner_key]	# This is the threshhold for how much damage we take before we perform the spawn(s)
		var accumulated_dmg:float = accumulated_damage_by_spawner[spawner_key] + dmg_amt
		
		# Emit when the accumulated + current damage crosses the threshhold.
		while accumulated_dmg > dmg_max:
			spawner.global_position = global_position
			spawner.rotation = (get_global_transform().origin - global_position).angle()
			spawner.spawn(get_parent())
			accumulated_dmg -= dmg_max
		
		# Save the remaining "leftover" accumulated damage
		accumulated_damage_by_spawner[spawner_key] = accumulated_dmg
	
	if damaged_sfx:
		damaged_sfx.play()
	
	damaged.emit(dmg_amt, global_position)
	
	if (health <= 0):
		health = 0
		die(false)

func die(utterly:bool = false):
	if died_sfx != null:
		died_sfx.reparent(get_parent())
		died_sfx.play()
	
	# pieces of our anatomy stay around
	
	for corpse_child in corpse_children:
		if corpse_child.process_mode == PROCESS_MODE_DISABLED:
			corpse_child.process_mode = Node.PROCESS_MODE_INHERIT
		corpse_child.reparent(get_parent(), true)

	
	if !utterly:
		for spawner:Spawner in spawned_on_death:
			spawner.spawn(get_parent())
	
	died.emit(utterly)
	
	# Give signals and such a frame to process. Some of them, like spawning, need to await until we are not in "collision" codepath
	# TODO (sam) does this cause any weirdness from things sticking around an extra frame
	await get_tree().process_frame

	queue_free()
