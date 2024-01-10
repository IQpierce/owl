class_name Randomness

# Credit to angelonit here: https://www.reddit.com/r/godot/comments/vjge0n/could_anyone_share_some_code_for_finding_a/
static func random_inside_unit_circle() -> Vector2:
	var theta:float = randf() * 2 * PI
	return Vector2(cos(theta), sin(theta)) * sqrt(randf())

