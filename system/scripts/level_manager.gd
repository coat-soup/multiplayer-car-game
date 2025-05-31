extends Node3D
class_name LevelManager

@export var friendly_station : PackedScene
var start_POI : POI
var end_POI : POI

@export var mission_manager : MissionManager
@export var ship : ShipManager

@export var level_size := 1000.0


func _ready() -> void:
	generate_level()


func generate_level():
	print("generating level")
	ship.movement_clone.velocity = Vector3.ZERO
	ship.movement_clone.position = Vector3.ZERO
	
	start_POI = friendly_station.instantiate() as POI
	start_POI.level_manager = self
	add_child(start_POI)
	start_POI.position = Util.random_point_in_sphere(400.0, 350.0)
	start_POI.global_rotation = Util.random_point_in_sphere(1.0)
	
	end_POI = friendly_station.instantiate() as POI
	end_POI.level_manager = self
	add_child(end_POI)
	end_POI.position = Util.random_point_in_sphere(level_size * 1.1, level_size * 0.9)
	end_POI.global_rotation = Util.random_point_in_sphere(1.0)
	
	await get_tree().create_timer(0.2).timeout
	mission_manager.generate_missions()


func enter_POI(poi : POI):
	print("receiving poi dock")
	if poi == end_POI:
		print("LEVEL COMPLETE. RELOADING\n")
		reset_level.rpc()

@rpc("any_peer", "call_local")
func reset_level():
	for child in get_children():
		child.queue_free()
	
	generate_level()
