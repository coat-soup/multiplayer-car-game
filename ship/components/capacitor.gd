extends ShipComponent
class_name Capacitor


func on_install_to_ship(ship_manager : ShipManager):
	super.on_install_to_ship(ship_manager)
	ship_manager.power_manager.add_capacitor_component(self)

func on_uninstall_from_ship(ship_manager : ShipManager):
	super.on_uninstall_from_ship(ship_manager)
	ship_manager.power_manager.remove_capacitor_component(self)
	print("capacitor sending remove signal")
