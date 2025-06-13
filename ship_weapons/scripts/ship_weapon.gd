extends ShipComponent
class_name ShipWeapon

@export var shell : PackedScene

@export var barrel_end : Node3D

@export var full_auto := true
@export var fire_rate := 1.2
var fire_timer := 0.0

var ui : UIManager

@export var firing_audio: AudioStreamPlayer3D
@export var weapons_controller : MountedWeaponsController
var found_bullet_speed : float = 100


func _ready() -> void:
	ui = get_tree().get_first_node_in_group("ui") as UIManager


func _process(delta: float) -> void:
	if fire_timer > 0:
		fire_timer -= delta


@rpc("any_peer", "call_local")
func fire_cannon():
	ui.display_chat_message("firing")
	fire_timer = 1 / fire_rate
	
	firing_audio.play()
	
	var shell_obj = shell.instantiate() as CannonShell
	get_tree().get_root().add_child(shell_obj)
	shell_obj.global_position = barrel_end.global_position
	shell_obj.global_rotation = barrel_end.global_rotation
	shell_obj.ui = ui
	found_bullet_speed = shell_obj.speed
	shell_obj.source = weapons_controller.controllable.using_player.name.to_int() if weapons_controller.controllable.using_player else -1
	shell_obj._ready()
	
	if weapons_controller.controllable.is_multiplayer_authority():
		shell_obj.fired_from_auth = true
	
	if weapons_controller.ship:
		shell_obj.velocity += weapons_controller.ship.movement_manager.velocity_sync
