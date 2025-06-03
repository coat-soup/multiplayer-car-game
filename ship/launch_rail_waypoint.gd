extends Node3D
class_name LaunchRailWaypoint

@export var connections : Array[LaunchRailWaypoint]
@export var elevator_level := 0
@export var tolerance = 0.05

@export var on_elevator : Elevator
@export var elevator_path : NodePath


func _ready() -> void:
	on_elevator = get_node_or_null(elevator_path) as Elevator
	if on_elevator:
		on_elevator.reached_floor.connect(update_floor)
		reparent.call_deferred(on_elevator.platform)

func reached(cur_pos : Vector3) -> bool:
	return cur_pos.distance_to(global_position) < 0.01


func find_path_to_waypoint(waypoint: LaunchRailWaypoint, path: Array[LaunchRailWaypoint] = []) -> Array[LaunchRailWaypoint]:
	if self in path:
		return []
	
	path.append(self)
	
	if self == waypoint:
		return path.duplicate()
	
	for connection in connections:
		var new_path = connection.find_path_to_waypoint(waypoint, path.duplicate())
		if new_path.size() > 0:
			return new_path
	
	return []


func update_floor(floor_id):
	elevator_level = floor_id
