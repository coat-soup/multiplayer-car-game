extends Node3D

class_name Player

@export var network_manager : PlayerNetworkManager
#@export var interaction_manager : InteractionManager
@export var movement_manager : PlayerMovement
@export var equipment_manager : EquipmentManager
@export var camera : Camera3D
@export var health: Health

@onready var ui : UIManager = get_tree().get_first_node_in_group("ui") as UIManager

var active : bool = true

var respawn_point : Node3D


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())


func _ready() -> void:
	if is_multiplayer_authority():
		health.took_damage.connect(on_damaged)
		health.healed.connect(on_damaged)
		health.died.connect(on_died)
		camera.current = true
		
		await get_tree().create_timer(0.2).timeout
		movement_manager.global_position = network_manager.network_manager.ship.spawn_point.global_position


func on_damaged(source):
	ui.update_health_bar(health.cur_health)
	if health.cur_health == 0:
		await get_tree().create_timer(0.2).timeout
		on_damaged(source)


func on_died():
	respawn_point = movement_manager.ship.spawn_point
	
	health.heal.rpc(100, -1)
	movement_manager.player.velocity = Vector3.ZERO
	movement_manager.global_rotation = Vector3.ZERO
	movement_manager.global_position = Vector3(0,2,0) if not respawn_point else respawn_point.global_position
