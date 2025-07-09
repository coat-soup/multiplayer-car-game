extends Node3D
class_name LevelManager

@export var friendly_station : PackedScene
var start_POI : POI
var end_POI : POI

@export var network_manager : NetworkManager
@export var mission_manager : MissionManager
@export var ship : ShipManager
@export var item_physics_manager : ItemPhysicsDupeManager

@export var level_size := 2000.0
var level_gen_seed : int = -1

@export var item_spawner : MultiplayerSpawner
#@export var items_spawned : Array[Item]

func _ready() -> void:
	for scene in Util.get_scenes_in_folder("res://items/scenes/"):
		item_spawner.add_spawnable_scene(scene)

func setup(_multiplayer):
	_multiplayer.peer_connected.connect(generate_for_new_connection)
	reset_level()


func spawn_item(prefab : PackedScene, pos) -> Item:
	#if not is_multiplayer_authority(): return
	
	#item_spawner.add_spawnable_scene(prefab.resource_path)
	var item = prefab.instantiate() as Item
	#var item = item_spawner.spawn(prefab)
	print("spawned: ", item)
	ship.add_child(item, true)
	item.global_position = pos
	return item


func generate_level():
	#if not is_multiplayer_authority(): return
	print("generating level")
	ship.movement_clone.velocity = Vector3.ZERO
	ship.movement_clone.position = Vector3.ZERO
	
	start_POI = friendly_station.instantiate() as POI
	start_POI.level_manager = self
	add_child(start_POI)
	start_POI.position = Vector3(-20,-30,-300)
	#start_POI.position = Util.random_point_in_sphere(400.0, 350.0)
	#start_POI.global_rotation = Util.random_point_in_sphere(1.0)
	
	end_POI = friendly_station.instantiate() as POI
	end_POI.level_manager = self
	add_child(end_POI)
	end_POI.position = Util.random_point_in_sphere(level_size * 1.1, level_size * 0.9)
	end_POI.global_rotation = Util.random_point_in_sphere(1.0)
	
	#await get_tree().process_frame
	if is_multiplayer_authority():
		mission_manager.generate_missions()


func generate_for_new_connection(peer_id : int):
	if multiplayer.is_server() or true:
		generate_from_seed.rpc_id(peer_id, level_gen_seed)


@rpc("any_peer", "call_local")
func generate_from_seed(s : int):
	seed(s)
	level_gen_seed = s
	generate_level()


func enter_POI(poi : POI):
	print("receiving poi dock")
	if poi == end_POI:
		print("LEVEL COMPLETE. RELOADING\n")
		reset_level.rpc()


@rpc("any_peer", "call_local")
func reset_level():
	for child in get_children():
		child.queue_free()
	
	if is_multiplayer_authority():
		generate_from_seed.rpc(randi())


# DOESNT WORK - CANT RPC RESOURCES
@rpc("any_peer", "call_local")
func generate_from_world_state(state : WorldState):
	print("\n Generating world for new player")
	for item in state.loose_items:
		spawn_item(load(item.item_prefab_path), item.world_position)
		print("spawning loose item: ", item)
