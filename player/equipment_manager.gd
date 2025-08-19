extends Node3D
class_name EquipmentManager

signal equipped_item
signal dropped_item

@export var player : Player
@export var num_slots := 8
var items : Array[Holdable] = []
var cur_slot := 0
var remote_transforms : Array[RemoteTransform3D]
@onready var ui : UIManager = get_tree().get_first_node_in_group("ui") as UIManager


func _ready() -> void:
	for i in range(num_slots):
		items.append(null)
		var rt = RemoteTransform3D.new()
		add_child(rt)
		remote_transforms.append(rt)
	
	if is_multiplayer_authority():
		ui.select_hotbar_slot(0)


func _input(event: InputEvent) -> void:
	if not player.is_multiplayer_authority():
		return
	
	if event.is_action_pressed("drop item"):
		drop_equipment.rpc(cur_slot)
	
	var scroll_dir = int(Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN)) - int(Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP))
	if scroll_dir != 0 and not (items[cur_slot] and (items[cur_slot] as TractorTool) and (items[cur_slot] as TractorTool).beam.target):
		swap_to_item(posmod((cur_slot + scroll_dir), items.size()))


func equip_item(equipment: Holdable, specific_slot = -1, try_combine : bool = true):
	var slot = specific_slot if specific_slot != -1 else (first_available_slot() if items[cur_slot] else cur_slot)
	
	#if items[slot]:
		#drop_equipment.rpc(slot)
		#print("dropping", items[slot])
	
	print("equipping ", equipment)
	#items[slot] = equipment
	#equipment.held_by_auth = true
	
	handle_equip.rpc(equipment.get_path(), slot, try_combine)


@rpc("any_peer", "call_local")
func handle_equip(scene_path : NodePath, slot : int, try_combine : bool = true):
	var equipment = get_tree().root.get_node(scene_path) as Holdable
	if equipment:
		var item = equipment
		
		if try_combine:
			for othertem in items:
				var s = ItemInventory.stackable_amount(item, othertem)
				if s > 0 and item.items_in_stack > 0:
					othertem.change_stack_size(s) # no rpc bc in rpc function
					item.change_stack_size(-s)
					item.inventory_icon.visible = false
			
			if item.items_in_stack <= 0:
				item.destroy_item()
				return
		
		if items[slot]:
			if player.is_multiplayer_authority(): ui.display_prompt("Inventory full")
			return
		
		if player.is_multiplayer_authority(): ui.place_item_in_slot(item, slot)
		
		item.inventory_icon.inventory_item.inventory_type = 1
		item.inventory_icon.inventory_item.inventory_slot = slot
		print("setting ", item.inventory_icon.inventory_item, " slot to ", slot)
		
		if not item.physics_dupe.is_inside_tree():
			await item.physics_dupe.tree_entered
		
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
		
		equipment.on_picked_up()
		
		if slot != cur_slot:
			equipment.visible = false
		else:
			equipment.visible = true
			equipment.held_by_auth = player.is_multiplayer_authority()
			equipment.on_held()
		
		
		item.disable_physics()
		
		equipped_item.emit(equipment)
		
	else:
		print("could not find equipment")


@rpc("any_peer", "call_local")
func drop_equipment(slot: int):
	var item := items[slot]
	if item:
		#if player.is_multiplayer_authority(): ui.remove_item_from_slot(item, slot)
		
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
		item.on_dropped(player)
		items[slot] = null
		
		dropped_item.emit(item)


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
		items[cur_slot].on_put_away()
		items[cur_slot].held_by_auth = false
	
	cur_slot = slot
	sync_cur_slot.rpc(slot)
	
	if items[cur_slot]:
		toggle_item_visibility.rpc(cur_slot, true)
		items[cur_slot].held_by_auth = player.is_multiplayer_authority()
		items[cur_slot].on_held()
	
	ui.select_hotbar_slot(cur_slot)


@rpc("any_peer", "call_local")
func sync_cur_slot(slot : int):
	cur_slot = slot
