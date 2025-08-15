extends Control

class_name UIManager

@onready var lobby_id_text_field: TextEdit = $NetworkPanel/LobbyIDTextField
@onready var interact_text: Label = $HUD/InteractText
@onready var chat_box: Label = $HUD/ChatBox
@onready var chat_anim: AnimationPlayer = $HUD/ChatBox/AnimationPlayer

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


func _ready():
	host_steam.pressed.connect(network_manager._on_host_pressed)
	host_local.pressed.connect(network_manager._on_host_local_pressed)
	join.pressed.connect(network_manager._on_join_pressed)
	
	chat_fade_timer = Timer.new()
	add_child(chat_fade_timer)
	chat_fade_timer.timeout.connect(fade_chat)


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


func update_pip_position(target_position : Vector3, camera : Camera3D):
	lead_pip.position = camera.unproject_position(target_position) - Vector2(20,20)


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
