extends Node
class_name MissionManager

@export var ship : ShipManager
@export var current_mission : Mission
@onready var ui : UIManager = get_tree().get_first_node_in_group("ui") as UIManager


func _ready():
	await get_tree().create_timer(0.1).timeout
	current_mission.generate_mission(get_parent(), Util.random_point_in_sphere(50.0))
	current_mission.on_completed.connect(on_mission_completed.bind(current_mission))
	ui.display_mission(current_mission)


func on_mission_completed(mission : Mission):
	ui.display_mission_completed(mission)
