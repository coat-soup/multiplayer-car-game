extends Node3D

signal impacted

@export var damage := 30
@export var radius := 0 ## 0 for direct impact, >0 for explosion

@export var speed := 10.0
@export var drop_rate := 1.0

@export var particles : PackedScene

var velocity := Vector3.ZERO

var hit_obj : Node3D

var active = true


func _ready():
	velocity = transform.basis.z * speed


func _physics_process(delta: float) -> void:
	position += velocity * delta
	velocity.y -= drop_rate * delta
	look_at(global_position - velocity)
	
	if not active:
		return
	
	var space_state = get_world_3d().direct_space_state

	var end = global_position + velocity * delta
	var query = PhysicsRayQueryParameters3D.create(global_position, end, Util.layer_mask([1,2]))
	query.exclude = [self]

	var result := space_state.intersect_ray(query)
	
	if result:
		global_position = result.position
		hit_obj = result.collider
		handle_impact.rpc()


@rpc("any_peer", "call_local")
func handle_impact():
	if not active:
		return
	active = false
	
	if is_multiplayer_authority():
		impacted.emit()
		if radius > 0:
			Util.explode_at_point(global_position, damage, radius, particles, get_tree().get_root())
		elif hit_obj != null:
			pass
			# do damage to direct hit
	else:
		Util.spawn_particles_for_time(global_position, particles, get_tree().get_root(), 1.0)
	
	# delay for rpc connection bc not using spawnsync
	await get_tree().create_timer(1.0).timeout
	queue_free()
