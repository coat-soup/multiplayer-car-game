extends Node3D
class_name CargoGrid

signal item_added
signal item_removed

@export var dimensions : Vector3i = Vector3i.ONE

# actual items (1 dimension)
var stored_items : Array[Item]
var remote_transforms : Array[RemoteTransform3D]
# 3D array of bools (is occupied)
@export var grid : Array = []

@onready var area: Area3D = $Area3D

@export var snapped_rotation_offset := Vector3.ZERO

const CARGO_GRID_TILE_MODEL = preload("res://world/props/models/cargo_grid_tile_model.tscn")

var transform_helper : Node3D


func _ready() -> void:
	transform_helper = Node3D.new()
	add_child(transform_helper)
	
	grid = []
	for x in range(dimensions.x):
		grid.append([])
		for y in range(dimensions.y):
			grid[x].append([])
			for z in range(dimensions.z):
				grid[x][y].append(false)
	
	for x in range(dimensions.x):
		for z in range(dimensions.z):
			var tile = CARGO_GRID_TILE_MODEL.instantiate()
			add_child(tile)
			tile.position = Vector3(x,-0.5,z)
	
	#$Base.scale = Vector3(dimensions.x, 1, dimensions.z)
	#$Base.position = Vector3(dimensions.x - 1, -1, dimensions.z - 1)/2.0
	area.scale = dimensions
	area.position = Vector3(dimensions.x - 1, dimensions.y - 1.0, dimensions.z - 1)/2.0
	
	area.body_entered.connect(on_body_entered)
	area.body_exited.connect(on_body_exited)


func on_body_entered(body):
	body = body as Item
	if body and check_item_accepted(body):
		body.cargo_grid = self


func on_body_exited(body):
	body = body as Item
	if body and body.cargo_grid == self:
		body.cargo_grid = null


func check_item_accepted(item : Item) -> bool:
	return item.cargo_grid_dimensions.x > 0 and item.cargo_grid_dimensions.y > 0 and item.cargo_grid_dimensions.z > 0


func get_snapped_world_position(item : Item) -> Vector3:
	return to_global(((get_item_corner_cell(item) + get_item_corner_cell(item, true)) / 2.0))


func get_snapped_world_rotation(item: Item, actually_make_it_local := false) -> Vector3:
	const rad_90 := PI / 2.0

	# Step 1: Convert item's global rotation to the grid's local rotation space
	var item_local_rot = (global_basis.inverse() * item.global_basis).get_euler()

	# Step 2: Snap the local rotation to the grid's local 90° angles
	var snapped_local_rot = Vector3(
		round(item_local_rot.x / rad_90) * rad_90,
		round(item_local_rot.y / rad_90) * rad_90,
		round(item_local_rot.z / rad_90) * rad_90
	)

	# Step 3: Convert the snapped local rotation back to world space
	var snapped_local_basis = Basis.from_euler(snapped_local_rot)
	var snapped_world_basis = global_basis * snapped_local_basis

	# Step 4: Return the final snapped world rotation (Euler angles)
	return snapped_world_basis.get_euler() if not actually_make_it_local else snapped_local_basis.get_euler()


func get_item_corner_cell(item: Item, other_corner := false):
	transform_helper.global_position = item.global_position
	transform_helper.global_rotation = get_snapped_world_rotation(item)
	var global_pos = transform_helper.to_global(((item.cargo_grid_dimensions - Vector3i.ONE)/2.0) * (-1.0 if other_corner else 1.0))
	return to_local(global_pos).round()


func can_put_item_there(item : Item) -> bool:
	return is_area_free(get_item_corner_cell(item), get_item_corner_cell(item, true))


func is_area_free(a : Vector3i, b : Vector3i) -> bool:
	
	#print("checking ", a, " to ", b)
	
	if a.x < 0 or a.y < 0 or a.z < 0 or a.x >= dimensions.x or a.y >= dimensions.y or a.z >= dimensions.z: return false # no out of bounds
	if b.x < 0 or b.y < 0 or b.z < 0 or b.x >= dimensions.x or b.y >= dimensions.y or b.z >= dimensions.z: return false
	
	for x in range(min(a.x, b.x), max(a.x,b.x) + 1):
		for y in range(min(a.y, b.y), max(a.y,b.y) + 1):
			for z in range(min(a.z, b.z), max(a.z,b.z) + 1):
				if grid[x][y][z] == true: return false # no clipping
				if y > 0 and y == min(a.y, b.y) and grid[x][y-1][z] == false: return false # no floating
	return true


#@rpc("any_peer", "call_local")
func remove_item(item : Item):
	var a = item.cargo_spot_a
	var b = item.cargo_spot_b
	
	print("removing ", a, " to ", b)
	
	var rt_id = remote_transforms.find(item.controlling_RT)
	if item.controlling_RT:
		item.controlling_RT.remote_path = ""
		remote_transforms[rt_id] = null
		item.controlling_RT.queue_free()
		item.controlling_RT = null
	
	if item.on_ship:
		item.physics_dupe.position = item.position
		item.physics_dupe.rotation = item.rotation
	else:
		item.physics_dupe.global_position = item.global_position
		item.physics_dupe.global_rotation = item.global_rotation
	
	var id = stored_items.find(item)
	
	if id == -1:
		print(self, " couldn't remove item ", item, " - not found.")
		return
	
	for x in range(min(a.x, b.x), max(a.x,b.x) + 1):
		for y in range(min(a.y, b.y), max(a.y,b.y) + 1):
			for z in range(min(a.z, b.z), max(a.z,b.z) + 1):
				grid[x][y][z] = false
	
	stored_items[id] = null
	item_removed.emit()


func try_place_item(item : Item):
	if can_put_item_there(item):
		place_item.rpc(get_item_corner_cell(item), get_item_corner_cell(item, true), item.get_path())


@rpc("any_peer", "call_local")
func place_item(a, b, item_path : String):
	var item = get_tree().root.get_node(item_path) as Item
	
	if !item.physics_dupe.is_inside_tree():
		await item.physics_dupe.tree_entered
	
	item.cargo_spot_a = a
	item.cargo_spot_b = b
	
	print("placing ", a, " to ", b)
	
	insert_into_null_or_append(stored_items, item)
	
	for x in range(min(a.x, b.x), max(a.x,b.x) + 1):
		for y in range(min(a.y, b.y), max(a.y,b.y) + 1):
			for z in range(min(a.z, b.z), max(a.z,b.z) + 1):
				grid[x][y][z] = true
	
	item.held_in_place = true
	
	# item placement
	item.global_position = get_snapped_world_position(item)
	item.global_rotation = get_snapped_world_rotation(item)
	if item.on_ship:
		item.physics_dupe.position = item.position
		item.physics_dupe.rotation = item.rotation
	else:
		item.physics_dupe.global_position = item.global_position
		item.physics_dupe.global_rotation = item.global_rotation
	
	# remote transform
	var rt_id = insert_into_null_or_append(remote_transforms, RemoteTransform3D.new())
	item.controlling_RT = remote_transforms[rt_id]
	item.controlling_RT.remote_path = item_path
	add_child(item.controlling_RT)
	item.controlling_RT.global_position = item.global_position
	item.controlling_RT.global_rotation = item.global_rotation
	
	item.snap_indicator.visible = false
	
	await get_tree().create_timer(0.1).timeout # so rigidbody updates before freezing
	item.physics_dupe.freeze = true
	
	item_added.emit()


func insert_into_null_or_append(array : Array, value : Variant) -> int:
	for i in range(len(array)):
		if array[i] == null:
			array[i] = value
			return i
	array.append(value)
	return len(array) - 1


# very unorganised/inefficient, just used for basic spawning
func stupid_find_first_slot_for_item(item : Item) -> Array[Vector3i]:
	var corner_offset = item.cargo_grid_dimensions - Vector3i.ONE
	
	for x in range(0, dimensions.x):
		for y in range(0, dimensions.y):
			for z in range(0, dimensions.z):
				var c_pos = Vector3i(x,y,z)
				if is_area_free(c_pos, c_pos + corner_offset):
					return [c_pos,c_pos + corner_offset]
	return []


func place_item_crude_at_points_crude(item : Item, a, b, local_rotation := Vector3.ZERO):
	if !item.physics_dupe.is_inside_tree():
		await item.physics_dupe.tree_entered
	
	item.global_position = (to_global(a) + to_global(b)) / 2.0
	item.global_rotation = global_rotation + local_rotation
	var rot = get_snapped_world_rotation(item)
	item.global_rotation = rot
	
	item.physics_dupe.global_position = (to_global(a) + to_global(b)) / 2.0
	item.physics_dupe.global_rotation = rot
	
	place_item(a, b, item.get_path())
