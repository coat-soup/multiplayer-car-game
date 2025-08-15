class_name AABBHelper


static func get_2d_bounds_from_aabb(parent : Node3D, box : AABB, camera : Camera3D) -> Array[Vector2]:
	return get_2d_bounds_from_3d_bounds(parent, box.position, box.size, camera)


static func get_2d_bounds_from_3d_bounds(parent : Node3D, corner : Vector3, size : Vector3, camera : Camera3D) -> Array[Vector2]: # [screen_position, size]
	var verts : Array[Vector3] = [
	corner,
	Vector3(corner.x + size.x, corner.y, corner.z),
	Vector3(corner.x + size.x, corner.y, corner.z + size.z),
	Vector3(corner.x, corner.y, corner.z + size.z),

	Vector3(corner.x, corner.y + size.y, corner.z),
	Vector3(corner.x + size.x, corner.y + size.y, corner.z),
	Vector3(corner.x + size.x, corner.y + size.y, corner.z + size.z),
	Vector3(corner.x, corner.y + size.y, corner.z + size.z)
	]
	
	for i in range(len(verts)):
		verts[i] = parent.to_global(verts[i])
	
	var controlStart : Vector2 = Vector2(INF, INF)
	var controlEnd : Vector2 = Vector2(-INF, -INF)
	
	for i in range(len(verts)):
		var screenVert : Vector2 = camera.unproject_position(verts[i]);
	
		if (screenVert.x < controlStart.x):
			controlStart.x = screenVert.x
		if (screenVert.y < controlStart.y):
			controlStart.y = screenVert.y
	
		if (screenVert.x > controlEnd.x):
			controlEnd.x = screenVert.x
		if (screenVert.y > controlEnd.y):
			controlEnd.y = screenVert.y
	
	var position = controlStart;
	var control_size = controlEnd - controlStart;
	
	return [position, control_size]
