extends Node3D
class_name CargoGrid

@export var dimensions : Vector3i = Vector3i.ONE

# actual items (1 dimension)
var stored_items : Array[Item]
var remote_transforms : Array[RemoteTransform3D]
# 3D array of bools (is occupied)
@export var grid : Array = []

@onready var area: Area3D = $Area3D


func _ready() -> void:
	grid = []
	for x in range(dimensions.x):
		grid.append([])
		for y in range(dimensions.y):
			grid[x].append([])
			for z in range(dimensions.z):
				grid[x][y].append(false)
	
	$Base.scale = Vector3(dimensions.x, 1, dimensions.z)
	$Base.position = Vector3(dimensions.x - 1, -1, dimensions.z - 1)/2.0
	area.scale = dimensions
	area.position = Vector3(dimensions.x - 1, dimensions.y - 1.0, dimensions.z - 1)/2.0
	
	area.body_entered.connect(on_body_entered)
	area.body_exited.connect(on_body_exited)


func _process(delta: float) -> void:
	var n_free = 0
	for x in range(0, dimensions.x):
		for y in range(0, dimensions.y):
			for z in range(0, dimensions.z):
				if grid[x][y][z] == false: n_free += 1
	#print(n_free, " spaces free")

func on_body_entered(body):
	body = body as Item
	if body and check_item_accepted(body):
		body.cargo_grid = self
		print("setting grid")


func on_body_exited(body):
	body = body as Item
	if body and body.cargo_grid == self:
		body.cargo_grid = null


func check_item_accepted(item : Item) -> bool:
	return item.cargo_grid_dimensions.x > 0 and item.cargo_grid_dimensions.y > 0 and item.cargo_grid_dimensions.z > 0


func get_snapped_world_position(item : Item) -> Vector3:
	var even_offset := Vector3(0.5,0.5,0.5) * Vector3(1 - item.cargo_grid_dimensions.x % 2, 1 - item.cargo_grid_dimensions.y % 2, 1 - item.cargo_grid_dimensions.z % 2)
	var local_pos = to_local(item.global_position)
	return to_global(local_pos.round() - even_offset)


static func get_snapped_rotation(item : Item) -> Vector3:
	const rad_90 : float = PI/2.0
	var rot := Vector3(
		round(item.rotation.x / rad_90) * rad_90,
		round(item.rotation.y / rad_90) * rad_90,
		round(item.rotation.z / rad_90) * rad_90
	)
	return rot


func get_item_corner_cell(item: Item, other_corner := false):
	var global_pos = item.snap_indicator.to_global(((item.cargo_grid_dimensions - Vector3i.ONE)/2.0) * (-1.0 if other_corner else 1.0))
	return to_local(global_pos).round()


func can_put_item_there(item : Item) -> bool:
	var a = get_item_corner_cell(item)
	var b = get_item_corner_cell(item, true)
	
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
	
	#var rt_id = remote_transforms.find(item.controlling_RT)
	#item.controlling_RT.remote_path = ""
	#remote_transforms[rt_id] = null
	#item.controlling_RT.queue_free()
	#item.controlling_RT = null
	
	#var id = stored_items.find(item)
	
	#if id == -1: return
	
	for x in range(min(a.x, b.x), max(a.x,b.x) + 1):
		for y in range(min(a.y, b.y), max(a.y,b.y) + 1):
			for z in range(min(a.z, b.z), max(a.z,b.z) + 1):
				grid[x][y][z] = false
	
	#stored_items[id] = null


func try_place_item(item : Item):
	if can_put_item_there(item):
		place_item.rpc(get_item_corner_cell(item), get_item_corner_cell(item, true), item.get_path())


@rpc("any_peer", "call_local")
func place_item(a, b, item_path : String):
	var item = get_tree().root.get_node(item_path) as Item
	
	item.cargo_spot_a = a
	item.cargo_spot_b = b
	
	#var rt_id = insert_into_null_or_append(remote_transforms, RemoteTransform3D.new())
	#item.controlling_RT = remote_transforms[rt_id]
	#print(rt_id, item.controlling_RT)
	#item.controlling_RT.remote_path = item_path
	#add_child(item.controlling_RT)
	#item.controlling_RT.global_position = item.global_position
	#item.controlling_RT.global_rotation = item.global_rotation
	
	print("placing ", a, " to ", b)
	
	var id = insert_into_null_or_append(stored_items, item)
	
	for x in range(min(a.x, b.x), max(a.x,b.x) + 1):
		for y in range(min(a.y, b.y), max(a.y,b.y) + 1):
			for z in range(min(a.z, b.z), max(a.z,b.z) + 1):
				grid[x][y][z] = true
	
	
	item.held_in_place = true
		
	item.global_position = get_snapped_world_position(item)
	item.physics_dupe.position = item.position
	item.global_rotation = get_snapped_rotation(item)
	item.physics_dupe.rotation = item.rotation
	
	item.snap_indicator.visible = false
		
	await get_tree().create_timer(0.1) # so rigidbody updates before freezing
	item.physics_dupe.freeze = true


func insert_into_null_or_append(array : Array, value : Variant) -> int:
	for i in range(len(array)):
		if array[i] == null:
			array[i] = value
			return i
	array.append(value)
	return len(array) - 1
