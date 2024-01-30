extends SeekerBrain

class_name SeekByFunction

# This extremely flexible "seeker brain" can look for a particular function 
#	(including particular parameters, e.g. resource type) on bodies it "sees", 
#	and use that function to determine the body's relevance.

@export var func_name:String
@export var func_params:Array

func get_body_relevance(body:CollisionObject2D) -> float:
	assert(!func_name.is_empty())
	
	if body.has_method(func_name):
		return body.callv(func_name, func_params)
	
	return 0
	



