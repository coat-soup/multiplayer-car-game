extends Node
class_name GameManager

signal money_changed

@export var ship_holder : Node3D
@export var money : int = 2000
@export var ui : UIManager
@onready var stat_synchronizer: MultiplayerSynchronizer = $StatSynchronizer


func _ready() -> void:
	Global.game_manager = self
	Global.ui = ui
	Global.network_manager = $NetworkManager
	Global.level_manager = $LevelManager
	Global.mission_manager = $MissionManager
	
	stat_synchronizer.delta_synchronized.connect(on_money_changed)
	ui.update_money_label(money)


func _input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()


@rpc("any_peer", "call_local")
func request_change_money(change : int):
	if not multiplayer.is_server():
		return
	
	money += change
	ui.update_money_label(money)
	money_changed.emit()


func on_money_changed():
	money_changed.emit()
	ui.update_money_label(money)
