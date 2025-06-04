extends MeshInstance3D
class_name GunBulletVisual

@export var center_speed := 20.0

func start_at_pos(pos : Vector3):
	global_position = pos

func _process(delta: float) -> void:
	position = position.lerp(Vector3.ZERO, min(1, delta * center_speed))
