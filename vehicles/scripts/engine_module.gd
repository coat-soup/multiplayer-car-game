extends VehicleModule
class_name EngineModule

@export var power := 100.0
@export var speed := 60.0


func setup():
	controller.engines.append(self)
	controller.update_engine_stats()
	broken.connect(controller.update_engine_stats)
	fixed.connect(controller.update_engine_stats)
	
	super.setup()


func get_power() -> float:
	return power if !is_broken else 0.0


func get_speed() -> float:
	return speed if !is_broken else 0.0
