extends Node2D
class_name Gun

enum AffectMotionMode { Never, Always, OnShot }

@export var affect_motion_mode:AffectMotionMode = AffectMotionMode.Never
@export_range(0.0, 1.0) var shoot_turn_damp:float = 1
@export var shot_proto:PackedScene
@export var shot_force:float
@export var cooldown_duration_secs:float
@export var inherit_velocity:RigidBody2D
@export var immune_to_shots:Array[PhysicsBody2D]
@export var shot_parent:Node2D

# TODO (sam) See bullet: This is placeholder
@export var camera_track:TrackThrusterCameraCartridge = null
@export var camera_pull_factor:float = 0

@onready var lazer:AudioStreamPlayer2D = $Lazer

var body:RigidBody2D = null



var cooldown_timestamp:int

func is_waiting_on_cooldown():
	return Time.get_ticks_msec() < cooldown_timestamp

func shoot(moving:bool, turning:bool):
	if affect_motion_mode == AffectMotionMode.Always:
		affect_motion(moving, turning)

	if (is_waiting_on_cooldown()):
		return

	if affect_motion_mode == AffectMotionMode.OnShot:
		affect_motion(moving, turning)

	var shot_instance:Bullet = shot_proto.instantiate()
	shot_instance.global_position = global_position
	shot_instance.global_rotation = global_rotation
	var initial_velocity:Vector2 = Vector2(0, -1).rotated(global_transform.get_rotation())
	initial_velocity *= shot_force
	initial_velocity += inherit_velocity.get_linear_velocity()
	shot_instance.set_linear_velocity(initial_velocity)
	
	shot_instance.ignore_bodies.append_array(immune_to_shots)

	shot_instance.camera_track = camera_track
	shot_instance.camera_pull_factor = camera_pull_factor
	
	shot_parent.get_parent().add_child(shot_instance)
	cooldown_timestamp = Time.get_ticks_msec() + (cooldown_duration_secs * 1000);
	
	# lazer audio
	lazer.play()

func affect_motion(moving:bool, turning:bool):
	if body != null && !turning:
		body.angular_velocity *= shoot_turn_damp
