extends Node
class_name NetworkManager

signal host_started

@onready var ui : UIManager = get_tree().get_first_node_in_group("ui")

const PLAYER = preload("res://player/player.tscn")

var lobby_id = 0
var steam_peer = SteamMultiplayerPeer.new()

const PORT = 6969
var enet_peer : ENetMultiplayerPeer
var LOCAL_DEBUG := true

const ALPHABET := "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

@export var spawn_position := Vector3.ZERO
@export var ship : ShipManager
@export var level_manager : LevelManager

const APP_ID = 2932440


func _ready() -> void:
	OS.set_environment("SteamAppID", str(APP_ID))
	OS.set_environment("SteamGameID", str(APP_ID))
	Steam.steamInitEx()
	
	steam_peer.lobby_created.connect(_on_lobby_created)
	
	enet_peer = ENetMultiplayerPeer.new()


func _process(_delta: float) -> void:
	Steam.run_callbacks()


func _on_host_pressed() -> void:
	steam_peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_PUBLIC)
	multiplayer.multiplayer_peer = steam_peer
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	if level_manager: level_manager.setup(multiplayer)
	
	$Camera3D.queue_free()
	add_player(multiplayer.get_unique_id())
	ui.toggle_network_menu(false)
	
	host_started.emit()


func _on_host_local_pressed() -> void:
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	if level_manager: level_manager.setup(multiplayer)
	
	#upnp_setup()
	
	$Camera3D.queue_free()
	add_player(multiplayer.get_unique_id())
	ui.toggle_network_menu(false)
	
	host_started.emit()


func _on_join_pressed() -> void:
	if ui.get_lobby_id() != "":
		steam_peer.connect_lobby(int(parse_lobby_code(ui.get_lobby_id())))
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
		print("Lobby created! ID: %s" % codify_lobby_id(id))
		ui.display_chat_message("Lobby created! ID: %s" % codify_lobby_id(id))
 

func add_player(peer_id):
	var player = PLAYER.instantiate()
	player.name = str(peer_id)
	print("playername: " + player.name)
	add_child(player)


func remove_player(peer_id):
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player.name == str(peer_id):
			player.queue_free()


static func codify_lobby_id(id: int) -> String:
	var code = ""
	var num : int = id
	
	while num > 0:
		var remainder = num % ALPHABET.length()
		code = ALPHABET[remainder] + code
		@warning_ignore("integer_division")
		num = num / ALPHABET.length()
	
	return code


static func parse_lobby_code(code: String) -> int:
	code = code.to_upper()
	var id = 0
	for i in range(code.length()):
		var c = code[i]
		var value = ALPHABET.find(c)
		id = id * ALPHABET.length() + value
	
	return id
