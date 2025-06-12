extends Resource
class_name WorldState

var loose_items : Array[ItemState]
var cargo_grids : Array[CargoGridState]


static func get_world_state(root : Node3D) -> WorldState:
	var state = WorldState.new()
	
	for item in root.get_tree().get_nodes_in_group("item"):
		item = item as Item
		if not (item.cargo_grid and item.held_in_place):
			state.loose_items.append(ItemState.new(item.scene_file_path, item.global_position, item.on_ship != null))
	
	for cargo_grid in root.get_tree().get_nodes_in_group("cargo grid"):
		cargo_grid = cargo_grid as CargoGrid
		var cg_state = CargoGridState.new()
		
		cg_state.path_to_self = cargo_grid.get_path()
		
		for item in cargo_grid.stored_items:
			cg_state.items.append(ItemState.new(item.item_data.prefab.resource_path, Vector3.ZERO, false))
			cg_state.item_positions.append([item.cargo_spot_a, item.cargo_spot_b])
			cg_state.item_rotations.append([item.global_rotation - cargo_grid.global_rotation])
		
		state.cargo_grids.append(cg_state)
	
	return state
