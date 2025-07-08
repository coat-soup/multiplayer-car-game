extends Node
class_name ShipPowerManager

@export var power_systems : Array[PowerSystem]
@export var reactor : ShipReactor
@export var capacitors : int # TODO link to actual capacitor components
@onready var unused_capacitors : int = capacitors


@rpc("any_peer", "call_local")
func set_system_capacitors(id : int, capacitors : int):
	var change = min(unused_capacitors, max(-power_systems[id].assigned_capacitors, min(power_systems[id].max_capacitors - power_systems[id].assigned_capacitors, capacitors - power_systems[id].assigned_capacitors)))
	power_systems[id].assigned_capacitors += change
	power_systems[id].capacitors_changed.emit()
	unused_capacitors -= change
