extends MissionObjective
class_name DestroyComponentsObjective

var components_to_destroy : Array[ShipComponent]


func setup(_mission : Mission):
	for component in components_to_destroy:
		component.broken.connect(check_completed)


func check_completed() -> bool:
	print("checking completed")
	for component in components_to_destroy:
		if not component.is_broken:
			return false
	complete()
	return true
