extends Node3D

@export var speed : Vector3

func _process(delta: float) -> void:
	rotation += speed * delta
