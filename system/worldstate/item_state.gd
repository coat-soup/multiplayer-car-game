extends Resource
class_name ItemState

var item_prefab_path : String
var world_position : Vector3
var on_ship : bool

func _init(path : String, pos : Vector3, ship : bool) -> void:
	item_prefab_path = path
	world_position = pos
	on_ship = ship
