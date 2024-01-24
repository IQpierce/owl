extends "res://scripts/gfx/VectorPolygonRendering.gd"

# TODO This should not depend on a player
@export var boss:Player
@export var min_size_factor:float = 0.5
@export var flicker_speed:float = 10
@export var flicker_range:float = 0.3
@export var exhaust_chance: float = 0.3

var full_length:float

func _ready():
	if polygon && polygon.size() > 0:
		full_length = abs(polygon[2].y)

func _process(delta):
	if visible && boss != null:
		if boss.max_speed > 0 && polygon && polygon.size() > 2:
			var old_thrust_size = abs(polygon[2].y)
			var thrust_portion = clamp(boss.linear_velocity.length() / boss.max_speed, 0, 1)
			var min_thrust = full_length * min_size_factor
			var thrust_size = ((1 - thrust_portion) * min_thrust) + (thrust_portion * full_length)
			thrust_size = thrust_size + randf_range(-flicker_speed * delta, flicker_speed * delta)
			thrust_size = clamp(thrust_size, old_thrust_size - flicker_range, old_thrust_size + flicker_range)
			thrust_size = clamp(thrust_size, 0, full_length + flicker_range)
			polygon[2].y = -thrust_size

		# TODO (sam) attempting to spawn a duplicate of the thruster as exhaust but duplicates cannot be seen in scene
		# The duplicates are being generated (found in Remote Inspector)
		# Do they need to be added under the viewport instead of root?
		#if randf_range(0, 1) < exhaust_chance:
		#	#var exhaust = preload().instance()
		#	var exhaust = self.duplicate()
		#	exhaust.boss = null
		#	get_tree().get_root().add_child(exhaust)
		#	exhaust.position = position + Vector2(0, -100)
			
	
