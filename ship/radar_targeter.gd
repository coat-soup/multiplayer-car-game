extends Node3D
class_name RadarTargeter

@export var controllable : Controllable
@export var radar_manager : RadarManager

@export var weapons_controller : MountedWeaponsController
@export var parent_ship : ShipManager
@export var parent_component : ShipComponent

@onready var ui : UIManager = get_tree().get_first_node_in_group("ui") as UIManager

var cur_target : RadarSignature
var target_last_pos : Vector3
var cached_local_player : Player

var t_vel : Vector3

func _ready() -> void:
	controllable.control_started.connect(on_control_started)
	controllable.control_ended.connect(on_control_ended)
	weapons_controller.radar_targeter = self


func _input(event: InputEvent) -> void:
	if not controllable.is_multiplayer_authority() or not controllable.using_player: return
	
	if event.is_action_pressed("target_radar_signature"):
		var t = get_forward_target()
		if t == cur_target or t == null:
			cur_target = null
			ui.end_target_lock()
		else:
			cur_target = t
			if cur_target: ui.start_target_lock(cur_target, weapons_controller != null)


func _process(delta: float) -> void:
	if cur_target:
		if not is_instance_valid(cur_target):
			cur_target = null
			ui.end_target_lock()
		elif weapons_controller:
			t_vel = (cur_target.global_position - target_last_pos) / delta
			var vel = parent_ship.movement_manager.velocity_sync if parent_ship else parent_component.ship.movement_manager.velocity_sync if parent_component else Vector3.ZERO
			ui.update_target_lock(cur_target, get_target_lead_position(), controllable.camera)
			
			target_last_pos = cur_target.global_position


func get_target_lead_position() -> Vector3:
	var vel = parent_ship.movement_manager.velocity_sync if parent_ship else parent_component.ship.movement_manager.velocity_sync if parent_component else Vector3.ZERO
	return cur_target.global_position + (t_vel - vel) * cur_target.global_position.distance_to(global_position) / weapons_controller.bullet_speed


func get_forward_target() -> RadarSignature:
	var c_dot := -1.0
	var closest : RadarSignature = null
	
	for sig in radar_manager.tracked_signatures:
		var t_dot = global_basis.z.dot((sig.global_position - global_position).normalized())
		if t_dot > c_dot:
			closest = sig
			c_dot = t_dot
	
	return closest


func on_control_started():
	if controllable.is_multiplayer_authority() and controllable.using_player: cached_local_player = controllable.using_player

func on_control_ended():
	if cached_local_player:
		ui.end_target_lock()
		cached_local_player = null
