extends Node
class_name ShipPowerManager

@export var power_systems : Array[PowerSystem]
@export var reactor : ShipReactor
@export var capacitors : int # TODO link to actual capacitor components
@onready var unused_capacitors : int = capacitors
