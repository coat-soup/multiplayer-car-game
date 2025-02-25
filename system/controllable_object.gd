extends RemoteTransform3D

class_name Controllable

signal control_started
signal control_ended

@export var camera : Camera3D
@export var interactable : Interactable

@export var synchronizer : MultiplayerSynchronizer

var using_player : PlayerMovement = null

var ui : UIManager


func _ready() -> void:
	ui = get_tree().get_first_node_in_group("ui") as UIManager
	interactable.interacted.connect(on_interact)


func _input(event: InputEvent) -> void:
	if using_player and is_multiplayer_authority() and (event.is_action_pressed("interact") or event.is_action_pressed("interact")):
		un_controll.rpc()


func on_interact(player):
	if using_player:
		ui.display_chat_message.rpc("%s attempting control of cannon. %s already in control" % [player.name, using_player.name])
		return
	take_control.rpc(str(player.name))


@rpc("any_peer", "call_local")
func take_control(player_id : String):
	var player = Util.get_player_from_id(str(player_id), self)
	
	get_owner().set_multiplayer_authority(str(player.name).to_int())
	set_multiplayer_authority(str(player.name).to_int())
	
	ui.display_chat_message("%s (auth: %s) taking control of cannon" % [player.name, str(player.is_multiplayer_authority())])
	
	using_player = player
	#using_player.reparent(interactable)
	remote_path = get_path_to(using_player)
	player.position = Vector3.ZERO
	
	if is_multiplayer_authority():
		using_player.hide()
		ui.display_chat_message("true auth, doing cam")
		control_started.emit()
		camera.current = true
		using_player.active = false
	else:
		ui.display_chat_message("no auth, no cam")


@rpc("any_peer", "call_local")
func un_controll():
	ui.display_chat_message("%s (auth: %s) exiting cannon" % [using_player.name, str(using_player.is_multiplayer_authority())])
	
	if is_multiplayer_authority():
		ui.display_chat_message("true auth, proper exit")
		control_ended.emit()
		camera.current = false
		using_player.camera.current = true
		using_player.active = true
	else:
		ui.display_chat_message("no auth, doing nothing")
	
	using_player.show()
	#using_player.reparent(get_tree().get_root())
	remote_path = ""
	using_player = null
