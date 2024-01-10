extends CollisionShape2D

@export var num_to_spawn:int
@export var proto:PackedScene

func _ready():
	for i in num_to_spawn:
		var proto_instance:Node2D = proto.instantiate()
		var rect_shape:RectangleShape2D = shape as RectangleShape2D
		if rect_shape:
			proto_instance.position.x = randf_range(-rect_shape.size.x * .5, rect_shape.size.x * .5)
			proto_instance.position.y = randf_range(-rect_shape.size.y * .5, rect_shape.size.y * .5)
		else:
			var circle_shape:CircleShape2D = shape as CircleShape2D
			if circle_shape:
				var srpnow:Vector2 = Randomness.random_inside_unit_circle() * randf_range(0, circle_shape.radius)
				proto_instance.position = srpnow
			else:
				printerr("ERROR: Unsupported shape type: " + proto_instance.to_string())
	
		add_child(proto_instance)
