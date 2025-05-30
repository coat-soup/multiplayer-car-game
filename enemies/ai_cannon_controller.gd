extends Node
class_name AICannonController

@export var cannon_controller : CannonController
@export var target : ShipComponent
@export var fire_angle := 5.0

@export var spread := 0.1 # lateral radius per distance unit

@export var sight_range := 50.0

var spread_offset := Vector3.ZERO

var distance_to_target := 0.0


func _ready() -> void:
	cannon_controller.control_manager.ai_override = true
	cannon_controller.control_manager.interactable.active = false
	target = (get_tree().get_first_node_in_group("ship") as ShipManager).main_target_component


func _process(_delta: float) -> void:
	if not target:
		print("no target")
		return
	
	if is_multiplayer_authority():
		distance_to_target = cannon_controller.global_position.distance_to(target.global_position)
		if distance_to_target <= sight_range:
			cannon_controller.ui.display_chat_message("vel:" + str(target.get_parent_velocity()))
			var adjusted_pos = target.global_position + spread_offset + target.get_parent_velocity() * distance_to_target / cannon_controller.found_bullet_speed
			var angle = rad_to_deg((adjusted_pos - cannon_controller.barrel_end.global_position).angle_to(cannon_controller.barrel_end.global_basis.z))
			cannon_controller.ai_camera_lookat(adjusted_pos)
			
			if angle <= fire_angle and cannon_controller.fire_timer <= 0:
				var query = PhysicsRayQueryParameters3D.create(cannon_controller.barrel_end.global_position, target.global_position, Util.layer_mask([1,2,3]))
				query.exclude = [cannon_controller]

				var result = cannon_controller.get_world_3d().direct_space_state.intersect_ray(query)

				if result and result.position.distance_to(target.global_position) < result.position.distance_to(cannon_controller.barrel_end.global_position):
					cannon_controller.ai_try_fire()
					randomise_spread_offset()
	else:
		print("not auth")


func randomise_spread_offset():
	spread_offset = cannon_controller.barrel_end.global_basis.y * randf() * spread * distance_to_target
	spread_offset = spread_offset.rotated(cannon_controller.barrel_end.global_basis.z, randf() * 2 * PI)
