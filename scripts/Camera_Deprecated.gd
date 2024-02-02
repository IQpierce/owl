#TODO (sam) We want to move everything to CameraRig and remove this WHEN we know it won't break scenes
extends Camera2D
class_name Camera_Deprecated

var attention_center:Vector2
var center_priority:int

func pique_curiousity(focus_global:Vector2, priority:int):
	var take_priority = priority > center_priority
	if !take_priority && priority == center_priority:
		take_priority = (focus_global - global_position).length_squared() < (attention_center - global_position).length_squared()

	if take_priority:
		attention_center = focus_global
		center_priority = priority
