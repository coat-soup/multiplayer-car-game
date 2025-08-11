extends Node3D
class_name TurretStation

@export var turret_component : Turret_Component
@onready var interactable: Interactable = $Interactable

var controllable : Controllable
var cached_local_player : Player

@export var ammo_snap_points : Array[ItemSnapPoint]


func _ready() -> void:
	controllable = turret_component.turret_controller.control_manager
	controllable.interactable = interactable
	controllable._ready()
	
	turret_component.turret_station = self
	
	controllable.control_started.connect(on_control_started)
	controllable.control_ended.connect(on_control_ended)
	
	for snap in ammo_snap_points:
		snap.item_placed.connect(on_ammo_placed)
		snap.item_removed.connect(on_ammo_removed)


func on_control_started():
	if controllable.using_player.is_multiplayer_authority(): cached_local_player = controllable.using_player

func on_control_ended():
	if cached_local_player: cached_local_player.movement_manager.global_position = interactable.global_position


func on_ammo_placed(item : Item):
	update_ammo()


func on_ammo_removed(item : Item):
	update_ammo()


func update_ammo():
	var crates : Array[AmmoCrate] = []
	for snap in ammo_snap_points:
		var crate = snap.held_item as AmmoCrate
		if crate: crates.append(crate)
	
	turret_component.turret_controller.weapons_manager.set_ammo_crates(crates)
