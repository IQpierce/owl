extends ThreatResponseBrain

class_name ThreatResponseFallbackBrain


# The brain allows for "prioritization" of threat-handling. If the first threat_response_brain 
# 	reports itself as unable to contribute, we will fall back to the second; etc.

@export var threat_response_brains:Array[ThreatResponseBrain]


func _ready():
	assert(threat_response_brains.size() > 0)



func respond_to_threats(known_threats:Array[Dictionary]) -> Array[Dictionary]:
	for threat_response_brain in threat_response_brains:
		assert(threat_response_brain != null)
		
		known_threats = threat_response_brain.respond_to_threats(known_threats)
		
		if known_threats.is_empty():
			# All threats have been handled, no need to keep executing.
			return known_threats
	
	return known_threats
	


