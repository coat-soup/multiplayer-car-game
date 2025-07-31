extends TractorBeam
class_name PlayerGrab

## max cargo volume (x*y*z) item that can be picked up
@export var max_grid_volume : int = 2



func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	if event.is_action_pressed("grab") and not target:
		start_grab()
	elif event.is_action_released("grab"):
		stop_grab()
	
	#var scroll_dir = int(Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN)) - int(Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP))
	#if scroll_dir != 0:
		#target_distance = clamp(target_distance - scroll_dir * 0.2, 0.5, beam_range)
	if Input.is_action_just_released("secondary_fire"):
		player.movement_manager.camera_locked = false


func raycast_target() -> Item:
	var t : Item = super.raycast_target()
	if t and t.cargo_grid_dimensions.x * t.cargo_grid_dimensions.y * t.cargo_grid_dimensions.z > max_grid_volume:
		player.ui.display_prompt("Too large to grab")
		return null
	else: return t
