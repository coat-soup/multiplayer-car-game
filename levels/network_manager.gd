extends Node

class_name NetworkManager

@export var ui : UIManager

const PLAYER = preload("res://player/player.tscn")

var lobby_id = 0
var steam_peer = SteamMultiplayerPeer.new()

const PORT = 6969
var enet_peer : ENetMultiplayerPeer
const LOCAL_DEBUG := true


func _ready() -> void:
	OS.set_environment("SteamAppID", str(480))
	OS.set_environment("SteamGameID", str(480))
	Steam.steamInitEx()
	
	steam_peer.lobby_created.connect(_on_lobby_created)
	
	if LOCAL_DEBUG:
		enet_peer = ENetMultiplayerPeer.new()


func _process(_delta: float) -> void:
	Steam.run_callbacks()


func _on_host_pressed() -> void:
	steam_peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_PUBLIC)
	multiplayer.multiplayer_peer = steam_peer
	
	if LOCAL_DEBUG:
		enet_peer.create_server(PORT)
		multiplayer.multiplayer_peer = enet_peer
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	#upnp_setup()
	
	$Camera3D.queue_free()
	add_player(multiplayer.get_unique_id())
	ui.toggle_network_menu(false)


func _on_join_pressed() -> void:
	if not LOCAL_DEBUG:
		steam_peer.connect_lobby(ui.get_lobby_id())
		multiplayer.multiplayer_peer = steam_peer
	else:
		enet_peer.create_client("localhost", PORT)
		multiplayer.multiplayer_peer = enet_peer
	
	$Camera3D.queue_free()
	ui.toggle_network_menu(false)
	

func _on_lobby_created(connected, id):
	if connected:
		lobby_id = id
		Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName()+"'s lobby"))
		Steam.setLobbyJoinable(id, true)
		print("Lobby created! ID: %s" % id)


func add_player(peer_id):
	var player = PLAYER.instantiate()
	player.name = str(peer_id)
	print("playername: " + player.name)
	get_owner().add_child(player)


func remove_player(peer_id):
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player.name == str(peer_id):
			player.queue_free()
