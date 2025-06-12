extends Mission
class_name CargoTransportMission

@export var cargo_items : Array[PackedScene]
@export var num_to_spawn : int = 3

func generate_mission(level_manager : LevelManager, _main_pos : Vector3):
	if num_to_spawn == 0:
		print("not spawning cargo (num set to 0)")
		return
	
	var objective := DeliverCargoObjective.new()
	objective.on_completed.connect(check_completed)
	objectives.append(objective)
	objective.destination = (level_manager.start_POI.get_node("TestCargoDestination") as StationCargoBay).cargo_grid
	
	var start_grid = (level_manager.start_POI.get_node("StationCargoBay") as StationCargoBay).cargo_grid
	
	for i in range(num_to_spawn):
		var item : Item = level_manager.spawn_item(cargo_items.pick_random(), start_grid.global_position + Vector3(-10,0,0))
		objective.cargo.append(item)
		
		var grid_pos = start_grid.stupid_find_first_slot_for_item(item)
		if grid_pos != []:
			start_grid.place_item_crude_at_points_crude(item, grid_pos[0], grid_pos[1])
			print("placing item")
		else:
			print("Couldn't find space for cargo mission item")
	
	objective.description_text = "Deliver all " + str(num_to_spawn) + " cargo items"
	objective.setup(self)
