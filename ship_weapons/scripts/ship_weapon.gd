extends ShipComponent
class_name ShipWeapon

@export var ammo_type : AmmoCrate.AMMO_TYPE

@export var shell : PackedScene

@export var barrel_end : Node3D

@export var full_auto := true
@export var fire_rate := 1.2
var fire_timer := 0.0

@export var firing_audio: AudioStreamPlayer3D
@export var weapons_controller : MountedWeaponsController
var found_bullet_speed : float = 100

const capacitor_boost_range := Vector2(0.5,1)
@export var heat_per_shot := 10.0
@onready var heat_manager : ComponentHeatManager = $ComponentHeatManager

#var ui

func _ready() -> void:
	ui = get_tree().get_first_node_in_group("ui") as UIManager
	super._ready()
	
	heat_manager.cooling_delay = 1/fire_rate


func _process(delta: float) -> void:
	if fire_timer > 0:
		fire_timer -= delta


@rpc("any_peer", "call_local")
func fire_cannon():
	if power_ratio() <= 0 or heat_manager.cur_heat + heat_per_shot >= heat_manager.heat_capacity: return
	var crate = weapons_controller.get_filled_ammo_crate_of_type(ammo_type)
	if not crate: return
	else: crate.remove_ammo(1)
	
	fire_timer = 1 / (fire_rate * lerp(capacitor_boost_range.x, capacitor_boost_range.y, power_ratio()))
	
	firing_audio.pitch_scale = randf_range(0.9, 1.1)
	firing_audio.play()
	
	var shell_obj = shell.instantiate() as CannonShell
	get_tree().get_root().add_child(shell_obj)
	shell_obj.global_position = barrel_end.global_position
	shell_obj.global_rotation = barrel_end.global_rotation
	
	if weapons_controller.radar_targeter and weapons_controller.radar_targeter.cur_target: # convergence
		var distance_to_lead = max(10.0, weapons_controller.radar_targeter.get_target_lead_position().distance_to(weapons_controller.global_position))
		shell_obj.global_rotation = Util.get_rotation_towards(shell_obj.global_position, weapons_controller.to_global(Vector3.FORWARD * distance_to_lead))
	
	shell_obj.ui = ui
	found_bullet_speed = shell_obj.speed
	shell_obj.source = weapons_controller.controllable.using_player.name.to_int() if weapons_controller.controllable.using_player else -1
	shell_obj._ready()
	
	if weapons_controller.controllable.is_multiplayer_authority():
		shell_obj.fired_from_auth = true
	
	if weapons_controller.ship:
		shell_obj.velocity += weapons_controller.ship.movement_manager.velocity_sync
	
	heat_manager.add_heat(heat_per_shot)
