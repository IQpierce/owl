extends Node2D

class_name Stomach

@export var consumable_reservoir:ConsumableReservoir
@export var polygons_to_scale:Array[Polygon2D]
@export var colliders_to_scale:Array[CollisionPolygon2D]
@export_range(0.0, 100.0) var min_x_scale:float = 0.805
@export_range(0.0, 100.0) var max_x_scale:float = 1.35

signal on_consumable_consumed(consumable_type:GameEnums.ConsumableType, amount:float)

func _ready():
	assert(consumable_reservoir != null)
	consumable_reservoir.on_amount_contained_changed.connect(self.on_container_change)
	update_scales_based_on_amount(-1, consumable_reservoir.amount_contained)

func update_scales_based_on_amount(old_amt:float, amt:float):
	var max_count = max(polygons_to_scale.size(), colliders_to_scale.size())
	for index in max_count:
		var old_lerp_weight = 1.0
		var old_scale = 1.0
		if old_amt >= 0:
			old_lerp_weight = inverse_lerp(0, consumable_reservoir.maximum_amount, old_amt)
			old_scale = lerp(min_x_scale, max_x_scale, old_lerp_weight)
		var lerp_weight:float = inverse_lerp(0, consumable_reservoir.maximum_amount, amt)
		var scale_change = lerp(min_x_scale, max_x_scale, lerp_weight) / old_scale
		if polygons_to_scale.size() > index && polygons_to_scale[index] != null:
			for vert in polygons_to_scale[index].polygon.size():
				polygons_to_scale[index].polygon[vert].x *= scale_change
			polygons_to_scale[index].queue_redraw()
		if colliders_to_scale.size() > index && colliders_to_scale[index] != null:
			for vert in colliders_to_scale[index].polygon.size():
				colliders_to_scale[index].polygon[vert].x *= scale_change

func on_container_change(old_amount:float, new_amount:float):
	update_scales_based_on_amount(old_amount, new_amount)

func on_pickup_consumed(pickup:Pickup):
	on_consumable_consumed.emit(pickup.consumable_type, pickup.consumable_units)

