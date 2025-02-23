extends Control

class_name UIManager

@onready var lobby_id_text_field: TextEdit = $VBoxContainer/LobbyIDTextField

func toggle_network_menu(value : bool):
	$VBoxContainer.visible = value

func get_lobby_id() -> int:
	return int(lobby_id_text_field.text)
