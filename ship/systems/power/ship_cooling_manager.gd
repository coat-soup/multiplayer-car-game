extends Node
class_name ShipCoolingManager

@export var ship : ShipManager
@export var coolers : Array[Cooler]

var cached_cooling_rate : float = 0.0


func _ready() -> void:
	ship.power_manager.capacitors_changed.connect(cache_cooling_rate)


func add_cooler_component(cooler : Cooler):
	coolers.append(cooler)
	cooler.broken.connect(cache_cooling_rate)
	cooler.fixed.connect(cache_cooling_rate)
	cache_cooling_rate()


func remove_cooler_component(cooler : Cooler):
	var id = coolers.find(cooler)
	if id != -1:
		coolers.remove_at(id)
		cooler.broken.disconnect(cache_cooling_rate)
		cooler.fixed.disconnect(cache_cooling_rate)
		cache_cooling_rate()


func get_total_cooling_rate() -> float:
	var rate : float = 0.0
	for cooler in coolers:
		if not cooler.is_broken: rate += cooler.cooling_rate
	return rate * ship.power_manager.get_system_power("Cooling")


func cache_cooling_rate():
	cached_cooling_rate = get_total_cooling_rate()
