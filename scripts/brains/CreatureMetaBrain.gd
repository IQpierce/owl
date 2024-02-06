extends Brain

class_name CreatureMetaBrain

@export var safe_mode_brains:Array[Brain]
@export var threat_mode_brains:Array[Brain]

var is_threat_mode:bool:
	get:
		return known_threats.size() > 0

# @TODO Clearly define the data in this dictionary...
# ...preferably by making it a concrete "struct" type instead of a Dictionary.
var known_threats:Array[Dictionary]

var last_think_timestamp:float = NAN

func think():
	var secs_since_last_think:float = Time.get_unix_time_from_system() - last_think_timestamp
	
	if is_threat_mode:
		var unhandled_threats:Array[Dictionary] = known_threats
		for threat_mode_brain in threat_mode_brains:
			assert(threat_mode_brain != null)
			unhandled_threats = threat_mode_brain.respond_to_threats(known_threats)
			if (unhandled_threats.is_empty()):
				break
		
		# tick down the relevance of all threats.
		if !is_nan(secs_since_last_think):
			var entries_to_erase:Array[Dictionary]
			for known_threat in known_threats:
				if known_threat.has("relevance_secs"):
					known_threat.relevance_secs -= secs_since_last_think
					if known_threat.relevance_secs <= 0:
						entries_to_erase.append(known_threat)
			
			for entry_to_erase in entries_to_erase:
				known_threats.erase(entry_to_erase)
		
	else:
		for safe_mode_brain in safe_mode_brains:
			safe_mode_brain.think()
	
	last_think_timestamp = Time.get_unix_time_from_system()
	

# @TODO Reconsider this simplistic formulation of "threat detection".
func on_damage_dealt(damage_amt:float, world_location:Vector2):
	on_new_threat_identified({
		"threat_level"		:	damage_amt,
		"world_location"	:	world_location,
		"relevance_secs"	:	15
	})

func on_new_threat_identified(threat_data:Dictionary):
	known_threats.append(threat_data)
	think()

