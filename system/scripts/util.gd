class_name Util

## Turns a list layer indices into corresponding layermask
## Eg. layer_mask([1,3]) returns 5 (101 in binary)
static func layer_mask(layers: Array) -> int:
	var mask := 0
	for layer in layers:
		mask |= (1 << (layer - 1))
	return mask

# COLLISION LAYER REPRESENTATIONS:
# 1 default
# 2 player (player should only ever have this)
# 3 interactable
# 4 vehicle component
# 5 vehicle physics body (should only interact with default)
# 6 fine vehicle collision (walls, floor, cannon, etc)


static func get_player_from_id(id: String, source : Node) -> Node3D:
	for player in source.get_tree().get_nodes_in_group("player"):
		if player.name == id:
			return player
	return null


static func explode_at_point(position: Vector3, damage: float, radius: float, particles: PackedScene, parent: Node, ui : UIManager):
	var space_state = parent.get_world_3d().direct_space_state
	
	var collision_shape = PhysicsShapeQueryParameters3D.new()
	collision_shape.shape = SphereShape3D.new()
	collision_shape.shape.radius = radius
	collision_shape.transform.origin = position
	collision_shape.collision_mask = layer_mask([1,2,4,5,6])
	
	var results = space_state.intersect_shape(collision_shape)
	
	var damaged : Array[Node3D] = []
	
	for result in results:
		var collider = result.collider
		if !damaged.has(collider):
			print(collider.name)
			var health = collider.get_node_or_null("Health") as Health
			if health:
				health.take_damage.rpc(damage, "")
				ui.flash_hitmarker()
		damaged.append(collider)
		
		var player = collider as Player
		if player:
			player.movement_manager.add_velocity_impulse.rpc(30 * (player.global_position - position).normalized())
			print("Hit player " + player.name)
		
		var v := collider as VehicleController
		if v:
			v.apply_impulse_rpc.rpc_id(v.get_multiplayer_authority(), (15 * (v.global_position - position).normalized()), position)
	
	
	spawn_particles_for_time(position, particles, parent, 1.0)


static func spawn_particles_for_time(position: Vector3, particles: PackedScene, parent: Node, time: float):
	var particles_obj = particles.instantiate()
	particles_obj.position = position
	parent.add_child(particles_obj)
	await particles_obj.get_tree().create_timer(time).timeout
	#particles_obj.queue_free()


static func get_gravitational_acceleration(pos : Vector3, planet : Planet) -> Vector3:
	const G = 10.0
	var direction = planet.position - pos
	var force = G * planet.mass / (direction.length() ** 2)
	return direction.normalized() * force
