extends ShipComponent
class_name Cooler

@export var cooling_rate : float = 5.0


func on_install_to_ship(ship_manager : ShipManager):
	super.on_install_to_ship(ship_manager)
	ship_manager.cooling_manager.add_cooler_component(self)


func on_uninstall_from_ship(ship_manager : ShipManager):
	super.on_uninstall_from_ship(ship_manager)
	ship_manager.cooling_manager.remove_cooler_component(self)
