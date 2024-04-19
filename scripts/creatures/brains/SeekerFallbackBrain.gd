extends SeekerBrain

class_name SeekerFallbackBrain

# The brain allows for "prioritization" of seeking. If the first seeker_brain 
# fails to find anything, we will fall back to the second; etc.

@export var sub_think_seek = false

# If a member of this list is a SeekerBrain, seek() will be called on it.
#	Only the last item is allowed to be a non-Seeker-brain, as a final fallback.
@export var prioritized_brains:Array[Brain]

var thought = false

func _process(delta:float):
	thought = false
	super._process(delta)
	if !thought && sub_think_seek:
		var quick_seeked = last_seeked_target
		if quick_seeked != null && !is_body_detectable(quick_seeked):
			quick_seeked = null
		process_seek_result(quick_seeked, true)

func _ready():
	assert(prioritized_brains.size() > 0)

func think():
	thought = true
	for brain in prioritized_brains:
		var seeker_brain:SeekerBrain = brain as SeekerBrain
		if seeker_brain:
		
			var best_target:PhysicsBody2D = seeker_brain.seek()
			
			if best_target != null || seeker_brain.last_seeked_target != null:
				process_seek_result(best_target)
				last_seeked_target = seeker_brain.last_seeked_target
				if best_target != null:
					last_seeked_target = best_target
				
				# If we found any target, no need to continue executing.
				#	We only need the fallbacks to process if the earlier cases failed.
				return
		elif last_seeked_target == null:
			# We only allow a non-seeker brain as the final in the list of fallbacks.
			assert(prioritized_brains[prioritized_brains.size()-1] == brain)
			brain.think()
			return
	
	# If we get here, all of our seeker brains failed to find anything.
	process_seek_result(null)
	
