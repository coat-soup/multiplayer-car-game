extends RemoteTransform3D

class_name Controllable

signal control_started
signal control_ended

@export var camera : Camera3D
@export var interactable : Interactable

@export var synchronizer : MultiplayerSynchronizer

var using_player : Player = null
var ai_override := false

var ui : UIManager

@onready var root_owner : Node = get_owner()
@export var transfer_auth := true


func _enter_tree() -> void:
	camera.current = false

func _ready() -> void:
	ui = get_tree().get_first_node_in_group("ui") as UIManager
	interactable.interacted.connect(on_interact)


func _input(event: InputEvent) -> void:
	if using_player and is_multiplayer_authority() and (event.is_action_pressed("interact") or event.is_action_pressed("interact")):
		un_controll.rpc()


func on_interact(player):
	if using_player:
		ui.display_chat_message.rpc("%s attempting control of %s. %s already in control" % [player.name, root_owner.name, using_player.name])
		return
	take_control.rpc(str(player.name))


@rpc("any_peer", "call_local")
func take_control(player_id : String):
	var player = Util.get_player_from_id(str(player_id), self)
	
	root_owner.set_multiplayer_authority(str(player.name).to_int(), false)
	synchronizer.set_multiplayer_authority(str(player.name).to_int(), false)
	set_multiplayer_authority(str(player.name).to_int(), false)
	
	ui.display_chat_message("%s (auth: %s) taking control of %s" % [player.name, str(player.is_multiplayer_authority()), root_owner.name])
	
	using_player = player
	#using_player.reparent(interactable)
	remote_path = get_path_to(using_player.movement_manager)
	player.position = Vector3.ZERO
	
	if is_multiplayer_authority():
		using_player.hide()
		ui.display_chat_message("true auth, doing cam")
		camera.current = true
		using_player.active = false
		using_player.health.died.connect(on_player_died)
	else:
		ui.display_chat_message("no auth, no cam")
	interactable.active = false
	control_started.emit()


func on_player_died():
	un_controll.rpc()


@rpc("any_peer", "call_local")
func un_controll():
	if not using_player: return
	ui.display_chat_message("%s (auth: %s) exiting %s" % [using_player.name, str(using_player.is_multiplayer_authority()), root_owner.name])
	
	if is_multiplayer_authority():
		ui.display_chat_message("true auth, proper exit")
		camera.current = false
		using_player.camera.current = true
		using_player.active = true
		using_player.health.died.disconnect(on_player_died)
	else:
		ui.display_chat_message("no auth, doing nothing")
	
	using_player.show()
	#using_player.reparent(get_tree().get_root())
	remote_path = ""
	using_player = null
	control_ended.emit()
	
	await get_tree().create_timer(0.5).timeout
	interactable.active = true


@rpc("any_peer", "call_local")
func reset_synch_auth():
	synchronizer.set_multiplayer_authority(1, false)
	root_owner.set_multiplayer_authority(1, false)

@rpc("any_peer", "call_local")
func retry_sync_auth():
	if using_player:
		synchronizer.set_multiplayer_authority(str(using_player.name).to_int(), false)
		root_owner.set_multiplayer_authority(str(using_player.name).to_int(), false)
