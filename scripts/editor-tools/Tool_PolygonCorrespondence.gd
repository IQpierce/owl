@tool

extends CollisionPolygon2D

class_name PolygonCorrespondence

@export var counterpart:PatchworkPolygon2D
@export var match_patchwork:bool = true
@export var thicken = false
@export var runtime_check_each_frame:bool = false
@export var runtime_sync_onready:bool = false
@export var editortime_sync_data:bool = false

func _ready():
	if !Engine.is_editor_hint():
		assert(counterpart != null)
		counterpart.matching_collider = self
		if runtime_sync_onready:
			sync_polygon_data()

func _process(delta:float):
	
	var in_editor:bool = Engine.is_editor_hint()
	
	if !in_editor && runtime_check_each_frame:
		# We're executing at runtime, and we should sync these data every frame.
		sync_polygon_data()
	elif in_editor && editortime_sync_data:
		# We're executing in the editor, and someone checked the checkbox to sync these.
		editortime_sync_data = false
		sync_polygon_data()

func sync_polygon_data():
	global_position = counterpart.global_position
	global_rotation = counterpart.global_rotation
	global_scale = counterpart.global_scale
	polygon = counterpart.polygon if match_patchwork else counterpart.raw_polygon
	#print(get_parent().name, global_scale, counterpart.global_scale, counterpart.global_rotation)

	# Setting a negative global_scale is inconsistent (sometimes reverting to all positive),
	# so lets always keep global_scale positive here and just flip vertices to compensate
	var real_global_scale = counterpart.global_scale
	var self_global_scale = global_scale
	var neg_scale = min(real_global_scale.x * self_global_scale.x, real_global_scale.y * self_global_scale.y) < 0
	if neg_scale || thicken:
		global_scale = Vector2(abs(real_global_scale.x), abs(real_global_scale.y))
		var new_polygon = PackedVector2Array()
		new_polygon.resize(polygon.size())

		var x_mul = -1 if real_global_scale.x < 0 else 1
		var y_mul = -1 if real_global_scale.y < 0 else 1
		# TODO (sam) It is a bit weird that we have to check rotations like this,
		# but we need for Top Right Feeding Hairs of Cuttlefish
		if counterpart.global_rotation - rotation > PI / 2:
			var temp = x_mul
			x_mul = y_mul
			y_mul = temp

		for i in polygon.size():
			new_polygon[i] = Vector2(polygon[i].x * x_mul, polygon[i].y * y_mul)
		if thicken:
			var poly_size = polygon.size()
			new_polygon.resize(poly_size * 2)
			for i in poly_size:
				new_polygon[i + poly_size] = new_polygon[poly_size - 1 - i] + Vector2(1 * x_mul * y_mul, 0)
		polygon = new_polygon
	#print(get_parent().name, polygon)
