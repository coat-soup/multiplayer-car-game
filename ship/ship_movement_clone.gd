extends CharacterBody3D
class_name ShipMovementClone

@export var ship_manager : ShipManager
@export var movement_synch_lerp_speed : float = 0.0

func toggle_collider(value : bool):
	if not value:
		collision_layer = 0
		collision_mask = 0
	else:
		collision_layer = Util.layer_mask([5])
		collision_mask = Util.layer_mask([5])
