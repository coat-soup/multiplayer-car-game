extends Node3D

@export var floor_positions : Array[Node3D]
@export var platform : Node3D

@export var speed : float = 5.0

@export var target_floor : int = 0

var cycle_dir := 1


func _process(delta: float) -> void:
	if target_floor >= 0 and target_floor < len(floor_positions):
		platform.position = platform.position.move_toward(floor_positions[target_floor].position, delta * speed)


func call_to_floor(floor):
	target_floor = int(floor)

func cycle_floor(dir):
	if target_floor >= len(floor_positions) - 1: cycle_dir = -1
	elif target_floor <= 0: cycle_dir = 1
	
	target_floor += cycle_dir
