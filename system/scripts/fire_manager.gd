extends Area3D
class_name FireManager

@export var dimensions : Vector3i = Vector3i(10,10,10)
@export var cell_size : float = 2.0

@export var dps : float = 15.0
@export var damage_interval : float = 0.3

var fires = {}

var tick_interval : float = 4.0

const FIRE_PREFAB = preload("res://system/scenes/fire.tscn")

var players : Array[Player]


func _ready() -> void:
	body_entered.connect(body_entered_damage)
	body_exited.connect(body_exited_damage)
	
	damage_tick()
	
	if not is_multiplayer_authority():
		multiplayer.connected_to_server.connect(on_connected)


func on_connected():
	for fire in fires:
		fires.put_out() # DONT RPC
	request_initialise_on_load().rpc(1)


@rpc("any_peer", "call_local")
func request_initialise_on_load():
	if not multiplayer.is_server(): return
	for pos in fires.keys():
		(get_parent() as ShipManager).movement_manager.ui.display_chat_message("Sending " + str(pos) + " fire to " + str(get_tree().get_rpc_sender_id()))
		try_spawn_fire.rpc_id(get_tree().get_rpc_sender_id(), pos)


func body_entered_damage(body):
	var player = body as PlayerMovement
	if player:
		players.append(player.player_manager)


func body_exited_damage(body):
	var id = -1
	var player = body as PlayerMovement
	if player:
		id = players.find(player.player_manager)
	
	if id != -1: players.remove_at(id)


func damage_tick():
	if not is_multiplayer_authority(): return
	
	for player in players:
		var pos : Vector3i
		pos = world_to_grid_pos(player.movement_manager.global_position - player.movement_manager.global_basis.y)
		
		if fires.get(pos) != null:
			player.health.take_damage.rpc(dps * damage_interval)
	
	
	await get_tree().create_timer(damage_interval).timeout
	damage_tick()


@rpc("any_peer", "call_local")
func try_spawn_fire(pos : Vector3i):
	var ray_start = to_global(pos * cell_size)
	
	var query = PhysicsRayQueryParameters3D.create(ray_start + global_basis.y * cell_size/2, ray_start - global_basis.y * cell_size, Util.layer_mask([1]))
	
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result:
		var actual_pos = world_to_grid_pos(result.position)
		if fires.get(actual_pos) != null:
			return
		
		var new_fire = FIRE_PREFAB.instantiate() as Fire
		new_fire.fire_manager = self
		add_child(new_fire)
		new_fire.global_position = result.position
		new_fire.grid_pos = set_fire_manual(new_fire)
		
		for fire in get_adjacent_fires(pos.x, pos.y, pos.z):
			new_fire.add_adjacent(fire)
			fire.add_adjacent(new_fire)
		
		if pos != new_fire.grid_pos: # for elevation changes
			for fire in get_adjacent_fires(new_fire.grid_pos.x, new_fire.grid_pos.y, new_fire.grid_pos.z):
				new_fire.add_adjacent(fire)
				fire.add_adjacent(new_fire)


func set_fire_manual(fire : Fire) -> Vector3i:
	var grid_pos : Vector3i = (fire.position / cell_size).round()
	fires[grid_pos] = fire
	return grid_pos


func world_to_grid_pos(world_pos : Vector3) -> Vector3i:
	return (to_local(world_pos) / cell_size).round() as Vector3i


func get_adjacent_fires(x,y,z) -> Array[Fire]:
	var a_fires : Array[Fire] = []
	for p in [
	Vector3i(x-1, y,  z  ),
	Vector3i(x,   y,  z+1),
	Vector3i(x+1, y,  z  ),
	Vector3i(x,   y,  z-1)]:
		var fire = fires.get(p) as Fire
		if fire: a_fires.append(fire)
	
	return a_fires


func pick_random_adjacent_pos(x, y, z) -> Vector3i:
	return [
	Vector3i(x-1, y,  z  ),
	Vector3i(x,   y,  z+1),
	Vector3i(x+1, y,  z  ),
	Vector3i(x,   y,  z-1)].pick_random()


@rpc("any_peer", "call_local")
func try_extinguish_at_pos(pos : Vector3i, extinguish_val : float):
	if fires[pos]:
		fires[pos].add_extinguish(extinguish_val)
