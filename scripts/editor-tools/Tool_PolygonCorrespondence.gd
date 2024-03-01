@tool

extends CollisionPolygon2D

class_name PolygonCorrespondence

@export var counterpart:PatchworkPolygon2D
@export var match_patchwork:bool = true
@export var runtime_check_each_frame:bool = false
@export var runtime_sync_onready:bool = false
@export var editortime_sync_data:bool = false

func _ready():
	assert(counterpart != null)
	counterpart.matching_collider = self
	if !Engine.is_editor_hint() && runtime_sync_onready:
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
	self.global_position = counterpart.global_position
	self.global_rotation = counterpart.global_rotation
	self.global_scale = counterpart.global_scale
	self.polygon = counterpart.patchwork if match_patchwork else counterpart.polygon
