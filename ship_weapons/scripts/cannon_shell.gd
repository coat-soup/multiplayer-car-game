extends Node3D
class_name CannonShell

signal impacted

@export var damage := 30
@export var radius := 0 ## 0 for direct impact, >0 for explosion

@export var speed := 10.0
@export var lifetime := 10.0

@export var particles : PackedScene

@export var shapecast : ShapeCast3D

var layer_mask := [1,2,4,6]
var ignore_list : Array[Node3D] = [self]

var velocity := Vector3.ZERO

var hit_obj : Node3D

var active = true
var do_move := false

var fired_from_auth := false

var ui : UIManager
var source : int


func _ready():
	velocity = transform.basis.z * speed
	await get_tree().create_timer(lifetime).timeout
	shapecast.collision_mask = Util.layer_mask(layer_mask)
	shapecast.target_position = Vector3(0,0, speed * 2 * get_physics_process_delta_time())
	handle_impact()


func _physics_process(delta: float) -> void:
	if active:
		shapecast.force_shapecast_update()
		if shapecast.is_colliding():
			for i in range(shapecast.get_collision_count()):
				if not ignore_list.has(shapecast.get_collider(i)):
					global_position = shapecast.get_collision_point(i)
					hit_obj = shapecast.get_collider(i)
					handle_impact()#.rpc()
					break
		elif do_move:
			global_position += velocity * delta
		else: do_move = true # just to skip first movement frame


@rpc("any_peer", "call_local")
func handle_impact():
	if not active:
		return
	active = false
	
	$ExplosionAudio.pitch_scale = randf_range(0.9, 1.1)
	$ExplosionAudio.play()

	if is_multiplayer_authority():
		impacted.emit()
		if radius > 0:
			Util.explode_at_point(global_position, damage, radius, particles, get_tree().get_root(), source)
		elif hit_obj != null:
			Util.spawn_particles_for_time(global_position, particles, get_tree().get_root(), 1.0)
			var health = hit_obj.get_node_or_null("Health") as Health
			
			var player = hit_obj as PlayerMovement
			if player: health = player.player_manager.health
			
			if health:
				health.take_damage.rpc(damage, source)
	else:
		Util.spawn_particles_for_time(global_position, particles, get_tree().get_root(), 1.0)
	
	# delay for rpc connection bc not using spawnsync
	visible = false
	await get_tree().create_timer(5.0).timeout
	queue_free()
