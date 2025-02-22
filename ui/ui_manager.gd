extends Control

class_name UIManager

@onready var lobby_id_text_field: TextEdit = $VBoxContainer/LobbyIDTextField
@onready var interact_text: Label = $HUD/InteractText
@onready var chat_box: Label = $HUD/ChatBox

var chats : Array[String] = []

func toggle_network_menu(value : bool):
	$VBoxContainer.visible = value


func get_lobby_id() -> int:
	return int(lobby_id_text_field.text)


func set_interact_text(text: String = "", prefix_key := false):
	var prefix = InputMap.action_get_events("interact")[0].as_text().split(" ")[0]
	interact_text.text = (("["+prefix+"] ") if prefix_key else "") + text

@rpc("any_peer", "call_local")
func display_chat_message(message : String):
	chats.append(message)
	if chats.size() > 10:
		chats.remove_at(0)
	
	chat_box.text = ""
	for chat in chats:
		chat_box.text += "\n" + chat
