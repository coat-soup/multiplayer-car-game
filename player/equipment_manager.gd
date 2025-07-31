extends Node3D

class_name EquipmentManager

@export var player : Player
@export var num_slots := 2
var items : Array[Equipment] = []
var cur_slot := 0
var remote_transforms : Array[RemoteTransform3D]


func _ready() -> void:
	for i in range(num_slots):
		items.append(null)
		var rt = RemoteTransform3D.new()
		add_child(rt)
		remote_transforms.append(rt)


func _input(event: InputEvent) -> void:
	if not player.is_multiplayer_authority():
		return
	
	if event.is_action_pressed("drop item"):
		drop_equipment.rpc(cur_slot)
	
	var scroll_dir = int(Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN)) - int(Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP))
	if scroll_dir != 0 and not (items[cur_slot] and (items[cur_slot] as TractorTool) and (items[cur_slot] as TractorTool).target):
		swap_to_item((cur_slot + scroll_dir) % items.size())


func equip_item(equipment: Equipment):
	var slot = first_available_slot() if items[cur_slot] else cur_slot
	
	if items[slot]:
		drop_equipment.rpc(slot)
		print("dropping", items[slot])
	
	print("equipping ", equipment)
	items[slot] = equipment
	equipment.held_by_auth = true
	
	handle_equip.rpc(equipment.get_path(), slot)


@rpc("any_peer", "call_local")
func handle_equip(scene_path : NodePath, slot : int):
	var equipment = get_tree().root.get_node(scene_path) as Equipment
	if equipment:
		var item = equipment
		
		
		# item placement
		item.global_position = global_position
		item.global_rotation = global_rotation
		if item.on_ship:
			item.physics_dupe.position = item.position
			item.physics_dupe.rotation = item.rotation
		else:
			item.physics_dupe.global_position = item.global_position
			item.physics_dupe.global_rotation = item.global_rotation
		
		# remote transform
		item.controlling_RT = remote_transforms[slot]
		item.controlling_RT.remote_path = scene_path
		item.controlling_RT.global_position = item.global_position
		item.controlling_RT.global_rotation = item.global_rotation
		
		item.snap_indicator.visible = false
		
		
		equipment.equipped = true
		equipment.interactable.active = false
		items[slot] = equipment
		
		
		equipment.held_player = player
		equipment.prev_parent = player # for transform
		equipment.position = Vector3.ZERO
		equipment.rotation = Vector3.ZERO
		
		equipment.picked_up.emit()
		
		if slot != cur_slot:
			equipment.visible = false
		else:
			equipment.on_held()
		
		
		item.disable_physics()
		
	else:
		print("could not find equipment")


@rpc("any_peer", "call_local")
func drop_equipment(slot: int):
	var item := items[slot]
	if item:
		item.enable_physics()
		
		remote_transforms[slot].remote_path = ""
		item.controlling_RT = null
		
		
		if item.on_ship:
			item.physics_dupe.position = item.position
			item.physics_dupe.rotation = item.rotation
		else:
			item.physics_dupe.global_position = item.global_position
			item.physics_dupe.global_rotation = item.global_rotation
		
		
		
		item.held_player = null
		item.equipped = false
		item.held_by_auth = false
		item.visible = true
		item.interactable.active = true
		#items[slot].raycast_position()
		if slot == cur_slot:
			item.on_unheld()
		item.on_dropped()
		items[slot] = null


func first_available_slot() -> int:
	for x in range(items.size()):
		if not items[x]:
			return x
	return cur_slot


@rpc("any_peer", "call_local")
func toggle_item_visibility(slot : int, value : bool):
	if items[slot]:
		items[slot].visible = value


func swap_to_item(slot):
	if items[cur_slot]:
		toggle_item_visibility.rpc(cur_slot, false)
		items[cur_slot].on_unheld()
		items[cur_slot].held_by_auth = false
	
	cur_slot = slot
	sync_cur_slot.rpc(slot)
	
	if items[cur_slot]:
		toggle_item_visibility.rpc(cur_slot, true)
		items[cur_slot].held_by_auth = true
		items[cur_slot].on_held()


@rpc("any_peer", "call_local")
func sync_cur_slot(slot : int):
	cur_slot = slot
