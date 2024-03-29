extends RigidBody2D

class_name Thing

@export var scaling_group:ScalingGroup2D
@export var spawned_per_damage:Dictionary	# keys are NodePath's which represent Spawners which will be triggered whenever an amount of damage is dealt. The damage threshold (a float) is the key value.
@export var spawned_on_death:Array[Spawner]

@export var health:float = 1
@export var max_health:float = 1

@export var corpse_children:Array[Node2D]	# Which of our child Node2D's persist beyond our death

@export var damage_sfx_cooldown_secs:float = .5

@onready var damaged_sfx:AudioStreamPlayer2D = get_node_or_null("DamagedSFX")
@onready var died_sfx:AttentiveAudio2D = get_node_or_null("DiedSFX")

const damage_blink_frames:int = 6
const damage_blink_count:int = 1
var frames_since_damage:int = -1

signal damaged(dmg_amt, global_position)
signal died()

var dead:bool:
	get:
		return health <= 0

var accumulated_damage_by_spawner:Dictionary	# whose keys align exactly with those of spawn_per_damage, and whose values represent the accumulated damage taken - reset and modulo'ed by the maximum represented by the float val of the emit_per_damage row
var last_damaged_sfx_playtime:float = NAN


func _ready():
	reset_accumulated_damage()

func reset_health():
	health = max_health
	reset_accumulated_damage()

func _process(delta:float):
	# TODO (sam) Placeholder for responding to damage
	if frames_since_damage >= 0:
		if frames_since_damage >= damage_blink_frames * damage_blink_count * 2:
			visible = true
			frames_since_damage = -1
		else:
			if frames_since_damage % damage_blink_frames == 0:
				visible = !visible
			frames_since_damage += 1

	
func reset_accumulated_damage():
	for spawn_key:NodePath in spawned_per_damage:
		accumulated_damage_by_spawner[spawn_key] = float(0)


func deal_damage(dmg_amt:float, global_position:Vector2):
	health -= dmg_amt
	
	for spawner_key:NodePath in spawned_per_damage:
		var spawner:Spawner = get_node(spawner_key)
		
		if spawner == null:
			push_error("No spawner for dealing damage! ", spawner_key)
			return
		
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

	if damaged_sfx && \
		(damage_sfx_cooldown_secs <= 0 || (is_nan(last_damaged_sfx_playtime) || Time.get_unix_time_from_system() > last_damaged_sfx_playtime + damage_sfx_cooldown_secs)):
		damaged_sfx.play()
		last_damaged_sfx_playtime = Time.get_unix_time_from_system()
	
	damaged.emit(dmg_amt, global_position)
	
	if (health <= 0):
		health = 0
		die(false)
	else:
		if visible && frames_since_damage < 0:
			frames_since_damage = 0

func die(utterly:bool = false):
	if died_sfx != null:
		died_sfx.reparent(get_parent())
		died_sfx.play_then_free()
	
	# pieces of our anatomy stay around
	
	for corpse_child in corpse_children:
		if corpse_child.process_mode == PROCESS_MODE_DISABLED:
			corpse_child.process_mode = Node.PROCESS_MODE_INHERIT
		corpse_child.reparent(get_parent(), true)

	
	if !utterly:
		for spawner:Spawner in spawned_on_death:
			if spawner == null:
				continue
			
			spawner.reparent(get_parent())
			spawner.free_after_spawn = true
			spawner.spawn(get_parent())
	
	died.emit(utterly)
	
	queue_free()
