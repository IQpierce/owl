extends CollisionShape2D

@export var num_to_spawn:int
@export var proto:PackedScene	# TODO: Make this an array, pick randomly from it, try to keep the distribution even...?
@export var exclude_inner_percentage:float = 0.0

func _ready():
	if not is_visible_in_tree():
		return
	
	assert(exclude_inner_percentage >= 0.0 && exclude_inner_percentage < 1.0)
	
	for i in num_to_spawn:
		var proto_instance:Node2D = proto.instantiate()
		
		var rand_spawn_position:Vector2
		
		var rect_shape:RectangleShape2D = shape as RectangleShape2D
		if rect_shape:
			rand_spawn_position.x = randf_range(-rect_shape.size.x * .5, rect_shape.size.x * .5)
			rand_spawn_position.y = randf_range(-rect_shape.size.y * .5, rect_shape.size.y * .5)
			
			if exclude_inner_percentage > 0.0:
				push_error("@TODO: Implement exclude_inner_percentage for rect spawn areas!")
		else:
			var circle_shape:CircleShape2D = shape as CircleShape2D
			if circle_shape:
				rand_spawn_position = (Randomness.random_on_unit_circle() * randf_range(circle_shape.radius * exclude_inner_percentage, circle_shape.radius))
			else:
				printerr("ERROR: Unsupported shape type: " + proto_instance.to_string())
		
		proto_instance.position = rand_spawn_position
		
		add_child(proto_instance)
