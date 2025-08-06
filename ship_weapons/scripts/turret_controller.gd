extends Node
class_name TurretController

@export var yaw_obj: Node3D
@export var pitch_obj: Node3D
@export var camera: Camera3D


@export var control_manager : Controllable
@export var sensetivity := 0.005
@export var turn_speed := 1.5

@export var crosshair : Node3D


@export_range(-360, 360) var p_min := 0
@export_range(-360, 360) var p_max := 180

var virtual_joystick_value = Vector2.ZERO
@export var do_joystick := true

var ui : UIManager

@export var ship_component : ShipComponent
@export var weapons_manager : MountedWeaponsController
@export var radar_targeter : RadarTargeter


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
	weapons_manager.ship = ship_component.ship
	
	for hardpoint in weapons_manager.hardpoints:
		hardpoint.ship = weapons_manager.ship
	
	
	if radar_targeter: radar_targeter.radar_manager = ship_component.ship.radar_manager


func _unhandled_input(event: InputEvent) -> void:
	if control_manager.ai_override: return
	if not control_manager.using_player: return
	if not control_manager.is_multiplayer_authority(): return
	
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if do_joystick:
			virtual_joystick_value += Vector2(event.relative.x, event.relative.y) * sensetivity
			virtual_joystick_value = virtual_joystick_value.limit_length(1)
			ui.update_virtual_joystick(virtual_joystick_value)
		else:
			camera.rotation.y += (-event.relative.x * sensetivity) * (-1.0 if camera.rotation.x > PI/2 else 1.0)
			camera.rotation.x += (-event.relative.y * sensetivity)# * (-1.0 if camera.rotation.x > PI/2 else 1.0)
			
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(p_min), deg_to_rad(p_max))
			#print(rad_to_deg(camera.rotation.x), ", ", rad_to_deg(camera.rotation.y), ", ", rad_to_deg(camera.rotation.z), " YDIFF: ", (-event.relative.y * sensetivity))# * (-1.0 if camera.rotation.x > PI/2 else 1.0))


func ai_camera_input(dir : Vector2):
	camera.rotation.y += (-dir.x * sensetivity)
	camera.rotation.x += (-dir.y * sensetivity)
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(p_min), deg_to_rad(p_max))


func ai_camera_lookat(global_pos : Vector3):
	camera.look_at(global_pos)


func _process(delta: float) -> void:
	if not (control_manager.using_player or control_manager.ai_override): return
	if not control_manager.is_multiplayer_authority(): return
	
	camera.position = ship_component.to_local($"Yaw/Pitch/CameraPositionPush".global_position)
	
	if do_joystick and virtual_joystick_value.length() > 0.1:
		yaw_obj.rotate_y(-virtual_joystick_value.x * turn_speed * delta)
		pitch_obj.rotate_x(-virtual_joystick_value.y * turn_speed * delta)
		pitch_obj.rotation.x = clamp(pitch_obj.rotation.x, deg_to_rad(p_min), deg_to_rad(p_max))
		
	else:
		camera.rotation.z = 0
		#var m = 1.0 if camera.rotation.x < deg_to_rad(90) else -1.0
		yaw_obj.rotation.y += clamp(wrapf(camera.rotation.y - yaw_obj.rotation.y, -PI, PI) * 10, -1, 1) * delta * turn_speed
		pitch_obj.rotation.x += clamp(wrapf(camera.rotation.x - pitch_obj.rotation.x, -PI, PI) * 10, -1, 1) * delta * turn_speed
		pitch_obj.rotation.x = clamp(pitch_obj.rotation.x, deg_to_rad(p_min), deg_to_rad(p_max))
	
	ui.toggle_power_warning(ship_component and ship_component.power_ratio() == 0)


func on_controlled():
	if do_joystick and control_manager.is_multiplayer_authority():
		ui.toggle_virtual_joystick(true)
	if control_manager.is_multiplayer_authority():
		crosshair.visible = true
		ui.toggle_turet_power_panel(true)
		ship_component.ship.power_manager.capacitors_changed.connect(update_ui_capacitors)
		update_ui_capacitors()


func on_uncontrolled():
	crosshair.visible = false
	if control_manager.is_multiplayer_authority():
		ui.toggle_virtual_joystick(false)
		ui.toggle_turet_power_panel(false)
		ship_component.ship.power_manager.capacitors_changed.disconnect(update_ui_capacitors)


static func pushv(val, deadzone = 0.1) -> float:
	return val if abs(val) <= deadzone else 1.0 if val > 0.0 else -1.0


func update_ui_capacitors():
	if not ship_component: return
	var power_system : PowerSystem = ship_component.ship.power_manager.get_system(ship_component.power_system_name)
	ui.update_turret_capacitors(power_system.assigned_capacitors, power_system.max_capacitors)


func on_broken():
	control_manager.un_controll.rpc()
	print("kicking player")
	print("TURRET BROKEN")
	
	control_manager.interactable.toggle_active.rpc(false)


func on_fixed():
	control_manager.interactable.toggle_active.rpc(true)
	pass
