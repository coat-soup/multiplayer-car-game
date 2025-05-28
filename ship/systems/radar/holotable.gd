extends Node

@onready var marker_holder: Node3D = $MarkerHolder
const RADAR_MARKER = preload("res://ship/systems/radar/radar_marker.tscn")

@onready var trajectory_visualiser: TrajectorVisualiser = $MarkerHolder/TrajectoryVisualiser

var center_point = Vector3.ZERO

var signatures : Array[RadarSignature]
var markers : Array[Node3D]

@export var update_interval := 0.05
@export var map_scale := 0.0005
@export var main_ship : ShipManager


func _ready() -> void:
	for i in get_tree().get_nodes_in_group("radar signature"):
		signatures.append(i as RadarSignature)
		var marker = RADAR_MARKER.instantiate() as Node3D
		marker_holder.add_child(marker)
		markers.append(marker)
		signatures[-1].set_marker_colour(marker)
	
	trajectory_visualiser.target = main_ship.movement_clone
	
	update_markers()
	update_trajectory()


func update_markers():
	for i in range(len(markers)):
		markers[i].position = (signatures[i].global_position - center_point) * map_scale
		markers[i].basis = signatures[i].global_basis
		markers[i].scale = signatures[i].scale * signatures[i].get_parent_node_3d().scale * map_scale
	
	await get_tree().create_timer(update_interval).timeout
	update_markers()


func update_trajectory():
	trajectory_visualiser.update_markers(map_scale, map_scale * 10)
	await get_tree().create_timer(update_interval).timeout
	update_trajectory()
