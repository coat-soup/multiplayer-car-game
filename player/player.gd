extends CharacterBody3D

class_name Player

@export var network_manager : PlayerNetworkManager
#@export var interaction_manager : InteractionManager
@export var movement_manager : PlayerMovement
@export var equipment_manager : EquipmentManager

var active : bool = true


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
