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
var ignore_list : Array[RID] = [self]

var velocity := Vector3.ZERO

var hit_obj : Node3D

var active = true

var fired_from_auth := false

var ui : UIManager
var source : int


func _ready():
	velocity = transform.basis.z * speed
	await get_tree().create_timer(lifetime).timeout
	handle_impact()


func _physics_process(delta: float) -> void:
	if active:
		var space_state = get_world_3d().direct_space_state

		var end = global_position + velocity * delta
		var query = PhysicsRayQueryParameters3D.create(global_position, end, Util.layer_mask(layer_mask))
		
		query.exclude = ignore_list
		
		shapecast.target_position = Vector3(0,0, velocity.length() * delta)
		
		var result := space_state.intersect_ray(query)
		
		if shapecast.is_colliding(): #result:
			global_position = shapecast.get_collision_point(0) #result.position
			hit_obj = shapecast.get_collider(0) #result.collider
			handle_impact()#.rpc()
	
	global_position += velocity * delta
	#velocity.y -= drop_rate * delta
	#look_at(global_position - velocity)


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
			if health:
				health.take_damage.rpc(damage, source)
	else:
		Util.spawn_particles_for_time(global_position, particles, get_tree().get_root(), 1.0)
	
	# delay for rpc connection bc not using spawnsync
	visible = false
	await get_tree().create_timer(5.0).timeout
	queue_free()
