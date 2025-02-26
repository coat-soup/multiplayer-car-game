extends Node3D

@onready var exit_point: Node3D = $ExitPoint


func _on_static_body_3d_interacted(source) -> void:
	source.global_position = exit_point.global_position
