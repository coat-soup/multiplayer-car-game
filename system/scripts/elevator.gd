extends Node3D
class_name Elevator

signal reached_floor
signal moving_to_floor

@export var floor_positions : Array[Node3D]
@export var platform : Node3D

@export var speed : float = 5.0

@export var target_floor : int = 0

var cycle_dir := 1
var moving = false


func _process(delta: float) -> void:
	if moving:
		if is_at_floor(target_floor):
			reached_floor.emit(target_floor)
			moving = false
		
		if target_floor >= 0 and target_floor < len(floor_positions):
			platform.position = platform.position.move_toward(floor_positions[target_floor].position, delta * speed)

@rpc("any_peer", "call_local")
func call_to_floor(floor_id):
	if int(floor_id) != target_floor:
		target_floor = int(floor_id)
		moving = true
		
		moving_to_floor.emit(target_floor)

@rpc("any_peer", "call_local")
func cycle_floor(_pass):
	if target_floor >= len(floor_positions) - 1: cycle_dir = -1
	elif target_floor <= 0: cycle_dir = 1
	
	target_floor += cycle_dir
	moving = true
	
	moving_to_floor.emit(target_floor)


func is_at_floor(floor_id) -> bool:
	if int(floor_id) == -1: return false
	else: return platform.position.distance_to(floor_positions[int(floor_id)].position) < 0.01
