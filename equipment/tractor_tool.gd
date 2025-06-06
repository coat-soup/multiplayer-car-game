extends Equipment
class_name TractorTool

@export var beam_range : float = 10.0
@export var move_speed : float = 15.0
@export var acceleration : float = 50.0
@export var spin_speed : float = 0.2

var target : RigidBody3D
var target_distance : float

@onready var audio: AudioStreamPlayer = $Audio


func on_triggered(button : int):
	if button != 0: return
	if target:
		print("letting go")
		#target.gravity_scale = 1
		target = null
		
	else:
		print("beaming")
		
		target = raycast_target()
		if target:
			#TODO: particles
			
			#target.gravity_scale = 0
			target_distance = target.global_position.distance_to(global_position)
			
			audio.pitch_scale = randf_range(0.9,1.1)
			audio.play()
		else: print("Didn't hit anything")


func _input(event: InputEvent) -> void:
	super._input(event)
	if not held_by_auth: return
	var scroll_dir = int(Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN)) - int(Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP))
	if scroll_dir != 0:
		target_distance = clamp(target_distance - scroll_dir * 0.2, 1.0, beam_range)
	if Input.is_action_just_released("secondary_fire"):
		held_player.movement_manager.camera_locked = false


func _process(delta: float) -> void:
	if target:
		if Input.is_action_pressed("secondary_fire"):
			held_player.movement_manager.camera_locked = true
			var spin_dir := Input.get_last_mouse_velocity()
			#target.global_rotate(global_basis.y, deg_to_rad(spin_dir.x * spin_speed * delta))
			#target.global_rotate(global_basis.x, deg_to_rad(spin_dir.y * spin_speed * delta))
			var t_vel = global_basis * Vector3(deg_to_rad(spin_dir.y * spin_speed), deg_to_rad(spin_dir.x * spin_speed), 0)
			target.angular_velocity = target.angular_velocity.move_toward(t_vel, 300.0 * delta)
		else:
			target.angular_velocity = target.angular_velocity.move_toward(Vector3.ZERO, delta * 30)
		#target.apply_force(force * delta * ((global_position - global_basis.z * beam_range / 2) - target.global_position).limit_length(1.0))
		var point = (global_position - global_basis.z * target_distance)
		target.linear_velocity = move_speed * (point - target.global_position).limit_length(1.0)
		#target.linear_velocity = target.linear_velocity.move_toward(move_speed * (point - target.global_position).limit_length(1.0), delta * acceleration)


func raycast_target() -> PhysicsBody3D:
	var space_state = get_world_3d().direct_space_state

	var query = PhysicsRayQueryParameters3D.create(held_player.camera.global_position, held_player.camera.global_position - held_player.camera.global_basis.z * beam_range, Util.layer_mask([1]))
	query.exclude = [held_player]

	var result := space_state.intersect_ray(query)
	if result: return result.collider as PhysicsBody3D
	else: return null
