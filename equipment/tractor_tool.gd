extends Equipment
class_name TractorTool

@export var beam_range : float = 10.0
@export var move_speed : float = 15.0
@export var acceleration : float = 50.0
@export var spin_speed : float = 0.2

var target : Item
var t_phys : RigidBody3D
var target_distance : float

@onready var audio: AudioStreamPlayer3D = $Audio

var constant_offset_for_some_fucking_reason := Vector3(0, -5000, 0)
@onready var cone: MeshInstance3D = $Cone


@export var color_by_norm_dist_grad : Gradient


func on_triggered(button : int):
	if button != 0: return
	if target:
		target.on_physics_let_go.rpc()
		
		target = null
		t_phys = null
		audio.playing = false
		cone.visible = false
		
	else:
		target = raycast_target()
		if target and not target.tractored:
			target.set_auth.rpc(str(held_player.name).to_int())
			
			target.on_physics_picked_up.rpc()
			
			t_phys = target.physics_dupe
			#TODO: particles
			
			#target.gravity_scale = 0
			target_distance = target.global_position.distance_to(global_position)
			audio.playing = true
			cone.visible = true
		else: print("Didn't hit anything")


func _input(event: InputEvent) -> void:
	super._input(event)
	if not held_by_auth: return
	var scroll_dir = int(Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN)) - int(Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP))
	if scroll_dir != 0:
		target_distance = clamp(target_distance - scroll_dir * 0.2, 2.0, beam_range)
	if Input.is_action_just_released("secondary_fire"):
		held_player.movement_manager.camera_locked = false


func _process(delta: float) -> void:
	if t_phys:
		if Input.is_action_pressed("secondary_fire"):
			held_player.movement_manager.camera_locked = true
			var spin_dir := Input.get_last_mouse_velocity()
			
			var t_vel = held_player.camera.global_basis.x * deg_to_rad(spin_dir.y * spin_speed) + held_player.camera.global_basis.y * deg_to_rad(spin_dir.x * spin_speed)
			if target.on_ship: t_vel = target.on_ship.global_basis.inverse() * t_vel
			t_phys.angular_velocity = t_phys.angular_velocity.move_toward(t_vel, 300.0 * delta)
			#target.set_target_angular_velocity.rpc_id(1, t_vel, 300)
		else:
			#target.set_target_angular_velocity.rpc_id(1, Vector3.ZERO, 30)
			t_phys.angular_velocity = t_phys.angular_velocity.move_toward(Vector3.ZERO, delta * 30)
		
		var point := (global_position - global_basis.z * target_distance)
		if target.on_ship:
			point = held_player.movement_manager.ship.movement_clone.to_local(point) + constant_offset_for_some_fucking_reason
		#target.set_linear_velocity.rpc_id(1, move_speed * (point - t_phys.global_position).limit_length(1.0))
		t_phys.linear_velocity = move_speed * (point - t_phys.global_position).limit_length(1.0)
		
		var lag_distance = point.distance_to(t_phys.global_position)
		var normalised_lag_distance = min(1.0, lag_distance/5.0)
		audio.pitch_scale = lerp(1.0,1.2, normalised_lag_distance)
		#(cone.get_surface_override_material(0) as StandardMaterial3D).albedo_color = color_by_norm_dist_grad.sample(normalised_lag_distance)
		
		if target.global_position.distance_to(global_position) > beam_range * 1.3:
			on_triggered(0)


func raycast_target() -> Item:
	var space_state = get_world_3d().direct_space_state

	var query = PhysicsRayQueryParameters3D.create(held_player.camera.global_position, held_player.camera.global_position - held_player.camera.global_basis.z * beam_range, Util.layer_mask([1]))
	query.exclude = [held_player]

	var result := space_state.intersect_ray(query)
	if result:
		return result.collider as Item
	return null
