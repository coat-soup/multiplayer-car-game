extends Node3D
class_name ShipManager

@export var root : Node
@export var movement_clone : ShipMovementClone
@export var movement_manager : ShipMovementManager
@export var main_target_component : ShipComponent
@export var gravity_bounds: Area3D
@export var setup_on_load := true
@export var movement_clone_prefab : PackedScene
@export var spawn_point : Node3D
@export var item_manager : ShipItemManager
@export var component_manager : ShipComponentManager
@export var fire_manager : FireManager
@export var radar_manager : RadarManager


func _ready() -> void:
	if setup_on_load:
		setup()


func setup():
	root = get_parent()
	#movement_clone = movement_clone_prefab.instantiate()
	#root.add_child.call_deferred(movement_clone)
	while not movement_clone or not movement_clone.is_inside_tree():
		if not multiplayer.is_server(): request_set_movement_clone.rpc()
		await get_tree().process_frame
	movement_clone.global_position = global_position
	movement_clone.global_rotation = global_rotation
	(movement_clone.get_node("RemoteTransform3D") as RemoteTransform3D).remote_path = get_path()
	movement_manager.ship = movement_clone
	movement_clone.ship_manager = self
	movement_manager.controllable.synchronizer = movement_clone.get_node("MultiplayerSynchronizer") as MultiplayerSynchronizer
	movement_manager.controllable.root_owner = movement_clone


@rpc("any_peer", "call_local")
func request_set_movement_clone():
	if multiplayer.is_server() and movement_clone:
		movement_manager.ui.display_chat_message("Returning clone set request")
		set_peer_movement_clone.rpc_id(multiplayer.get_remote_sender_id(), movement_clone.get_path())


@rpc("any_peer", "call_local")
func set_peer_movement_clone(node_path : NodePath):
	movement_clone = get_tree().root.get_node_or_null(node_path)
