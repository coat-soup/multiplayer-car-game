extends Node3D

@export var turret_component : Turret_Component
@onready var interactable: Interactable = $Interactable

var controllable : Controllable
var cached_local_player : Player

func _ready() -> void:
	controllable = turret_component.turret_controller.control_manager
	controllable.interactable = interactable
	controllable._ready()
	
	controllable.control_started.connect(on_control_started)
	controllable.control_ended.connect(on_control_ended)


func on_control_started():
	if controllable.using_player.is_multiplayer_authority(): cached_local_player = controllable.using_player

func on_control_ended():
	if cached_local_player: cached_local_player.movement_manager.global_position = interactable.global_position
