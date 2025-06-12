class_name Util

## Turns a list layer indices into corresponding layermask
## Eg. layer_mask([1,3]) returns 5 (101 in binary)
static func layer_mask(layers: Array) -> int:
	var mask := 0
	for layer in layers:
		mask |= (1 << (layer - 1))
	return mask

## Checks if mask contains layer
static func layer_in_mask(mask: int, layer: int) -> bool:
	return (mask & (1 << (layer - 1))) != 0


# COLLISION LAYER REPRESENTATIONS:
# 1 default
# 2 player (player should only ever have this)
# 3 interactable
# 4 vehicle component
# 5 vehicle physics body (should only interact with default)
# 6 fine vehicle collision (walls, floor, cannon, etc)
# 7 ship item physics dupe layer (both ship dupe and item dupe should have only this layer)

static func get_player_from_id(id: String, source : Node) -> Player:
	for player in source.get_tree().get_nodes_in_group("player"):
		if player.name == id:
			return player as Player
	return null


static func explode_at_point(position: Vector3, damage: float, radius: float, particles: PackedScene, parent: Node, source_id : int):
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
				health.take_damage.rpc(damage, source_id)
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


static func random_point_in_sphere(radius : float, min_radius : float = 0.0) -> Vector3:
	return (Vector3.UP * randf_range(min_radius, radius)).rotated(Vector3.RIGHT, randf_range(0, 2*PI)).rotated(Vector3.FORWARD, randf_range(0, 2*PI))


static func get_scenes_in_folder(folder_path: String) -> Array[String]:
	var scenes: Array[String] = []
	var dir := DirAccess.open(folder_path)
	
	if dir:
		dir.list_dir_begin()
		while true:
			var file_name = dir.get_next()
			if file_name == "": break
			if not dir.current_is_dir() and file_name.ends_with(".tscn"):
				var full_path = folder_path.path_join(file_name)
				scenes.append(full_path)
		dir.list_dir_end()
	else:
		push_error("Failed to open directory: %s" % folder_path)

	return scenes
