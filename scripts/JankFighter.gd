extends Node2D

# Tries to fix physics jank bugs that break the game.

@export var bodies_in_motion:Array[RigidBody2D]
@export var max_move_dist_sqr:float = 1000

const NUM_FRAMES_TO_SAVE = 2

var frame_moduloed_index:int = 0

# Keys are RigidBody2D's
# Values are Array[Dictionary]. Each Dictionary contains a bunch of body motion data.
var saved_body_data:Dictionary



func _ready():
	for body_in_motion in bodies_in_motion:
		var new_array:Array[Dictionary]
		for i in NUM_FRAMES_TO_SAVE:
			new_array.append(Dictionary())
		saved_body_data[body_in_motion] = new_array

func _process(delta:float):
	
	for body_in_motion:RigidBody2D in bodies_in_motion:
		if body_in_motion == null:
			continue
		
		# Check for massive teleport-move, restore if needed.
		assert(max_move_dist_sqr > 0)
		var last_frame:Dictionary = saved_body_data[body_in_motion][frame_moduloed_index]
		if last_frame.has("global_position"):
			var moved_dist:float = (body_in_motion.global_position - last_frame.global_position).length_squared()
			if moved_dist > max_move_dist_sqr:
				# We teleported. Move us back to where we were.
				push_warning("JANK DETECTED! Massive teleport distance of ", moved_dist, " ... restoring to previous frame position")
				body_in_motion.global_position = last_frame.global_position
				body_in_motion.rotation = last_frame.rotation
				body_in_motion.linear_velocity = last_frame.linear_velocity
				body_in_motion.angular_velocity = last_frame.angular_velocity
	
	frame_moduloed_index = (frame_moduloed_index + 1) % NUM_FRAMES_TO_SAVE

	for body_in_motion:RigidBody2D in bodies_in_motion:
		if body_in_motion == null:
			continue
		
		saved_body_data[body_in_motion][frame_moduloed_index] = {
			"global_position"		:	body_in_motion.global_position,
			"rotation"				:	body_in_motion.rotation,
			"linear_velocity"		:	body_in_motion.linear_velocity,
			"angular_velocity"		:	body_in_motion.angular_velocity
		}
