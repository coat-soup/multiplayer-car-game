extends Resource
class_name Mission

signal on_completed

@export var title : String
@export var reward : int

@export var difficulty : int

@export var objectives : Array[MissionObjective]

var completed : bool = false


func generate_mission(_world : Node3D, _main_pos : Vector3):
	pass


func check_completed() -> bool:
	for objective in objectives:
		if not objective.completed:
			return false
	complete()
	return true


func complete():
	completed = true
	on_completed.emit()
