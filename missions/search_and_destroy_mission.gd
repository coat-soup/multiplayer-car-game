extends Mission
class_name SearchAndDestroyMission

@export var target_component : PackedScene
@export var num_to_spawn : int = 3
@export var spread : float = 10.0

func generate_mission(world : Node3D, main_pos : Vector3):
	if num_to_spawn == 0:
		print("not spawning satellites")
		return
	var objective := DestroyComponentsObjective.new()
	objective.on_completed.connect(check_completed)
	objectives.append(objective)
	for i in range(num_to_spawn):
		var target := target_component.instantiate() as ShipComponent
		objective.components_to_destroy.append(target)
		world.add_child(target)
		target.global_position = main_pos + Util.random_point_in_sphere(spread, spread * 0.6)
		target.global_rotation = Util.random_point_in_sphere(1.0)
	objective.description_text = "Destroy all " + str(num_to_spawn) + " " + str(objective.components_to_destroy[0].name) + " components"
	objective.setup(self)
