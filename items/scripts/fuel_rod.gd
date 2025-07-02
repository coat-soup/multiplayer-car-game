extends Item
class_name FuelRod

signal fuel_emptied

@export var max_fuel := 100.0
@onready var cur_fuel : float = max_fuel

@onready var fuel_label: Label3D = $FuelLabel

var reactor : ShipReactor


func drain_fuel(amount: float):
	cur_fuel -= amount
	
	fuel_label.text = str(round(cur_fuel))
	
	if cur_fuel <= 0: fuel_emptied.emit()
