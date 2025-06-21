extends Node3D
class_name Fire

signal extinguished

@export var spread_interval : float = 15.0

var adjacent_fires : Array[Fire]

const FIRE_PREFAB = preload("res://system/scenes/fire.tscn")

var damagables : Array[Health]

@export var manually_spawned = false
var fire_manager : FireManager
var grid_pos : Vector3i


func _ready() -> void:
	if manually_spawned: # must be parented to a fire manager
		await get_tree().process_frame
		fire_manager = get_parent() as FireManager
		if fire_manager: grid_pos = fire_manager.set_fire_manual(self)
	
	start_spread_tick()
	var p = Util.random_point_in_circle(0.3)
	$CSGBox3D.position = Vector3(p.x, 0, p.y)


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
	if len(adjacent_fires) >= 4: return
	
	await get_tree().create_timer(randf_range(0.0, spread_interval)).timeout
	spread_tick()


func spread_tick():
	if len(adjacent_fires) < 4:
		var p = fire_manager.pick_random_adjacent_pos(grid_pos.x, grid_pos.y, grid_pos.z)
		if fire_manager.fires.get(p) == null:
			fire_manager.try_spawn_fire(p)
	
	await get_tree().create_timer(spread_interval).timeout
	if len(adjacent_fires) < 4:
		spread_tick()


func put_out():
	queue_free()
