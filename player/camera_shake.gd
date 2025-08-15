extends Node3D
class_name CameraShake

@onready var default_pos : Vector3 = position

var shake_strength : float = 0.0
var shake_timer : float = 0.0
var shake_time : float = 0.5


func _process(delta: float) -> void:
	if shake_timer > 0:
		shake_timer -= delta
		
	
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, delta * 5.0)
		var offset = random_offset()
		position = default_pos + Vector3(offset.x, offset.y, 0)


func apply_shake(strength : float):
	shake_timer = shake_time
	shake_strength = strength


func random_offset() -> Vector2:
	return Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))


func normalized_shake_strength() -> float:
	return lerp(0, shake_strength, shake_timer/shake_time)
