extends Node3D
class_name Item

@export var physics_dupe : RigidBody3D
@export var dupe_RT : RemoteTransform3D

@export var local_position : Vector3 # for multiplayer sync
@export var local_rotation : Vector3

@export var on_ship : ShipManager
var pending_exit := false

var velo_calc : Vector3

@onready var impact_audio: AudioStreamPlayer3D = $ImpactAudio


func _ready() -> void:
	physics_dupe.body_entered.connect(on_collided)


func on_collided(_body):
	print("collided with force ", velo_calc)
	if velo_calc.length() >= 0.05:
		impact_audio.pitch_scale = randf_range(0.9,1.1)
		impact_audio.play()


func _physics_process(_delta: float) -> void:
	velo_calc = physics_dupe.position - local_position
	if is_multiplayer_authority():
		local_position = physics_dupe.position
		local_rotation = physics_dupe.rotation
	if on_ship:
		position = local_position
		rotation = local_rotation


@rpc("any_peer", "call_local")
func set_auth(id):
	set_multiplayer_authority(id)
	physics_dupe.set_multiplayer_authority(id)
