extends Node3D
class_name TractorBeam

signal tractor_started
signal tractor_ended

@export var beam_range : float = 10.0
@export var move_speed : float = 15.0
@export var acceleration : float = 50.0
@export var spin_speed : float = 0.2

var target : Item
var t_phys : RigidBody3D
var target_distance : float

var dupe_world_offset := Vector3(0, -5000, 0) # (duped ship position)

@export var player : Player
var point : Vector3


func _process(delta: float) -> void:
	if t_phys:
		if Input.is_action_pressed("secondary_fire"):
			player.movement_manager.camera_locked = true
			var spin_dir := Input.get_last_mouse_velocity()
			
			var t_vel = player.camera.global_basis.x * deg_to_rad(spin_dir.y * spin_speed) + player.camera.global_basis.y * deg_to_rad(spin_dir.x * spin_speed)
			if target.on_ship: t_vel = target.on_ship.global_basis.inverse() * t_vel
			t_phys.angular_velocity = t_phys.angular_velocity.move_toward(t_vel, 300.0 * delta)
			#target.set_target_angular_velocity.rpc_id(1, t_vel, 300)
		else:
			#target.set_target_angular_velocity.rpc_id(1, Vector3.ZERO, 30)
			t_phys.angular_velocity = t_phys.angular_velocity.move_toward(Vector3.ZERO, delta * 30)
		
		point = (global_position - global_basis.z * target_distance)
		if target.on_ship:
			point = player.movement_manager.ship.movement_clone.to_local(point) + dupe_world_offset
		#target.set_linear_velocity.rpc_id(1, move_speed * (point - t_phys.global_position).limit_length(1.0))
		t_phys.linear_velocity = move_speed * (point - t_phys.global_position).limit_length(1.0)
		
		if target.global_position.distance_to(global_position) > beam_range * 1.3:
			stop_grab()


func get_normalised_lag_distance() -> float:
	var lag_distance = point.distance_to(t_phys.global_position)
	return min(1.0, lag_distance/5.0)


func start_grab():
	target = raycast_target()
	if target and not target.tractored and not target.immovable:
		target.set_auth.rpc(str(player.name).to_int())
		
		target.on_physics_picked_up.rpc()
		
		t_phys = target.physics_dupe
		#TODO: particles
		
		#target.gravity_scale = 0
		target_distance = target.global_position.distance_to(global_position)
		tractor_started.emit(target)


func stop_grab():
	if target:
		target.on_physics_let_go.rpc()
		
		var t_temp = target
		
		target = null
		t_phys = null
		
		tractor_ended.emit(t_temp)


func raycast_target() -> Item:
	var space_state = get_world_3d().direct_space_state

	var query = PhysicsRayQueryParameters3D.create(player.camera.global_position, player.camera.global_position - player.camera.global_basis.z * beam_range, Util.layer_mask([1]))
	query.exclude = [player]

	var result := space_state.intersect_ray(query)
	if result:
		return result.collider as Item
	return null
