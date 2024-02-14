extends ThreatResponseBrain

class_name FlightResponseBrain

@export var run_away_brain:WanderBrain

var run_away_position:Vector2 = Vector2.INF
var cached_threats:Array[Dictionary]

func _ready():
	run_away_brain.on_target_location_changed.connect(on_new_runaway_location_chosen)

func on_new_runaway_location_chosen(runaway_location:Vector2):
	run_away_position = runaway_location

func respond_to_threats(known_threats:Array[Dictionary]) -> Array[Dictionary]:
	if cached_threats != known_threats:
		run_away_position = Vector2.INF
	
	if run_away_position.is_equal_approx(Vector2.INF):
		run_away_brain.think()
		assert(!run_away_position.is_equal_approx(Vector2.INF))
	
	cached_threats = known_threats
	
	return []
