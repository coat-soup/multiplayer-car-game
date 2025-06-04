extends Node3D
class_name CannonController

@onready var yaw_obj: Node3D = $Yaw
@onready var pitch_obj: Node3D = $Yaw/Pitch
@onready var camera: Camera3D = $Camera3D

@export var shell : PackedScene

@export var control_manager : Controllable
@export var sensetivity := 0.005
@export var turn_speed := 1.5
@export var full_auto := false

@export var barrel_end : Node3D
@export var crosshair : Node3D

@export var fire_rate := 1.2
var fire_timer := 0.0

@export_range(-360, 360) var p_min := -30
@export_range(-360, 360) var p_max := 40

var virtual_joystick_value = Vector2.ZERO
@export var do_joystick := true

var ui : UIManager

@onready var firing_audio: AudioStreamPlayer3D = $Yaw/Pitch/BarrelEnd/FiringAudio
@export var ship_component : ShipComponent
@export var ship : ShipManager
var found_bullet_speed : float = 100


func _ready() -> void:
	ui = get_tree().get_first_node_in_group("ui") as UIManager
	
	if not ship_component:
		ship_component = get_parent() as ShipComponent
	if ship_component:
		ship_component.broken.connect(on_broken)
		ship_component.fixed.connect(on_fixed)
	
	control_manager.control_started.connect(on_controlled)
	control_manager.control_ended.connect(on_uncontrolled)
	
	crosshair.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if control_manager.ai_override: return
	if not control_manager.using_player: return
	if not control_manager.is_multiplayer_authority(): return
	
	if !full_auto and event.is_action_pressed("primary_fire") and fire_timer <= 0:
		fire_cannon.rpc()
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if do_joystick:
			virtual_joystick_value += Vector2(event.relative.x, event.relative.y) * sensetivity
			virtual_joystick_value = virtual_joystick_value.limit_length(1)
			ui.update_virtual_joystick(virtual_joystick_value)
		else:
			camera.rotation.y += (-event.relative.x * sensetivity)
			camera.rotation.x += (-event.relative.y * sensetivity)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(p_min), deg_to_rad(p_max))


func ai_camera_input(dir : Vector2):
	camera.rotation.y += (-dir.x * sensetivity)
	camera.rotation.x += (-dir.y * sensetivity)
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(p_min), deg_to_rad(p_max))


func ai_camera_lookat(global_pos : Vector3):
	camera.look_at(global_pos)


func ai_try_fire() -> bool:
	if fire_timer <= 0:
		fire_cannon.rpc()
		return true
	else: return false


func _process(delta: float) -> void:
	if fire_timer > 0:
		fire_timer -= delta
	
	if not (control_manager.using_player or control_manager.ai_override): return
	if not control_manager.is_multiplayer_authority(): return
	
	if not control_manager.ai_override and full_auto and Input.is_action_pressed("primary_fire") and fire_timer <= 0:
		fire_cannon.rpc()
	
	if do_joystick and virtual_joystick_value.length() > 0.1:
		yaw_obj.rotate_y(-virtual_joystick_value.x * turn_speed * delta)
		pitch_obj.rotate_x(-virtual_joystick_value.y * turn_speed * delta)
		pitch_obj.rotation.x = clamp(pitch_obj.rotation.x, deg_to_rad(p_min), deg_to_rad(p_max))
		
	else:
		camera.rotation.z = 0
		yaw_obj.rotation.y += clamp(wrapf(camera.rotation.y - yaw_obj.rotation.y, -PI, PI) * 10, -1, 1) * delta * turn_speed
		pitch_obj.rotation.x += clamp(wrapf(camera.rotation.x - pitch_obj.rotation.x, -PI, PI) * 10, -1, 1) * delta * turn_speed
		pitch_obj.rotation.x = clamp(pitch_obj.rotation.x, deg_to_rad(p_min), deg_to_rad(p_max))
		return


@rpc("any_peer", "call_local")
func fire_cannon():
	fire_timer = 1 / fire_rate
	
	firing_audio.play()
	
	var shell_obj = shell.instantiate() as CannonShell
	get_tree().get_root().add_child(shell_obj)
	shell_obj.global_position = barrel_end.global_position
	shell_obj.global_rotation = barrel_end.global_rotation
	shell_obj.ui = ui
	found_bullet_speed = shell_obj.speed
	shell_obj.source = control_manager.using_player.name.to_int() if control_manager.using_player else -1
	shell_obj._ready()
	
	if control_manager.is_multiplayer_authority():
		shell_obj.fired_from_auth = true
	
	if ship:
		shell_obj.velocity += ship.movement_manager.velocity_sync


func on_controlled():
	if do_joystick and control_manager.is_multiplayer_authority():
		ui.toggle_virtual_joystick(true)
	if control_manager.is_multiplayer_authority():
		crosshair.visible = true


func on_uncontrolled():
	crosshair.visible = false
	if control_manager.is_multiplayer_authority():
		ui.toggle_virtual_joystick(false)


static func pushv(val, deadzone = 0.1) -> float:
	return val if abs(val) <= deadzone else 1.0 if val > 0.0 else -1.0


func on_broken():
	control_manager.un_controll.rpc()
	print("kicking player")
	
	control_manager.interactable.toggle_active.rpc(false)


func on_fixed():
	control_manager.interactable.toggle_active.rpc(true)
	pass
