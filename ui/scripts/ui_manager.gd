extends Control

class_name UIManager

@onready var lobby_id_text_field: TextEdit = $NetworkPanel/ButtonHolder/LobbyIDTextField
@onready var interact_text: Label = $HUD/InteractText
@onready var chat_box: Label = $HUD/ChatBox
@onready var chat_anim: AnimationPlayer = $HUD/ChatBox/AnimationPlayer

@onready var interact_info_panel: Control = $HUD/InteractInfoPanel
@onready var interact_outline_bg: NinePatchRect = $HUD/InteractInfoPanel/InteractOutlineBG
@onready var interact_outline: NinePatchRect = $HUD/InteractInfoPanel/InteractOutline
@onready var interact_name_label: Label = $HUD/InteractInfoPanel/InteractOutline/NameLabel
@onready var interact_action_label: Label = $HUD/InteractInfoPanel/InteractOutline/ActionLabel


@onready var host_steam: Button = $NetworkPanel/ButtonHolder/HostSteam
@onready var host_local: Button = $NetworkPanel/ButtonHolder/HostLocal
@onready var join: Button = $NetworkPanel/ButtonHolder/Join
@onready var lobby_list_holder: VBoxContainer = $NetworkPanel/LobbyListHolder
@onready var refresh_lobbies: Button = $NetworkPanel/RefreshLobbies


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
@onready var target_outline: NinePatchRect = $HUD/RadarTargetting/TargetOutline


@onready var mounted_weapon_container: VBoxContainer = $MountedWeaponPanel/VBoxContainer
@onready var turret_power_panel: Control = $TurretPowerPanel
@onready var turret_capacitor_label: RichTextLabel = $TurretPowerPanel/CapacitorNumberLabel
@onready var power_warning: RichTextLabel = $"TurretPowerPanel/Power Warning"
@onready var mounted_ammo_panel: Control = $MountedWeaponAmmoPanel
@onready var mounted_ammo_container: Control = $MountedWeaponAmmoPanel/VBoxContainer
@onready var ammo_warning: RichTextLabel = $"MountedWeaponAmmoPanel/Ammo Warning"


@onready var hotbar: HBoxContainer = $HUD/Inventory/Hotbar
@onready var inventory_panel_holder: Control = $HUD/Inventory/InventoryPanelHolder
@onready var dragged_icon_holder: Control = $HUD/Inventory/DraggedIconHolder

var prompt_time_remaining := 0.0
var chat_fade_timer : Timer

@onready var character_panel: CharacterCustomisationPanelManager = $NetworkPanel/CharacterPanel


func _ready():
	host_steam.pressed.connect(network_manager._on_host_pressed)
	host_local.pressed.connect(network_manager._on_host_local_pressed)
	join.pressed.connect(network_manager._on_join_pressed)
	
	chat_fade_timer = Timer.new()
	add_child(chat_fade_timer)
	chat_fade_timer.timeout.connect(fade_chat)
	
	refresh_lobbies.pressed.connect(build_lobby_list)
	build_lobby_list()


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


func toggle_interact_panel(value: bool):
	interact_info_panel.visible = value


func update_interact_panel(name_text : String, prompts : String, pos : Vector2, size : Vector2):
	interact_name_label.text = name_text
	interact_action_label.text = prompts
	
	interact_outline.global_position = pos
	interact_outline.size = size
	interact_outline_bg.global_position = pos
	interact_outline_bg.size = size


func set_interact_text(text: String = "", prefix_key := false):
	if prompt_time_remaining > 0: return
	var prefix = InputMap.action_get_events("interact")[0].as_text().split(" ")[0]
	interact_text.text = (("["+prefix+"] ") if prefix_key else "") + text


func display_prompt(prompt: String, time := 2.0):
	interact_text.text = prompt
	prompt_time_remaining = time


@rpc("any_peer", "call_local")
func display_chat_message(message : String):
	chat_box.modulate = Color.WHITE
	chat_fade_timer.stop()
	chat_fade_timer.start(5.0)
	
	chats.append("[Server]: " + message)
	if chats.size() > 10:
		chats.remove_at(0)
	
	chat_box.text = ""
	for chat in chats:
		chat_box.text += "\n" + chat


func fade_chat():
	chat_anim.play("chat_fade")


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


func flash_hitmarker(dead : bool = false):
	display_chat_message("Hit")
	hitmarker.modulate = Color.ORANGE if dead else Color.hex(0xffffff64)
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
	radar_target_name.text = "TARGET: " + signature.signature_name


func end_target_lock():
	radar_targetting.visible = false
	radar_target_name.text = ""


func update_target_lock(signature : RadarSignature, target_position : Vector3, camera : Camera3D):
	lead_pip.global_position = camera.unproject_position(target_position) - Vector2(20,20)
	var mesh = (signature.get_node("RadarMarker/Visual") as CSGSphere3D).get_meshes()[1] as Mesh
	var aabb_calc = AABBHelper.get_2d_bounds_from_aabb(signature, mesh.get_aabb(), camera)
	target_outline.size = aabb_calc[1]
	target_outline.global_position = aabb_calc[0] #camera.unproject_position(signature.global_position) - aabb_calc[1]/2
	radar_target_name.text = "TARGET: " + signature.signature_name + "\n" + str(round(camera.global_position.distance_to(target_position))) + "m"
	
	var in_view = (-camera.global_basis.z).dot((target_position - camera.global_position).normalized()) > 0
	lead_pip.visible = in_view
	target_outline.visible = in_view


func setup_mounted_weapons(controller : MountedWeaponsController):
	for child in mounted_weapon_container.get_children():
		child.queue_free()
	
	for weapon in controller.weapons:
		var weapon_info = preload("res://ui/widgets/mounted_weapon_hud_widget.tscn").instantiate()
		mounted_weapon_container.add_child(weapon_info)
		
		(weapon_info.get_node("NameLabel") as Label).text = weapon.component_name
		
		weapon.heat_manager.heat_changed.connect(update_mounted_weapons.bind(controller))

	
	update_mounted_weapons(controller)


func unsetup_mounted_weapons(controller : MountedWeaponsController):
	for child in mounted_weapon_container.get_children():
		child.queue_free()
	
	for weapon in controller.weapons:
		weapon.heat_manager.heat_changed.disconnect(update_mounted_weapons)


func update_mounted_weapons(controller : MountedWeaponsController):
	for i in range(len(controller.weapons)):
		(mounted_weapon_container.get_child(i).get_node("ProgressBar") as ProgressBar).value = controller.weapons[i].heat_manager.get_heat_ratio()


func setup_mounted_ammo(controller : MountedWeaponsController):
	for crate in controller.ammo_crates:
		var widget = preload("res://ui/widgets/mounted_ammo_hud_widget.tscn").instantiate()
		mounted_ammo_container.add_child(widget)
		
		widget.get_node("NameLabel").text = crate.get_ammo_type_string() + " ammo"
		widget.get_node("CountLabel").text = str(crate.cur_ammo)
		widget.get_node("ProgressBar").value = float(crate.cur_ammo) / float(crate.max_ammo)
	ammo_warning.visible = controller.check_needs_ammo()
	
	controller.turret_station.ammo_ammount_changed.connect(update_mounted_ammo.bind(controller))
	
	#update_mounted_ammo(controller)
	mounted_ammo_panel.visible = true


func unsetup_mounted_ammo(controller : MountedWeaponsController):
	for child in mounted_ammo_container.get_children():
		child.queue_free()
	
	controller.turret_station.ammo_ammount_changed.disconnect(update_mounted_ammo)
	
	mounted_ammo_panel.visible = false


func update_mounted_ammo(controller : MountedWeaponsController):
	for i in range(len(controller.ammo_crates)):
		mounted_ammo_container.get_child(i).get_node("CountLabel").text = str(controller.ammo_crates[i].cur_ammo)
		mounted_ammo_container.get_child(i).get_node("ProgressBar").value = float(controller.ammo_crates[i].cur_ammo) / float(controller.ammo_crates[i].max_ammo)
	ammo_warning.visible = controller.check_needs_ammo()


func toggle_turet_power_panel(value: bool):
	turret_power_panel.visible = value


func update_turret_capacitors(cur: int, max: int):
	turret_capacitor_label.text = str(cur) + "/" + str(max)


func toggle_power_warning(value: bool):
	power_warning.visible = value


func select_hotbar_slot(slot : int):
	for i in range(hotbar.get_child_count()):
		hotbar.get_child(i).get_node("Select").visible = i == slot


func place_item_in_slot(item : Holdable, slot : int):
	var icon = item.inventory_icon
	icon.visible = true
	icon.reparent(hotbar.get_child(slot))
	icon.position = Vector2.ZERO


func remove_item_from_slot(item : Holdable, slot : int):
	var icon = hotbar.get_child(slot).get_child(1)
	if icon: icon.queue_free()


func open_inventory_panel(inventory : ItemInventory):
	inventory.inventory_ui_panel.reparent(inventory_panel_holder)
	var bg : ColorRect = inventory.inventory_ui_panel.get_node("Background") as ColorRect
	inventory.inventory_ui_panel.position = Vector2(-bg.size.x, -bg.size.y/2)
	inventory.inventory_ui_panel.visible = true


func close_inventory_panel(inventory : ItemInventory):
	inventory.inventory_ui_panel.visible = false
	inventory.inventory_ui_panel.reparent(inventory)


func build_lobby_list():
	for child in lobby_list_holder.get_children():
		child.queue_free()
	
	var data = network_manager.get_friends_in_lobbies()
	for steam_id in data:
		var lobby_entry = preload("res://ui/widgets/lobby_entry.tscn").instantiate()
		lobby_list_holder.add_child(lobby_entry)
		
		lobby_entry.get_node("NameLabel").text = Steam.getFriendPersonaName(steam_id)
		
		var alt_m : String
		match data[steam_id]:
			-1: alt_m = "Not in game"
			-2: alt_m = "In menus"
		
		if data[steam_id] == -1 or data[steam_id] == -2:
			lobby_entry.get_node("PlayerCountLabel").text = alt_m
			lobby_entry.get_node("PingLabel").visible = false
			lobby_entry.get_node("JoinButton").visible = false
			continue
		
		lobby_entry.get_node("PlayerCountLabel").text = str(Steam.getNumLobbyMembers(data[steam_id])) + "/16 PLAYERS"
		lobby_entry.get_node("PingLabel").text = ""
		lobby_entry.get_node("JoinButton").pressed.connect(on_friend_lobby_join_pressed.bind(steam_id, data[steam_id]))



func on_friend_lobby_join_pressed(steam_id: int, lobby_id: int) -> bool:
	var game_info: Dictionary = Steam.getFriendGamePlayed(steam_id)

	if game_info.is_empty():
		build_lobby_list()
		return false

	# They are in a game
	var app_id: int = game_info.id
	var lobby = game_info.lobby

	# Return true if they are in the same game and have the same lobby_id
	if app_id == Steam.getAppID() and lobby is int and lobby == lobby_id:
		network_manager.join_lobby_by_id(lobby_id)
		return true
	
	return false
