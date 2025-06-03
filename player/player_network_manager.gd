extends Node

class_name PlayerNetworkManager

@export var third_person_models: Array[Node3D]
@export var username_label: Label3D
var username: String = ""

@export var player : Player

var network_manager : NetworkManager
var ui : UIManager


func _enter_tree() -> void:
	pass
	#player.set_multiplayer_authority(str(get_owner().name).to_int())


func _ready() -> void:
	network_manager = get_tree().get_first_node_in_group("network manager") as NetworkManager
	assert(network_manager, "Network manager not found!!!")
	ui = get_tree().get_first_node_in_group("ui") as UIManager
	
	# Get the local player's Steam ID and username
	var steam_user_id = Steam.getSteamID()
	var steam_user_name = Steam.getFriendPersonaName(steam_user_id)
	username = steam_user_name
	
	#username_label.text = steam_user_name
	
	if is_multiplayer_authority():
		for m in third_person_models:
			m.visible = false
	
	await get_tree().create_timer(1.0).timeout
	request_sync_username.rpc_id(str(get_owner().name).to_int())
	#try_sync()

func try_sync(n := 0):
	if multiplayer.has_multiplayer_peer() and multiplayer.multiplayer_peer.get_connection_status() == multiplayer.multiplayer_peer.CONNECTION_CONNECTED:
		request_sync_username.rpc_id(str(get_owner().name).to_int())
		print("Synching username")
	elif n < 20:
		await get_tree().create_timer(0.2).timeout
		try_sync(n + 1)
	else:
		if ui:
			ui.display_chat_message("Connection failed")
			push_error("Connection failed")


@rpc("any_peer", "call_local")
func sync_username(new_username: String) -> void:
	username = new_username
	username_label.text = username
	if ui and false:
		ui.display_chat_message("username synced to " + username)


@rpc("any_peer", "call_local")
func request_sync_username():
	if is_multiplayer_authority():
		sync_username.rpc(username)
		if ui and false:
			ui.display_chat_message("username sync request received")
