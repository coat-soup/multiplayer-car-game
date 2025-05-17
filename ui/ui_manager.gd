extends Control

class_name UIManager

@onready var lobby_id_text_field: TextEdit = $VBoxContainer/LobbyIDTextField
@onready var interact_text: Label = $HUD/InteractText
@onready var chat_box: Label = $HUD/ChatBox

@onready var host_steam: Button = $VBoxContainer/HostSteam
@onready var host_local: Button = $VBoxContainer/HostLocal
@onready var join: Button = $VBoxContainer/Join
@onready var health_bar: ProgressBar = $HUD/HealthBar

@onready var virtual_joystick: Control = $HUD/VirtualJoystick

var chats : Array[String] = []

@export var network_manager : NetworkManager

var prompting := false


func _ready():
	host_steam.pressed.connect(network_manager._on_host_pressed)
	host_local.pressed.connect(network_manager._on_host_local_pressed)
	join.pressed.connect(network_manager._on_join_pressed)


func toggle_network_menu(value : bool):
	$VBoxContainer.visible = value


func get_lobby_id() -> String:
	return lobby_id_text_field.text


func set_interact_text(text: String = "", prefix_key := false):
	if prompting: return
	var prefix = InputMap.action_get_events("interact")[0].as_text().split(" ")[0]
	interact_text.text = (("["+prefix+"] ") if prefix_key else "") + text


func display_prompt(prompt: String, time := 2.0):
	interact_text.text = prompt
	prompting = true
	await get_tree().create_timer(time).timeout
	if interact_text.text == prompt:
		interact_text.text = ""
		prompting = false


@rpc("any_peer", "call_local")
func display_chat_message(message : String):
	chats.append(message)
	if chats.size() > 10:
		chats.remove_at(0)
	
	chat_box.text = ""
	for chat in chats:
		chat_box.text += "\n" + chat


func toggle_virtual_joystick(value: bool):
	virtual_joystick.visible = value


func update_virtual_joystick(value: Vector2):
	virtual_joystick.get_child(0).position = value * 100
	(virtual_joystick.get_child(1) as Line2D).set_point_position(1, value * 100)


func update_health_bar(value: float):
	health_bar.value = value
