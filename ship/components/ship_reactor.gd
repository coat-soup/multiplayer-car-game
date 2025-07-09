extends ShipComponent
class_name ShipReactor

@export var fuel_drain_rate : float = 0.3
@onready var fuel_rod_snap_point: ItemSnapPoint = $FuelRodSnapPoint

var fuel_rod : FuelRod
@export var fuel_tick_interval : float = 1.0

@export var power_manager : ShipPowerManager


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	
	fuel_rod_snap_point.item_placed.connect(on_fuel_inserted)
	fuel_rod_snap_point.item_removed.connect(on_fuel_removed)
	fuel_drain_tick()

func fuel_drain_tick():
	if not is_multiplayer_authority(): return
	
	if fuel_rod and fuel_rod.cur_fuel > 0:
		fuel_rod.drain_fuel(fuel_drain_rate * fuel_tick_interval * (1 if not power_manager else power_manager.get_active_capacitor_ratio()))
	
	await get_tree().create_timer(fuel_tick_interval).timeout
	fuel_drain_tick()


func on_fuel_inserted():
	fuel_rod = fuel_rod_snap_point.held_item


func on_fuel_removed():
	fuel_rod = null


func has_fuel() -> bool:
	return fuel_rod != null and fuel_rod.cur_fuel > 0
