extends Node3D

@export var target : CharacterBody3D
@export var ship : ShipManager

var planets : Array[Planet]

const TRAJECTORY_MARKER = preload("res://system/trajectory_marker.tscn")

var markers : Array[Node3D]

@export var spacing := 1.0
@export var n_markers := 30


func _ready() -> void:
	for i in get_tree().get_nodes_in_group("planet"):
		planets.append(i as Planet)
	
	for i in range(n_markers):
		markers.append(TRAJECTORY_MARKER.instantiate())
		add_child(markers[i])


func _process(_delta: float) -> void:
	if target:
		update_markers()
	elif ship:
		target = ship.movement_clone


func update_markers():
	var marker_pos := target.global_position
	var velocity := target.velocity
	for i in range(len(markers)):
		for planet in planets:
			velocity += Util.get_gravitational_acceleration(marker_pos, planet) * spacing
		marker_pos += velocity * spacing
		markers[i].global_position = marker_pos
