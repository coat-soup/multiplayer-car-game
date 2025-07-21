extends ShipComponent
class_name Cooler

@export var cooling_rate : float = 5.0


func _ready() -> void:
	super._ready()
	
	ship.cooling_manager.add_cooler_component(self)
