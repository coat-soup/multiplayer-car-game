extends Node3D
class_name Fire

signal extinguished

@export var spread_interval : float = 25.0

var adjacent_fires : Array[Fire]

const FIRE_PREFAB = preload("res://system/scenes/fire.tscn")

var damagables : Array[Health]

@export var manually_spawned = false
var fire_manager : FireManager
var grid_pos : Vector3i

var extinguish_level : float = 0.0 # 1 = extinguished
var revive_rate : float = 0.1


func _ready() -> void:
	if manually_spawned: # must be parented to a fire manager
		await get_tree().process_frame
		fire_manager = get_parent() as FireManager
		if fire_manager: grid_pos = fire_manager.set_fire_manual(self)
	
	start_spread_tick()
	var p = Util.random_point_in_circle(0.3)
	$CSGBox3D.position = Vector3(p.x, 0, p.y)


func _process(delta: float) -> void:
	if extinguish_level > 0.0: extinguish_level -= revive_rate * delta


func add_adjacent(fire : Fire):
	adjacent_fires.append(fire)
	fire.extinguished.connect(start_spread_tick)


func body_entered_damage(body):
	var player = body as PlayerMovement
	if player:
		damagables.append(player.player_manager.health)
	else:
		var health = body.get_node_or_null("Health")
		if health: damagables.append(health)


func body_exited_damage(body):
	var id = -1
	var player = body as PlayerMovement
	if player:
		id = damagables.find(player.player_manager.health)
	else:
		var health = body.get_node_or_null("Health")
		if health: id = damagables.find(health)
	
	if id != -1: damagables.remove_at(id)


func start_spread_tick():
	if not is_multiplayer_authority(): return
	
	if len(adjacent_fires) >= 4: return
	
	await get_tree().create_timer(randf_range(spread_interval/2.0, spread_interval)).timeout
	spread_tick()


func spread_tick():
	if not is_multiplayer_authority(): return
	
	if len(adjacent_fires) < 4:
		var p = fire_manager.pick_random_adjacent_pos(grid_pos.x, grid_pos.y, grid_pos.z)
		if fire_manager.fires.get(p) == null:
			fire_manager.try_spawn_fire.rpc(p)
	
	await get_tree().create_timer(spread_interval).timeout
	if len(adjacent_fires) < 4:
		spread_tick()


#@rpc("any_peer", "call_local")
func add_extinguish(amount : float):
	extinguish_level += amount
	$GPUParticles3D.amount_ratio = 1 - extinguish_level
	if extinguish_level >= 1.0:
		put_out()#.rpc()


@rpc("any_peer", "call_local")
func put_out():
	fire_manager.fires.erase(grid_pos)
	extinguished.emit()
	await get_tree().create_timer(0.2).timeout
	queue_free()
