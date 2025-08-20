extends Node3D
class_name EnemyManager

@export var max_local_difficulty := 3.0
## target_diff = sin wave loop of this length. Half the time difficulty is negative: means peace
@export var difficulty_wave_interval : float = 300.0

@onready var target_local_difficulty : float = -max_local_difficulty
var current_local_difficulty := 0.0

@export var spawnable_enemies : Array[EnemyCreatureData]

@export var check_spawn_interval : float = 10.0

var enemy_groups : Array[Vector2] 	# each entry represents (total_number_initially_spawned_in_group, remaining_difficulty).
									# eg a group of 3 needler's will start at (3, 1), and go to (3, 0.66) when one dies, etc
									# first value is just for this calc -> on_death: groups[id].y -= 1/groups[id].x

var spawned_enemies = {}

@export var level_manager : LevelManager
@export var multiplayer_spawner : MultiplayerSpawner

var time_start = 0


func _ready() -> void:
	time_start = Time.get_ticks_msec()
	
	spawnable_enemies.sort_custom(func(a, b): return a.difficulty_rating < b.difficulty_rating)
	
	for enemy in spawnable_enemies:
		multiplayer_spawner.add_spawnable_scene(enemy.scene_path)


func check_for_enemy_spawn():
	if not multiplayer.is_server(): return
	
	var time_elapsed = Time.get_ticks_msec() - time_start
	target_local_difficulty = max_local_difficulty * -sin((2 * PI * time_elapsed) / (difficulty_wave_interval * 1000)) # time in milisec
	
	cleanup_out_of_range_enemies()
	if update_current_local_difficulty() < target_local_difficulty:
		spawn_enemies()
	
	await get_tree().create_timer(check_spawn_interval).timeout
	check_for_enemy_spawn()


func spawn_enemies():
	var remaining_diff := target_local_difficulty
	while remaining_diff >= spawnable_enemies[0].difficulty_rating: # smallest rating bc we sorted it in ready
		var enemy_choice : EnemyCreatureData = null
		while not enemy_choice or enemy_choice.difficulty_rating > remaining_diff:
			enemy_choice = spawnable_enemies.pick_random()
		
		var group_id := get_available_group_id()
		
		var num_to_spawn = enemy_choice.group_size # maybe change with global difficulty later
		var spawn_location = level_manager.ship.movement_manager.global_position + Util.random_point_in_sphere(200.0, 150.0)
		for x in range(num_to_spawn):
			var enemy = load(enemy_choice.scene_path).instantiate() as EnemyCreature
			enemy.target = level_manager.ship
			add_child(enemy, true)
			enemy.global_position = spawn_location + Util.random_point_in_sphere(20.0)
			enemy.health.died.connect(enemy_died.bind(group_id, enemy))
			
			spawned_enemies[group_id].append(enemy)
		
		enemy_groups[group_id] = Vector2(num_to_spawn, enemy_choice.difficulty_rating)
		remaining_diff = target_local_difficulty - update_current_local_difficulty()


func enemy_died(group_id, enemy):
	enemy_groups[group_id].y = enemy_groups[group_id].y - 1.0/enemy_groups[group_id].x
	spawned_enemies[group_id].remove_at(spawned_enemies[group_id].find(enemy))
	if enemy_groups[group_id].y <= 0:
		enemy_groups[group_id].x = 0 # mark empty group (all enemies died)


func update_current_local_difficulty() -> float:
	var d = 0.0
	for group in enemy_groups:
		d += group.y
	current_local_difficulty = d
	return d


func get_available_group_id() -> int:
	for i in range(len(enemy_groups)):
		if enemy_groups[i].x == 0: return i
	
	enemy_groups.append(Vector2.ZERO)
	spawned_enemies[len(enemy_groups) - 1] = []
	return len(enemy_groups) - 1


func cleanup_out_of_range_enemies():
	if not multiplayer.is_server(): return
	
	for i in range(len(enemy_groups)):
		for enemy in spawned_enemies[i]:
			enemy = enemy as EnemyCreature
			if not enemy.target or enemy.global_position.distance_to(enemy.target.global_position) > 400.0:
				enemy.health.take_damage.rpc(69000000)
