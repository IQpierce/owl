extends Node2D

class_name ConsumableReservoir


@export var consumable_type:GameEnums.ConsumableType = 0

@export var amount_contained:float = 0:
	get:
		return amount_contained
	set(new_amt):
		if (new_amt <= 0):
			new_amt = 0
			
		if (new_amt >= maximum_amount):
			new_amt = maximum_amount
		
		if (new_amt == amount_contained):
			return
		
		var old_amt:float = amount_contained
		amount_contained = new_amt
		on_amount_contained_changed.emit(old_amt, new_amt)

@export var maximum_amount:float = 0	# If nonzero, this defines a maximum that we can contain.

@export var decay_rate_per_sec:float = 0


signal on_amount_contained_changed(old_amount:float, new_amount:float)


func _process(delta:float):
	amount_contained -= decay_rate_per_sec * delta

# @returns the new amount
func change_consumable_amount(delta:float) -> float:
	amount_contained += delta
	return amount_contained

# @returns The new amount of the consumable, if this type of consumable is handled. Otherwise NAN.
func apply_consumable_change_by_type(change_consumable_type:GameEnums.ConsumableType, delta:float) -> float:
	if change_consumable_type == consumable_type:
		return change_consumable_amount(delta)
	
	return NAN
