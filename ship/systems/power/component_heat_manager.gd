extends MultiplayerSynchronizer
class_name ComponentHeatManager

signal capacity_reached
signal completely_cooled
signal heat_changed

@onready var component : ShipComponent = get_parent() as ShipComponent
@export var heat_capacity : float = 100.0
@export var cur_heat : float = 0.0

@export var cooling_delay : float = 1.0
@export var cool_cooldown : float = 0.0

var tick_speed := 0.2


func _ready():
	await get_tree().create_timer(randf_range(0, tick_speed)).timeout
	tick()


func _process(delta: float) -> void:
	if cool_cooldown > 0: cool_cooldown -= delta


@rpc("any_peer", "call_local")
func add_heat(amount : float):
	#if not is_multiplayer_authority(): return
	if cur_heat < heat_capacity:
		cur_heat = min(heat_capacity, cur_heat + amount)
		heat_changed.emit()
		if cur_heat >= heat_capacity:
			capacity_reached.emit()
	
	cool_cooldown = cooling_delay


@rpc("any_peer", "call_local")
func remove_heat(amount : float):
	if cool_cooldown > 0: return
	#if not is_multiplayer_authority(): return
	if cur_heat > 0:
		cur_heat = max(0, cur_heat - amount)
		heat_changed.emit()
		if cur_heat <= 0:
			completely_cooled.emit()


func get_heat_ratio() -> float:
	return cur_heat/heat_capacity


func tick():
	if cur_heat > 0 and component.ship:# and is_multiplayer_authority():
		remove_heat(component.ship.cooling_manager.get_total_cooling_rate() * tick_speed)
	
	await get_tree().create_timer(tick_speed).timeout
	tick()
