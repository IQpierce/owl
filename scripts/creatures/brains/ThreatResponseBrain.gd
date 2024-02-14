extends Brain

class_name ThreatResponseBrain

@export var known_threats:Array[Dictionary]

func think():
	respond_to_threats(known_threats)

func respond_to_threats(known_threats:Array[Dictionary]) -> Array[Dictionary]:
	assert(false, "pure virtual, this should be overridden!!")
	return known_threats
