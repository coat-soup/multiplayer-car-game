extends Node3D
class_name Item

@export var physics_dupe : RigidBody3D
@export var dupe_RT : RemoteTransform3D

@export var local_position : Vector3 # for multiplayer sync
@export var local_rotation : Vector3

@export var on_ship : ShipManager
var pending_exit := false

func _physics_process(delta: float) -> void:
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
