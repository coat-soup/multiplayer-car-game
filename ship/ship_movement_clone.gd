extends CharacterBody3D
class_name ShipMovementClone

@export var ship_manager : ShipManager
@export var movement_synch_lerp_speed : float = 0.0

@export var synched_position : Vector3

func toggle_collider(value : bool):
	if not value:
		collision_layer = 0
		collision_mask = 0
	else:
		collision_layer = Util.layer_mask([5])
		collision_mask = Util.layer_mask([5])

func _process(delta: float) -> void:
	if movement_synch_lerp_speed > 0:
		if is_multiplayer_authority():
			synched_position = global_position
			ship_manager.movement_manager.ui.display_chat_message("SENDING")
		else:
			global_position = global_position.lerp(synched_position, delta * movement_synch_lerp_speed)
			ship_manager.movement_manager.ui.display_chat_message("LERPING")
