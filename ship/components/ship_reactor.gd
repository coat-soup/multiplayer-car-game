extends ShipComponent
class_name ShipReactor

signal reactor_state_changed

@export var fuel_drain_rate : float = 0.3
@onready var fuel_rod_snap_point: ItemSnapPoint = $FuelRodSnapPoint

var fuel_rod : FuelRod
@export var fuel_tick_interval : float = 1.0

@export var power_manager : ShipPowerManager
var active : bool


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


func startup():
	if not active and has_fuel():
		active = true
		reactor_state_changed.emit()


func shutdown():
	if active:
		active = false
		reactor_state_changed.emit()


func on_fuel_inserted(item : Item):
	fuel_rod = item as FuelRod
	fuel_rod.fuel_emptied.connect(shutdown)
	startup()


func on_fuel_removed(item : Item):
	fuel_rod.fuel_emptied.disconnect(shutdown)
	fuel_rod = null
	shutdown()


func has_fuel() -> bool:
	return fuel_rod != null and fuel_rod.cur_fuel > 0
