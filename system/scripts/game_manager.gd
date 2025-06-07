extends Node
class_name GameManager

@export var ship_holder : Node3D

func _ready() -> void:
	pass
	#ship_holder.global_position = Vector3.ZERO


func _input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
