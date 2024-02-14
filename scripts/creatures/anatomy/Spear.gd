extends Node2D


@export var hook_connection_point:Node2D

@export var head_y_offset:float = -3

@export_group("Extension", "extension") 
@export var extension_enabled:bool = false

@export_range(0, 1) var extension_percent:float = 0:
	get:
		return extension_percent
	set(v):
		extension_percent = clampf(v, 0, 1)
		# Scale updating will happen in process(), partly because this can get called before onready

@export var extension_retracting_rate_per_sec:float = 2.0
@export var extension_extending_rate_per_sec:float = 0.5
@export var extension_shaft_scale_min:float = 1
@export var extension_shaft_scale_max:float = 5


@export_flags_2d_physics var extension_head_collision_inactive:int
@export_flags_2d_physics var extension_head_collision_active:int

@export_flags_2d_physics var extension_shaft_collision_inactive:int
@export_flags_2d_physics var extension_shaft_collision_active:int

signal on_body_speared(body:RigidBody2D)
signal on_body_escaped_spear(body:RigidBody2D)
signal on_all_bodies_escaped_spear(body:RigidBody2D)

@onready var head:Area2D = $Head
@onready var shaft:Area2D = $Shaft

var desired_extension_percent:float = NAN
var speared_bodies:Dictionary # [RigidBody2D, Vector2] - keys are the offset from origin
var last_frame_head_global_position:Vector2

func _ready():
	assert(head != null)
	assert(shaft != null)
	
	
	head.on_new_thing_stuck.connect(on_body_stuck_to_head)
	head.on_thing_unstuck.connect(on_body_unstuck_from_head)
	head.on_became_empty_of_stuck_things.connect(on_all_bodies_unstuck_from_head)
	
	shaft.on_new_thing_stuck.connect(on_body_stuck_to_shaft)
	shaft.on_thing_unstuck.connect(on_body_unstuck_from_shaft)
	shaft.on_became_empty_of_stuck_things.connect(on_all_bodies_unstuck_from_shaft)
	
	if extension_enabled:
		update_anatomy_collision_by_extension_state()

func _process(delta:float):
	if extension_enabled:
		update_anatomy_collision_by_extension_state()
	
	if !is_nan(desired_extension_percent):
		if desired_extension_percent < extension_percent:
			# Need to retract over time.
			extension_percent = extension_percent - (delta * extension_retracting_rate_per_sec)
		elif desired_extension_percent > extension_percent:
			# Need to extend over time.
			extension_percent = extension_percent + (delta * extension_extending_rate_per_sec)
		
		shaft.scale.y = lerpf(extension_shaft_scale_min, extension_shaft_scale_max, extension_percent)
		
		if is_equal_approx(desired_extension_percent, extension_percent):
			desired_extension_percent = NAN
	
	head.position.y = shaft.position.y + head_y_offset * shaft.scale.y
	

	for speared_body:RigidBody2D in speared_bodies:
		if speared_body == null:
			continue

		speared_body.global_position = head.global_position + speared_bodies[speared_body]
	
	last_frame_head_global_position = head.global_position

func update_anatomy_collision_by_extension_state():
	assert(extension_enabled)
	if is_almost_fully_retracted():
		head.collision_mask = extension_head_collision_inactive
		shaft.collision_mask = extension_shaft_collision_inactive
	else:
		head.collision_mask = extension_head_collision_active
		shaft.collision_mask = extension_shaft_collision_active

func is_almost_fully_retracted() -> bool:
	return !extension_enabled || extension_percent <= 0.05

func start_extension(new_extension_percent:float = 1):
	if !extension_enabled:
		push_error("Cannot extend ", self, ", extension is not enabled")
		return
	
	desired_extension_percent = clampf(new_extension_percent, 0, 1)

func start_retraction(new_extension_percent:float = 0):
	if !extension_enabled:
		push_error("Cannot extend ", self, ", extension is not enabled")
		return
	
	desired_extension_percent = clampf(new_extension_percent, 0, 1)

func on_body_stuck_to_head(body:RigidBody2D):
	if !speared_bodies.has(body):
		add_speared_body(body)


func on_body_unstuck_from_head(body:RigidBody2D):
	if speared_bodies.has(body):
		remove_speared_body(body)

func on_all_bodies_unstuck_from_head():
	if speared_bodies.is_empty():
		on_all_bodies_escaped_spear.emit()

func on_body_stuck_to_shaft(body:RigidBody2D):
	if !speared_bodies.has(body):
		add_speared_body(body)

func on_body_unstuck_from_shaft(body:RigidBody2D):
	if speared_bodies.has(body):
		remove_speared_body(body)

func on_all_bodies_unstuck_from_shaft():
	if speared_bodies.is_empty():
		on_all_bodies_escaped_spear.emit()


func add_speared_body(body:RigidBody2D):
	assert(!speared_bodies.has(body))
	var offset = body.global_position - head.global_position
	speared_bodies[body] = offset
	
	on_body_speared.emit(body)
	
func remove_speared_body(body:RigidBody2D):
	assert(speared_bodies.has(body))
	speared_bodies.erase(body)
	on_body_escaped_spear.emit(body)
	
