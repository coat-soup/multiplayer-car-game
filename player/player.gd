extends CharacterBody3D

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


func on_damaged():
	ui.update_health_bar(health.cur_health)
	if health.cur_health == 0:
		await get_tree().create_timer(0.2).timeout
		on_damaged()


func on_died():
	health.heal.rpc(100, -1)
	velocity = Vector3.ZERO
	global_rotation = Vector3.ZERO
	global_position = Vector3(0,2,0) if not respawn_point else respawn_point.global_position
