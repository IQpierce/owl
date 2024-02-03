extends Node2D

class_name Stomach

@export var consumable_reservoir:ConsumableReservoir
@export var nodes_to_scale:Array[Node2D]
@export_range(0.0, 100.0) var min_x_scale:float = 0.805
@export_range(0.0, 100.0) var max_x_scale:float = 1.35

signal on_consumable_consumed(consumable_type:GameEnums.ConsumableType, amount:float)

func _ready():
	assert(consumable_reservoir != null)
	consumable_reservoir.on_amount_contained_changed.connect(self.on_container_change)
	
	for node_to_scale in nodes_to_scale:
		update_scales_based_on_amount(consumable_reservoir.amount_contained)

func update_scales_based_on_amount(amt:float):
	for node_to_scale in nodes_to_scale:
		var lerp_weight:float = inverse_lerp(0, consumable_reservoir.maximum_amount, amt)
		node_to_scale.scale.x = lerp(min_x_scale, max_x_scale, lerp_weight)

func on_container_change(_old_amount:float, new_amount:float):
	update_scales_based_on_amount(new_amount)

func on_pickup_consumed(pickup:Pickup):
	on_consumable_consumed.emit(pickup.consumable_type, pickup.consumable_units)

