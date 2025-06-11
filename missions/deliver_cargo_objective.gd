extends MissionObjective
class_name DeliverCargoObjective

var cargo : Array[Item]
var destination : CargoGrid


func setup(_mission : Mission):
	destination.item_added.connect(check_completed)


func check_completed() -> bool:
	print("checking completed")
	for cargo_item in cargo:
		if not destination.stored_items.has(cargo_item):
			return false
	complete()
	return true
