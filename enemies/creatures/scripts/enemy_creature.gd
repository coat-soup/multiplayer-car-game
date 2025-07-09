extends CharacterBody3D
class_name EnemyCreature

@export var speed : float = 30.0
@export var turn_speed : float = 2.0

@export var damage : int = 30
@export var attack_cooldown : float = 5.0

@export var health : Health

@export var target : Node3D

var dead := false
var time_to_attack : float = 0.0

@onready var attack_hitbox: Area3D = $AttackHitbox


func _ready() -> void:
	health.died.connect(on_died)
	attack_hitbox.body_entered.connect(on_body_entered_attack)


func _process(delta: float) -> void:
	if time_to_attack > 0.0:
		time_to_attack -= delta
	
	#print(time_to_attack)
	
	if target and not dead:
		var t_dir = (target.global_position - global_position).normalized()
		#rotation -= Vector3(t_dir.signed_angle_to(global_basis.z, global_basis.x), t_dir.signed_angle_to(global_basis.z, global_basis.y), 0) * delta * turn_speed
		
		if time_to_attack > 0.0:
			t_dir = t_dir.rotated(global_basis.x, -PI/2)
		
		var rotation_axis = global_basis.z.cross(t_dir)
		if rotation_axis.length() > 0.001:
			rotation_axis = rotation_axis.normalized()
			var angle_diff = acos(clamp(global_basis.z.dot(t_dir), -1.0, 1.0))
			var rotation_amount = min(angle_diff, turn_speed * delta)
			rotate(rotation_axis, rotation_amount)
		
		velocity = velocity.move_toward(global_basis.z * speed * (0.0 if time_to_attack > attack_cooldown*0.9 else 1.0), delta * 40.0)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, delta * 10.0)
	move_and_slide()


func on_body_entered_attack(body : Node3D):
	if time_to_attack > 0.0: return
	
	var _health_comp = body.get_node_or_null("Health")
	var ship = body as ShipMovementClone
	if ship:
		ship.ship_manager.movement_manager.add_impact_impulse.rpc(global_basis.z * 8000)
		ship.ship_manager.component_manager.take_damage_at_point(damage, global_position, -1)
		time_to_attack = attack_cooldown


func on_died():
	dead = true


func do_funny_legacy_rotation(delta):
	if target:
		rotation += (global_basis.z - (target.global_position - global_position).normalized()) * turn_speed * delta
