extends CharacterBody3D
class_name EnemyCreature

@export var speed : float = 30.0
@export var turn_speed : float = 2.0

@export var damage : int = 30
@export var attack_cooldown : float = 5.0

@export var health : Health

@export var player_target : Node3D
@export var target : Node3D

@export var player_check_interval : float = 5.0
@export var player_target_chance : float = 0.3

var dead := false
var time_to_attack : float = 0.0

@onready var attack_hitbox: Area3D = $AttackHitbox
@onready var player_detector: Area3D = $PlayerDetector


func _ready() -> void:
	health.died.connect(on_died)
	attack_hitbox.body_entered.connect(on_body_entered_attack)
	try_target_player()
	health.took_damage.connect(on_took_damage)


func _process(delta: float) -> void:
	if time_to_attack > 0.0:
		time_to_attack -= delta
	
	#print(time_to_attack)
	
	var t = target if not player_target else player_target
	
	if t and not dead:
		var t_dir = (t.global_position - global_position).normalized()
		#rotation -= Vector3(t_dir.signed_angle_to(global_basis.z, global_basis.x), t_dir.signed_angle_to(global_basis.z, global_basis.y), 0) * delta * turn_speed
		
		if time_to_attack > 0.0:
			t_dir = -t_dir #t_dir.rotated(global_basis.x, -PI/2)
		
		var rotation_axis = global_basis.z.cross(t_dir)
		var rotation_amount: float = 0
		if rotation_axis.length() > 0.001:
			var angle_diff = acos(clamp(global_basis.z.dot(t_dir), -1.0, 1.0))
			rotation_amount = min(angle_diff, turn_speed * delta)
		elif t_dir.dot(global_basis.z) < 0:
			rotation_axis = global_basis.x
			rotation_amount = turn_speed * delta
		
		if rotation_axis != Vector3.ZERO: rotate(rotation_axis.normalized(), rotation_amount)
		
		velocity = velocity.move_toward(global_basis.z * speed * (0.0 if time_to_attack > attack_cooldown*0.9 else 1.0), delta * 40.0)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, delta * 10.0)
	move_and_slide()


func on_body_entered_attack(body : Node3D):
	if not multiplayer.is_server(): return
	
	if time_to_attack > 0.0: return
	
	var _health_comp = body.get_node_or_null("Health")
	var ship = body as ShipMovementClone
	if ship:
		#ship.ship_manager.movement_manager.add_impact_impulse.rpc(global_basis.z * 8000)
		ship.ship_manager.component_manager.take_damage_at_point(damage, global_position, -1)
		time_to_attack = attack_cooldown
	
	var player = body as PlayerMovement
	if player:
		player.player_manager.health.take_damage.rpc(damage)
		player.add_velocity_impulse.rpc(global_basis.z.normalized() * damage)
		time_to_attack = attack_cooldown


func on_died():
	dead = true


func do_funny_legacy_rotation(delta):
	if target:
		rotation += (global_basis.z - (target.global_position - global_position).normalized()) * turn_speed * delta


func try_target_player():
	for body in player_detector.get_overlapping_bodies():
		body = body as PlayerMovement
		if body and not player_target:
			if body.player_manager.active and not body.on_ship and randf() < player_target_chance:
				player_target = body
				body.player_manager.health.died.connect(player_target_died)
	
	await get_tree().create_timer(player_check_interval).timeout
	try_target_player()


func player_target_died():
	(player_target as PlayerMovement).player_manager.health.died.disconnect(player_target_died)
	player_target = null


func on_took_damage(source_id):
	var player : Player = Util.get_player_from_id(str(source_id), self)
	if player and player.active and not player.movement_manager.on_ship:
		if player_target == null and randf() < player_target_chance: player_target = player.movement_manager
