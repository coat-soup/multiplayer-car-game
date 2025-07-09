extends ShipComponent
class_name Capacitor


func _ready() -> void:
	super._ready()
	
	ship.power_manager.add_capacitor_component(self)
