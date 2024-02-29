extends PatchworkPolygon2D
class_name InjectedPolygon2D

# TODO (sam) This is pretty gross, but Godot doesn't support exporting arbitrary data class, so we're stuck with this or a dictionary.
@export var injectee_open:int = 0
@export var injectee_close:int = 0

static func compare(a: InjectedPolygon2D, b:InjectedPolygon2D):
	return a.injectee_open < b.injectee_close

func _build_on_ready() -> bool:
	return false

func _draw():
	pass
