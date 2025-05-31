extends Node
class_name GameManager


func _ready() -> void:
	pass
	#get_viewport().size = DisplayServer.screen_get_size()
	#await get_tree().create_timer(3.0).timeout
	#get_viewport().size = Vector2(1920, 1080)
	#await get_tree().create_timer(3.0).timeout
	#get_viewport().size = Vector2(3840, 2160)


func _input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
