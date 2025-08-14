extends Node3D
class_name Ladder

@onready var exit_point: Node3D = $ExitPoint
@onready var top_bits: MeshInstance3D = $Cylinder_010


func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	var parent_ladder := get_parent() as Ladder
	if parent_ladder:
		top_bits.visible = false
		exit_point = parent_ladder.exit_point


func _on_static_body_3d_interacted(source) -> void:
	var player = source as Player
	if player:
		player.movement_manager.global_position = exit_point.global_position
