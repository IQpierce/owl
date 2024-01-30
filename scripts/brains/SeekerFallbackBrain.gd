extends SeekerBrain

# The brain allows for "prioritization" of seeking. If the first seeker_brain 
# fails to find anything, we will fall back to the second; etc.

@export var seeker_brains:Array[SeekerBrain]


func _ready():
	assert(seeker_brains.size() > 0)

func think():
	for seeker_brain in seeker_brains:
		assert(seeker_brain != null)
		
		var best_target:PhysicsBody2D = seeker_brain.seek()
		
		if best_target != null:
			process_seek_result(best_target)
			
			# If we found any target, no need to continue executing.
			#	We only need the fallbacks to process if the earlier cases failed.
			return
	
	# If we get here, all of our seeker brains failed to find anything.
	process_seek_result(null)
	
