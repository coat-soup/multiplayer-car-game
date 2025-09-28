extends Node3D
class_name NavalMine

@onready var homing_trigger: Area3D = $HomingTrigger
@onready var detonate_trigger: Area3D = $DetonateTrigger
@onready var health: Health = $Hitbox/Health

@export var damage : int = 80

var target : Node3D
var velocity : Vector3
var accel : float = 0.5


func _ready() -> void:
	homing_trigger.body_entered.connect(on_body_entered_homing)
	homing_trigger.body_exited.connect(on_body_exited_homing)
	detonate_trigger.body_entered.connect(on_body_entered_detonate)
	health.died.connect(detonate)


func on_body_entered_homing(body : Node3D):
	if body as ShipMovementClone:
		target = body


func on_body_exited_homing(body : Node3D):
	if body == target:
		target = null


func on_body_entered_detonate(body : Node3D):
	if multiplayer.is_server(): health.take_damage.rpc(health.cur_health * 100)


func _physics_process(delta: float) -> void:
	if target:
		velocity += (target.global_position - global_position).normalized() * accel
	else:
		velocity = velocity.move_toward(Vector3.ZERO, accel * delta)
	
	if velocity == Vector3.ZERO: return
	
	global_position += velocity * delta


func detonate():
	$RadarSignature.terminate()
	Util.explode_at_point(global_position, damage, 20,preload("res://vfx/particles/explosion_particles.tscn"), get_parent(), -1)
	await get_tree().process_frame
	queue_free()
