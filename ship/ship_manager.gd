extends Node3D
class_name ShipManager

@export var root : Node
@export var movement_clone : ShipMovementClone
@export var movement_manager : ShipMovementManager
@export var main_target_component : ShipComponent
@export var gravity_bounds: Area3D


func _ready() -> void:
	movement_clone.global_position = global_position
	movement_clone.global_rotation = global_rotation
	(movement_clone.get_node("RemoteTransform3D") as RemoteTransform3D).remote_path = get_path()
	movement_manager.ship = movement_clone
	movement_manager.controllable.synchronizer = movement_clone.get_node("MultiplayerSynchronizer") as MultiplayerSynchronizer
