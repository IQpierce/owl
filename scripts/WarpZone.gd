extends Area2D

class_name WarpZone

@export var secs_duration_til_warp:float = 1
@export var things_to_ignore:Array[Thing]
@export var warp_target_definition_container:Node	# Must implement "get_warp_target_definition() -> Dictionary"

signal on_warped_thing(warped_thing:Thing)
signal on_warped_body(warped_body:RigidBody2D)
signal on_warped_into_microcosm(warped_body:RigidBody2D, microcosm:Microcosm)
signal on_warp_microcosm_dispelled(escaped_body:RigidBody2D, microcosm:Microcosm)

var things_to_warp:Dictionary # [Thing, float] ... keys are the # of secs left before warping

var things_warped:Array[Thing]

var waiting_for_dispel:bool

func _ready():
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_entered)

func _process(delta:float):
	# If we've been rigged up with no warp target, or if it's been destroyed,
	# disable our functionality entirely!
	if !is_instance_valid(warp_target_definition_container):
		process_mode = Node.PROCESS_MODE_DISABLED
		
	var warp_amount:float = delta * secs_duration_til_warp
	
	# Make sure we never re-warp something already warped.
	for thing_warped:Thing in things_warped:
		things_to_warp.erase(thing_warped)
	
	for thing_to_warp:Thing in things_to_warp:
		if thing_to_warp == null:
			continue
		
		things_to_warp[thing_to_warp] -= warp_amount
		
		if things_to_warp[thing_to_warp] <= 0:
			# warp it!
			var warp_target_definition:Dictionary = warp_target_definition_container.get_warp_target_definition()
			assert(warp_target_definition != null)
			warp(thing_to_warp, warp_target_definition)
			things_warped.append(thing_to_warp)
	

func warp(thing:Thing, warp_target_definition:Dictionary):
	var target_packed_scene:PackedScene = warp_target_definition["target_packed_scene"]
	var on_warped_microcosm_dispel_callback:Callable = warp_target_definition["on_warped_microcosm_dispel_callback"]
	
	assert(target_packed_scene != null)
	
	var main_world:Node2D = get_tree().root.get_node("BigWrappingArea/PhosphorEmulation/VpC_PostProcessing/Vp_PostProcessing/VpC_NeverClear/Vp_NeverClear/WorldContainer")
	assert(main_world != null)
	
	# Remove the thing from the main world.
	thing.get_parent().remove_child(thing)
	
	var player_thing:Player = thing as Player
	if player_thing:
		var world_parent:Node = main_world.get_parent()
		world_parent.remove_child(main_world)
		
		var microcosm_world:Microcosm = target_packed_scene.instantiate() as Microcosm
		assert(microcosm_world != null)
		world_parent.add_child(microcosm_world)
		
		var player_world_position:Vector2 = Vector2(1920/2, 1080/2)
		var player_rotation:float = 0
		
		var player_start_node:Node2D = microcosm_world.get_node("PlayerStart")
		if player_start_node != null:
			player_world_position = player_start_node.global_position
			player_rotation = player_start_node.global_rotation
		
		microcosm_world.add_child(player_thing)
		player_thing.global_position = player_world_position
		player_thing.global_rotation = player_rotation
		
		assert(!waiting_for_dispel)
		waiting_for_dispel = true
		microcosm_world.on_dispelled.connect(on_microcosm_dispelled)
		
		on_warped_into_microcosm.emit(player_thing, microcosm_world)
		
		while waiting_for_dispel:
			await world_parent.get_tree().process_frame
		
		microcosm_world.on_dispelled.disconnect(on_microcosm_dispelled)
		
		assert(!waiting_for_dispel)
		assert(!player_thing.dead)
		microcosm_world.remove_child(player_thing)
		
		world_parent.remove_child(microcosm_world)
		microcosm_world.queue_free()
		
		main_world.add_child(player_thing)
		world_parent.add_child(main_world)
		
		if on_warped_microcosm_dispel_callback != null:
			on_warped_microcosm_dispel_callback.call(player_thing, microcosm_world)
		
		on_warp_microcosm_dispelled.emit(player_thing, microcosm_world)
		
	else:
		assert(false)
		
	on_warped_body.emit(thing)
	on_warped_thing.emit(thing)

func on_microcosm_dispelled():
	assert(waiting_for_dispel)
	waiting_for_dispel = false

func _on_body_entered(body:RigidBody2D):
	var body_thing:Thing = body as Thing
	if is_valid_thing_to_warp(body_thing):
		if !things_to_warp.has(body_thing):
			things_to_warp[body_thing] = secs_duration_til_warp
		else:
			push_error("Thing entered warp zone twice: ", body)

func _on_body_exited(body:RigidBody2D):
	var body_thing:Thing = body as Thing
	if is_valid_thing_to_warp(body_thing):
		things_to_warp.erase(body_thing)

func is_valid_thing_to_warp(thing:Thing):
	return is_instance_valid(thing) && !things_to_ignore.has(thing)
