extends Node2D
class_name Hopdart

enum Motion { Direct, Impulse }
enum Alignment { Screen, Body }
enum State { Ready, Active, Cooldown }

@export var motion = Motion.Direct #TODO (sam) Direct Motion into the crevice of ZoomAsteroid is a consistent Collision Jank test
@export_group("Direct Motion")
@export var initial_distance:float = 50
@export var finesse_distance:float = 100
@export_group("Impulse Motion")
@export var initial_impulse:float = 40
@export var finesse_impulse:float = 20
@export_group("")
@export var alignment:Alignment = Alignment.Screen
@export_range(16, 160) var direction_grace_msec = 48
@export_range(16, 1000) var initial_msec:int = 100
@export_range(16, 1000) var finesse_msec:int = 200
@export var cooldown_msec:int = 0
@export var end_drift:float = 0.92

var body:Thing = null
var state:State = State.Ready
var engaged:bool = false
var sum_distance:float = 0
var sum_move:Vector2 = Vector2.ZERO
var usage_timestamp:int = 0
var direction = Vector2.ZERO
var prev_move = Vector2.ZERO

#TODO (sam) There might wanna be two stages to this (hop and dart?)
#  The first stage is totally rigid; you got the direction you initially input for strict duration
#  The second stage considers how long you've been holding the input (during first stage?) and can alter direction a little

func _physics_process(delta:float):
	if body == null:
		return

	var now = Time.get_ticks_msec()

	if state == State.Active:
		if engaged && now - usage_timestamp < initial_msec + finesse_msec:
			var move_dir = direction
			if alignment == Alignment.Body:
				move_dir = move_dir.rotated(body.rotation)

			if motion == Motion.Direct:
				var attempt_dist = (initial_distance / (initial_msec / 1000.0)) * delta
				if now - usage_timestamp > initial_msec:
					attempt_dist = (finesse_distance / (finesse_msec / 1000.0)) * delta

				var move = move_dir * attempt_dist
				# TODO (sam) we probably want to do this from the bounds of the body somehow (instead of just the center)
				# TODO (sam) is there a big cost to getting space state or defining the ray?
				var space_state = get_world_2d().direct_space_state
				var raycast = PhysicsRayQueryParameters2D.create(body.global_position, move)
				var hit = space_state.intersect_ray(raycast)
				
				if hit != null && hit.has("position"):
					var hit_pos = hit["position"]
					var to_hit = hit_pos - body.global_position
					var other:Node2D = null
					if hit.has("collider"):
						other = hit["collider"]
					if other != body && to_hit.length_squared() < move.length_squared() && to_hit.dot(move) > 0:
						move = Vector2.ZERO
				
				body.global_position += move
				sum_distance += move.length()
				sum_move += move
				prev_move = move
			elif motion == Motion.Impulse:
				var impulse = initial_impulse
				if now - usage_timestamp > initial_msec:
					impulse = finesse_impulse
				body.apply_central_impulse(direction * impulse)
				var approx_dist = impulse * delta * delta
				sum_distance += approx_dist
				sum_move += direction * approx_dist
				prev_move = direction * impulse
		else:
			state = State.Cooldown
			usage_timestamp = now
	elif state == State.Cooldown && !engaged:
		if now - usage_timestamp >= cooldown_msec:
			state = State.Ready
	
	engaged = state == State.Active && now - usage_timestamp < initial_msec

	if !engaged && prev_move.length_squared() > 1:
		prev_move *= end_drift
		if motion == Motion.Direct:
			body.global_position += prev_move
		if motion == Motion.Impulse:
			var vel_perp_prev = body.linear_velocity - body.linear_velocity.project(prev_move.normalized())
			body.linear_velocity = prev_move + vel_perp_prev


func engage(want_direction:Vector2):
	engaged = true
	if state == State.Ready:
		state = State.Active
		usage_timestamp = Time.get_ticks_msec()
		sum_distance = 0
		sum_move = Vector2.ZERO

	if state == State.Active && Time.get_ticks_msec() - usage_timestamp < direction_grace_msec:
		direction = want_direction.normalized()

