extends Node2D
class_name Hopdart

enum Alignment { Screen, Body }
enum State { Ready, Active, Cooldown }

@export var alignment:Alignment = Alignment.Screen
@export var initial_distance:float = 50
@export var finesse_distance:float = 100
@export_range(16, 1000) var initial_msec:int = 100
@export_range(16, 1000) var finesse_msec:int = 200
@export var cooldown_msec:int = 0

var body:Thing = null
var state:State = State.Ready
var engaged:bool = false
var sum_distance:float = 0
var usage_timestamp:int = 0
var direction = Vector2.ZERO
var initial_position:Vector2 = Vector2.ZERO

#TODO (sam) There might wanna be two stages to this (hop and dart?)
#  The first stage is totally rigid; you got the direction you initially input for strict duration
#  The second stage considers how long you've been holding the input (during first stage?) and can alter direction a little

func _physics_process(delta:float):
	if body == null:
		return
	
	if state == State.Active:
		if engaged && Time.get_ticks_msec() - usage_timestamp < initial_msec + finesse_msec:
			#TODO (sam) need to raycast or something make sure we don't cheat physics?
			var attempt_dist = (initial_distance / (initial_msec / 1000.0)) * delta
			if sum_distance > 0:
				attempt_dist = (finesse_distance / (finesse_msec / 1000.0)) * delta

			var move_dir = direction
			if alignment == Alignment.Body:
				move_dir = move_dir.rotated(body.rotation)

			var move = move_dir * attempt_dist
			# TODO (sam) we probably want to do this from the bounds of the body somehow (instead of just the center)
			# TODO (sam) is there a big cost to getting space state or defining the ray?
			var space_state = get_world_2d().direct_space_state
			var raycast = PhysicsRayQueryParameters2D.create(body.global_position, move)
			var hit = space_state.intersect_ray(raycast)
			
			if hit != null && hit.has("position"):
				var hit_pos = hit["position"]
				var to_hit = hit_pos - body.global_position
				if to_hit.length_squared() < move.length_squared() && to_hit.dot(move) > 0:
					move = Vector2.ZERO
			
			body.global_position += move
			sum_distance += move.length()
		else:
			state = State.Cooldown
			usage_timestamp = Time.get_ticks_msec()
	elif state == State.Cooldown && !engaged:
		if Time.get_ticks_msec() - usage_timestamp >= cooldown_msec:
			state = State.Ready
	
	engaged = state == State.Active && Time.get_ticks_msec() - usage_timestamp < initial_msec

func engage(want_direction:Vector2):
	engaged = true
	direction = want_direction.normalized()
	if state == State.Ready:
		state= State.Active
		usage_timestamp = Time.get_ticks_msec()
		sum_distance = 0
		if body != null:
			initial_position = body.global_position

