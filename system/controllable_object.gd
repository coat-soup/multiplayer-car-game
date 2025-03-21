extends RemoteTransform3D

class_name Controllable

signal control_started
signal control_ended

@export var camera : Camera3D
@export var interactable : Interactable

@export var synchronizer : MultiplayerSynchronizer

var using_player : Player = null

var ui : UIManager

@onready var root_owner : Node = get_owner()


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
	if not using_player: return
	ui.display_chat_message("%s (auth: %s) exiting %s" % [using_player.name, str(using_player.is_multiplayer_authority()), root_owner.name])
	
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
