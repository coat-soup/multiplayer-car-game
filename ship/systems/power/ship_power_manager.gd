extends Node
class_name ShipPowerManager

signal capacitors_changed

@export var power_systems : Array[PowerSystem]
@export var reactor : ShipReactor
@export var capacitors : Array[Capacitor]
@onready var unused_capacitors : int = len(capacitors)
@onready var broken_capacitors : int = 0


func _ready() -> void:
	if reactor: reactor.power_manager = self


@rpc("any_peer", "call_local")
func set_system_capacitors(id : int, amount : int):
	var change = min(unused_capacitors, max(-power_systems[id].assigned_capacitors, min(power_systems[id].max_capacitors - power_systems[id].assigned_capacitors, amount - power_systems[id].assigned_capacitors)))
	power_systems[id].assigned_capacitors += change
	power_systems[id].capacitors_changed.emit()
	capacitors_changed.emit()
	unused_capacitors -= change


func get_system(system_name : String) -> PowerSystem:
	for system in power_systems:
		if system.system_name == system_name: return system
	
	return null


func get_system_power(system_name : String) -> float: # (range 0 to 1)
	if not reactor.active: return 0
	for system in power_systems:
		if system.system_name == system_name: return float(system.assigned_capacitors)/float(system.max_capacitors)
	return 0


func add_capacitor_component(capacitor : Capacitor):
	if !capacitor.is_broken: unused_capacitors += 1
	else: broken_capacitors += 1
	
	capacitors.append(capacitor)
	capacitor.broken.connect(on_capacitor_broken)
	capacitor.fixed.connect(on_capacitor_fixed)
	
	capacitors_changed.emit()


func remove_capacitor_component(capacitor : Capacitor):
	print("power manager removing capacitor")
	if !capacitor.is_broken:
		if unused_capacitors <= 0: unassign_random_capacitor()
		unused_capacitors -= 1
	else: broken_capacitors -= 1
	
	var id = capacitors.find(capacitor)
	capacitors.remove_at(id)
	capacitor.broken.disconnect(on_capacitor_broken)
	capacitor.fixed.disconnect(on_capacitor_fixed)
	
	capacitors_changed.emit()


# no rpc, called automatically on all clients already
func unassign_random_capacitor():
	if not is_multiplayer_authority(): return
	
	var weights : Array[float] = []
	for system in power_systems:
		weights.append(system.assigned_capacitors)
	var system = Util.weighted_random(range(len(power_systems)), weights)
	
	set_system_capacitors.rpc(system, power_systems[system].assigned_capacitors -1)


func get_active_capacitor_ratio() -> float:
	return float(len(capacitors) - unused_capacitors - broken_capacitors)/float(len(capacitors))


func on_capacitor_broken():
	unused_capacitors -= 1
	broken_capacitors += 1
	unassign_random_capacitor() # calls cap changed signal


func on_capacitor_fixed():
	unused_capacitors += 1
	broken_capacitors -= 1
	capacitors_changed.emit()
