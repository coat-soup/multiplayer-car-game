extends Control

class_name UIManager

@onready var lobby_id_text_field: TextEdit = $NetworkPanel/LobbyIDTextField
@onready var interact_text: Label = $HUD/InteractText
@onready var chat_box: Label = $HUD/ChatBox

@onready var host_steam: Button = $NetworkPanel/HostSteam
@onready var host_local: Button = $NetworkPanel/HostLocal
@onready var join: Button = $NetworkPanel/Join
@onready var health_bar: ProgressBar = $HUD/HealthBar

@onready var ammo_counter: Label = $AmmoCounter

@onready var virtual_joystick: Control = $HUD/VirtualJoystick

@onready var hitmarker: TextureRect = $HUD/CrosshairHolder/Hitmarker

var chats : Array[String] = []

@export var network_manager : NetworkManager

@onready var mission_title_label: Label = $HUD/MissionPanel/MissionTitleLabel
@onready var mission_objectives_label: Label = $HUD/MissionPanel/MissionObjectivesLabel

@onready var radar_targetting: Control = $HUD/RadarTargetting
@onready var radar_target_name: Label = $HUD/RadarTargetting/TargetName
@onready var lead_pip: TextureRect = $HUD/RadarTargetting/LeadPip


var prompt_time_remaining := 0.0


func _ready():
	host_steam.pressed.connect(network_manager._on_host_pressed)
	host_local.pressed.connect(network_manager._on_host_local_pressed)
	join.pressed.connect(network_manager._on_join_pressed)


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1: visible = !visible


func _process(delta: float) -> void:
	if prompt_time_remaining > 0:
		prompt_time_remaining -= delta
		if prompt_time_remaining <= 0:
			interact_text.text = ""


func toggle_network_menu(value : bool):
	$NetworkPanel.visible = value


func get_lobby_id() -> String:
	return lobby_id_text_field.text


func set_interact_text(text: String = "", prefix_key := false):
	if prompt_time_remaining > 0: return
	var prefix = InputMap.action_get_events("interact")[0].as_text().split(" ")[0]
	interact_text.text = (("["+prefix+"] ") if prefix_key else "") + text


func display_prompt(prompt: String, time := 2.0):
	interact_text.text = prompt
	prompt_time_remaining = time


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


func update_ammo_counter(ammo : int, max_ammo : int):
	ammo_counter.text = str(ammo) + "|" + str(max_ammo)


func hide_ammo_counter():
	ammo_counter.text = ""


func flash_hitmarker():
	display_chat_message("Hit")
	hitmarker.visible = true
	await get_tree().create_timer(0.1).timeout
	hitmarker.visible = false


func display_mission(mission : Mission):
	mission_title_label.text = mission.title
	mission_objectives_label.text = ""
	for objective in mission.objectives:
		mission_objectives_label.text += objective.description_text + "\n"
	display_chat_message("New mission: " + str(mission.title))


func display_mission_completed(_mission : Mission):
	mission_objectives_label.text = "Completed"


func start_target_lock(signature : RadarSignature, show_pip : bool):
	radar_targetting.visible = true
	lead_pip.visible = show_pip
	radar_target_name.text = signature.signature_name


func end_target_lock():
	radar_targetting.visible = false
	radar_target_name.text = ""


func update_pip_position(target_position : Vector3, camera : Camera3D):
	lead_pip.position = camera.unproject_position(target_position) - Vector2(20,20)
