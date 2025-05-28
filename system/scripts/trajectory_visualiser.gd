extends Node3D
class_name TrajectoryVisualiser

@export var target : ShipMovementManager

var planets : Array[Planet]

const TRAJECTORY_MARKER = preload("res://system/scenes/trajectory_marker.tscn")

var markers : Array[Node3D]

@export var spacing := 1.0
@export var n_markers := 30


func _ready() -> void:
	for i in get_tree().get_nodes_in_group("planet"):
		planets.append(i as Planet)
	
	for i in range(n_markers):
		markers.append(TRAJECTORY_MARKER.instantiate())
		add_child(markers[i])



func update_markers(visual_scale : float = 1.0, marker_scale : float = 1.0):
	var marker_pos := target.global_position
	var velocity := target.velocity_sync
	var looped := false
	for i in range(len(markers)):
		if not looped:
			markers[i].visible = true
			for planet in planets:
				velocity += Util.get_gravitational_acceleration(marker_pos, planet) * spacing
			marker_pos += velocity * spacing
			markers[i].position = marker_pos * visual_scale
			markers[i].scale = Vector3.ONE * marker_scale
			if i > 5 and marker_pos.distance_to(target.global_position) < 100: looped = true
		
		else:
			markers[i].visible = false
