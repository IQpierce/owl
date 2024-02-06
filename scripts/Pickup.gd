extends RigidBody2D

class_name Pickup

@export var consumable_type:GameEnums.ConsumableType
@export var consumable_units:float = 0

@onready var collected_sfx:AudioStreamPlayer2D = $CollectedSFX

func on_picked_up(picker_upper:Node) -> void:
	var picker_upper_creature:Creature = picker_upper as Creature
	if picker_upper_creature != null:
		if picker_upper_creature.consume_pickup(self):
			
			if collected_sfx:
				collected_sfx.reparent(get_parent())
				
				if picker_upper is Player:
					collected_sfx.volume_db += 10
					collected_sfx.pitch_scale = randf_range(.9, 1)
				else:
					collected_sfx.pitch_scale = randf_range(.75, .85)
					
				collected_sfx.play()
			
			queue_free()
		else:
			return

func get_consumable_units_contained(check_type:GameEnums.ConsumableType) -> float:
	if consumable_type == check_type:
		return consumable_units
	else:
		return 0
