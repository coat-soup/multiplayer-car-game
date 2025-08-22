extends Node3D
class_name LevelManager

@export var friendly_station : PackedScene
var start_station : POIStation
var end_station : POIStation

@export var POIs : Array[POIListing]

@export var network_manager : NetworkManager
@export var mission_manager : MissionManager
@export var ship : ShipManager
@export var item_physics_manager : ItemPhysicsDupeManager
@export var enemy_manager : EnemyManager

@export var level_size := 2000.0
var level_gen_seed : int = -1

@export var item_spawner : MultiplayerSpawner
#@export var items_spawned : Array[Item]

var tracked_spawnable_items : Array[String]

var r : RandomNumberGenerator


func _ready() -> void:
	for data_path in Util.get_files_in_folder("res://items/item_data/", "tres"):
		var item_data : ItemData = load(data_path) as ItemData
		item_spawner.add_spawnable_scene(item_data.prefab_path)


func setup(_multiplayer):
	_multiplayer.peer_connected.connect(generate_for_new_connection)
	enemy_manager.level_manager = self
	enemy_manager.check_for_enemy_spawn()
	reset_level()


func spawn_item_synced(file_path, pos) -> Item:
	if not multiplayer.is_server(): return null
	
	#add_item_to_spawner.rpc(file_path)  # all item paths are loaded and added in _ready
	var item = load(file_path).instantiate() as Item
	ship.add_child(item, true)
	item.global_position = pos
	return item


@rpc("call_local", "any_peer")
func add_item_to_spawner(file_path : String):
	if not tracked_spawnable_items.has(file_path):
		tracked_spawnable_items.append(file_path)
		item_spawner.add_spawnable_scene(file_path)


func generate_level():
	#if not is_multiplayer_authority(): return
	print("generating level")
	ship.movement_clone.velocity = Vector3.ZERO
	ship.movement_clone.position = Vector3.ZERO
	
	start_station = friendly_station.instantiate() as POIStation
	start_station.level_manager = self
	add_child(start_station)
	start_station.position = Vector3(-20,-30,-300)
	#start_station.position = Util.random_point_in_sphere(400.0, 350.0)
	#start_station.global_rotation = Util.random_point_in_sphere(1.0)
	
	end_station = friendly_station.instantiate() as POIStation
	end_station.level_manager = self
	add_child(end_station)
	end_station.position = Util.random_point_in_sphere(level_size * 0.5, level_size * 0.6, r)
	end_station.global_rotation = Util.random_point_in_sphere(1.0, 0.0, r)
	
	#await get_tree().process_frame
	if is_multiplayer_authority():
		mission_manager.generate_missions()
	
	for poi in POIs:
		for n in range(r.randi_range(poi.level_amount_range.x, poi.level_amount_range.y)):
			var p = poi.scene.instantiate() as POI
			add_child(p)
			p.global_position = Util.random_point_in_sphere(level_size, 400.0, r)
			p.global_rotation = Util.random_point_in_sphere(1.0, 0.0, r)
			p.level_manager = self
			p.generate(r, r.randf_range(poi.size_multiplier_range.x, poi.size_multiplier_range.y))


func generate_for_new_connection(peer_id : int):
	if multiplayer.is_server() or true:
		generate_from_seed.rpc_id(peer_id, level_gen_seed)


@rpc("any_peer", "call_local")
func generate_from_seed(s : int):
	r = RandomNumberGenerator.new()
	r.seed = s
	seed(s)
	level_gen_seed = s
	generate_level()


func enter_POI(poi : POI):
	print("receiving poi dock")
	if poi == end_station:
		print("LEVEL COMPLETE. RELOADING\n")
		reset_level.rpc()


@rpc("any_peer", "call_local")
func reset_level():
	for child in get_children():
		child.queue_free()
	
	if is_multiplayer_authority():
		generate_from_seed.rpc(randi())
