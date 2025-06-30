extends Node3D
class_name POI

@export var POI_name : String

@export var docking_area : Area3D
@export var level_manager : LevelManager


func _ready() -> void:
	docking_area.body_entered.connect(on_body_entered_docking)


func on_body_entered_docking(body : Node3D):
	if is_multiplayer_authority():
		if body == level_manager.ship.movement_clone:
			level_manager.enter_POI(self)
