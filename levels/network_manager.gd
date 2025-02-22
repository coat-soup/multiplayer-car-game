extends Node

@export var ui : UIManager

const PLAYER = preload("res://player/player.tscn")
const PORT = 6969
var enet_peer = ENetMultiplayerPeer.new()


func _on_host_pressed() -> void:
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	
	#upnp_setup()
	
	$Camera3D.queue_free()
	add_player(multiplayer.get_unique_id())
	ui.toggle_network_menu(false)


func _on_join_pressed() -> void:
	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer
	
	$Camera3D.queue_free()
	ui.toggle_network_menu(false)
	
	
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

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP discover failed! Error: %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), "UPNP invalid gateway! Gateway: %s" % upnp.get_gateway())
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, "UPNP port mapping failed! Error: %s" % map_result)
	
	print("Success! Join address: %s" % upnp.query_external_address())
