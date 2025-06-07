extends RigidBody3D
class_name Tractorable

@export var on_ship: ShipManager
var old_vel : Vector3

func _physics_process(_delta: float) -> void:
	if on_ship and is_multiplayer_authority():
		var vel_diff = on_ship.movement_manager.velocity_sync - old_vel

		# Only add part of the relative velocity to avoid full snapping
		# This simulates loose attachment: tweak factor as needed
		linear_velocity += vel_diff
		old_vel = on_ship.movement_manager.velocity_sync
		#linear_velocity += on_ship.global_basis.y * -10 * get_physics_process_delta_time()



var prev_ship_transform: Transform3D

func _integrate_forces_old(state: PhysicsDirectBodyState3D) -> void:
	if on_ship and is_multiplayer_authority():
		linear_velocity += on_ship.global_basis.y * -10 * get_physics_process_delta_time()
		
		var current_ship_transform = on_ship.global_transform
		
		# Calculate the relative transform of the item to the previous ship transform
		var local_transform = prev_ship_transform.affine_inverse() * state.transform
		
		# Apply the current ship transform to the local transform to get the new global transform
		var new_transform = current_ship_transform * local_transform
		
		# Update the item's physics transform
		state.transform = new_transform
		
		prev_ship_transform = current_ship_transform
