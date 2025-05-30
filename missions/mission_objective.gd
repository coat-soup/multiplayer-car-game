extends Resource
class_name MissionObjective

signal on_completed

@export var description_text : String

var completed : bool = false


func setup(mission : Mission):
	pass


func get_progress_text() -> String:
	return "Completed: " + str(completed)


func check_completed() -> bool:
	return completed


func complete():
	print("objective completed")
	completed = true
	on_completed.emit()
