extends ShipComponent
class_name Turret_Component

@export_range(-360, 360) var p_min := 0
@export_range(-360, 360) var p_max := 180

@export var turret_controller : TurretController

func _ready() -> void:
	turret_controller.p_min = p_min
	turret_controller.p_max = p_max
