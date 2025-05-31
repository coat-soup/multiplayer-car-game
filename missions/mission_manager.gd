extends Node
class_name MissionManager

@export var ship : ShipManager
@export var mission_template : Mission
@export var current_mission : Mission
@export var ui : UIManager
@export var level_manager : LevelManager


func generate_missions():
	current_mission = mission_template.duplicate()
	current_mission.generate_mission(level_manager, Util.random_point_in_sphere(50.0))
	current_mission.on_completed.connect(on_mission_completed.bind(current_mission))
	ui.display_mission(current_mission)


func on_mission_completed(mission : Mission):
	ui.display_mission_completed(mission)
