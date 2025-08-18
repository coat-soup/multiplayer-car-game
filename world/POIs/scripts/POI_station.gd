extends POI
class_name POIStation

@export var docking_area : Area3D


func _ready() -> void:
	docking_area.body_entered.connect(on_body_entered_docking)


func on_body_entered_docking(body : Node3D):
	pass
	if is_multiplayer_authority():
		if body == level_manager.ship.movement_clone:
			level_manager.enter_POI(self)
