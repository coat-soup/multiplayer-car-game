extends Resource
class_name ShipData

@export var ship_name : String
@export var buy_price : int

@export_multiline var description : String

@export var prefab : PackedScene
@export var movement_prefab : PackedScene


func spawn_instance(position : Vector3, parent : Node) -> ShipManager:
	var ship = prefab.instantiate() as ShipManager
	ship.movement_clone = movement_prefab.instantiate()
	
	parent.add_child(ship, true)
	parent.add_child(ship.movement_clone, true)
	
	ship.position = position
	ship.movement_clone.position = position
	
	ship.setup()
	
	return ship
