extends Node
class_name ItemInventory

@export var display_name : String = "Inventory"
@export var dimensions : Vector2i = Vector2i(1,1)

var items : Array[InventoryItemData]

@onready var ui : UIManager = get_tree().get_first_node_in_group("ui") as UIManager

var opened_locally : bool = false
var using_player : Player
@export var interactable : Interactable

var inventory_ui_panel : InventoryUIPanelManager
const INVENTORY_UI_PANEL = preload("res://ui/widgets/inventory_ui_panel.tscn")

var currently_dragging : InventoryItemIconManager

@onready var level_manager = (get_tree().get_first_node_in_group("network manager") as NetworkManager).level_manager


func _ready() -> void:
	interactable.interacted.connect(on_interacted)
	
	inventory_ui_panel = INVENTORY_UI_PANEL.instantiate() as InventoryUIPanelManager
	inventory_ui_panel.inventory = self
	add_child(inventory_ui_panel)
	inventory_ui_panel.rebuild()
	
	inventory_ui_panel.visible = false
	
	for x in range(dimensions.x):
		for y in range(dimensions.y):
			items.append(null)


func _input(event: InputEvent) -> void:
	if opened_locally and event.is_action_pressed("interact"):
		close_inventory.rpc()


func on_interacted(source : Node):
	request_open_by_player.rpc(source.get_path())


@rpc("any_peer", "call_local")
func request_open_by_player(player_path : String):
	var accepted = using_player == null
	if accepted:
		using_player = get_tree().get_root().get_node(player_path) as Player
		if not using_player:
			print("Opening player not found for ", get_parent().name, "inventory (path: ", player_path, ")")
	if multiplayer.is_server(): receive_open_response.rpc_id(multiplayer.get_remote_sender_id(), accepted, player_path)


@rpc("any_peer", "call_local")
func receive_open_response(accepted : bool, player_path : String):
	if accepted:
		using_player = get_tree().get_root().get_node(player_path) as Player
		open_inventory_local()
	else:
		print("TELLING THEM NO")
		ui.display_prompt("In use by other player")


@rpc("any_peer", "call_local")
func close_inventory():
	if opened_locally:
		close_inventory_local()
	using_player = null


func open_inventory_local():
	ui.open_inventory_panel(self)
	interactable.active = false
	opened_locally = true
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	using_player.active = false
	
	using_player.equipment_manager.equipped_item.connect(on_new_equip)
	using_player.equipment_manager.dropped_item.connect(on_equipment_dropped)
	
	for item in using_player.equipment_manager.items:
		if not item: continue
		item.inventory_icon.started_drag.connect(on_drag_started.bind(item.inventory_icon))
		item.inventory_icon.ended_drag.connect(on_drag_ended.bind(item.inventory_icon))
		item.inventory_icon.stack_split.connect(on_stack_split.bind(item.inventory_icon))
	
	for item in items:
		if not item: continue
		item.ui_icon.visible = true
		item.ui_icon.started_drag.connect(on_drag_started.bind(item.ui_icon))
		item.ui_icon.ended_drag.connect(on_drag_ended.bind(item.ui_icon))
		item.ui_icon.stack_split.connect(on_stack_split.bind(item.ui_icon))


func close_inventory_local():
	ui.close_inventory_panel(self)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	using_player.active = true
	
	using_player.equipment_manager.equipped_item.disconnect(on_new_equip)
	using_player.equipment_manager.dropped_item.disconnect(on_equipment_dropped)
	
	for item in using_player.equipment_manager.items:
		if not item: continue
		item.inventory_icon.started_drag.disconnect(on_drag_started)
		item.inventory_icon.ended_drag.disconnect(on_drag_ended)
		item.inventory_icon.stack_split.disconnect(on_stack_split)
	
	for item in items:
		if not item: continue
		item.ui_icon.started_drag.disconnect(on_drag_started)
		item.ui_icon.ended_drag.disconnect(on_drag_ended)
		item.ui_icon.stack_split.disconnect(on_stack_split)
	
	if currently_dragging: currently_dragging.stop_dragging()
	
	opened_locally = false
	await get_tree().create_timer(0.2).timeout
	interactable.active = true


func on_new_equip(item : Holdable):
	item.inventory_icon.started_drag.connect(on_drag_started.bind(item.inventory_icon))
	item.inventory_icon.ended_drag.connect(on_drag_ended.bind(item.inventory_icon))
	item.inventory_icon.stack_split.connect(on_stack_split.bind(item.inventory_icon))


func on_equipment_dropped(item : Holdable):
	item.inventory_icon.started_drag.disconnect(on_drag_started)
	item.inventory_icon.ended_drag.disconnect(on_drag_ended)
	item.inventory_icon.stack_split.disconnect(on_stack_split)


@rpc("any_peer", "call_local")
func set_item(item_path : String, slot : int, change_physics : bool = true):
	var item : Holdable = get_tree().get_root().get_node(item_path) as Holdable
	if item:
		items[slot] = InventoryItemData.new(item, self)
		inventory_ui_panel.put_icon_in_slot(items[slot].ui_icon, slot)
		items[slot].inventory_slot = slot
		items[slot].inventory_type = 0
		
		item.destroy_item()
		
		if using_player.is_multiplayer_authority():
			print("first s ", items[slot])
			items[slot].ui_icon.visible = true
			print("second s ", items[slot])
			items[slot].ui_icon.started_drag.connect(on_drag_started.bind(items[slot].ui_icon))
			items[slot].ui_icon.ended_drag.connect(on_drag_ended.bind(items[slot].ui_icon))
			items[slot].ui_icon.stack_split.connect(on_stack_split.bind(items[slot].ui_icon))


@rpc("any_peer", "call_local")
func swap_item_positions(a : int, b : int):
	var item_a = items[a]
	var item_b = items[b]
	
	items[a] = item_b
	if item_b:
		inventory_ui_panel.put_icon_in_slot(item_b.ui_icon, a)
		item_b.inventory_slot = a
	
	items[b] = item_a
	if item_a:
		inventory_ui_panel.put_icon_in_slot(item_a.ui_icon, b)
		item_a.inventory_slot = b


@rpc("any_peer", "call_local")
func drop_item(slot : int, spawn_outside : bool = true) -> Item:
	print("attempting to drop item at ", slot)
	var new_item : Holdable = level_manager.spawn_item_synced(items[slot].item_data.prefab_path, using_player.equipment_manager.global_position) if spawn_outside else null
	
	if new_item: new_item.override_stack_size.rpc(items[slot].items_in_stack)
	
	items[slot].ui_icon.queue_free()
	items[slot] = null
	return new_item


func on_drag_started(icon : InventoryItemIconManager):
	currently_dragging = icon


func on_drag_ended(icon : InventoryItemIconManager):
	var ending_point = get_hovering_slot()
	
	var stackable = stackable_amount(icon.inventory_item, items[ending_point.x] if ending_point.y == 1 else using_player.equipment_manager.items[ending_point.x])
	var stack_all = stackable == icon.inventory_item.items_in_stack
	
	return_icon(icon)
	
	if ending_point.y == -1:
		# return to prev slot
		if check_in_bounds(get_viewport().get_mouse_position(), ui.hotbar) or check_in_bounds(get_viewport().get_mouse_position(), inventory_ui_panel.background):
			return_icon(icon)
		
		else: # throw out
			if icon.inventory_item.inventory_type == 0:
				drop_item.rpc(icon.inventory_position)
			else:
				using_player.equipment_manager.drop_equipment.rpc(icon.inventory_position)
		
	elif ending_point.y == 0:
		if items.has(icon.inventory_item): # inventory to hotbar
			inventory_to_hotbar.rpc(icon.inventory_item.inventory_slot, ending_point.x)
			
		elif icon.inventory_item.inventory_type == 1: # hotbar to hotbar
			if icon.inventory_position == ending_point.x:
				return_icon(icon)
				return
			if stackable > 0:
				var item = using_player.equipment_manager.items[icon.inventory_item.inventory_slot]
				item.change_stack_size.rpc(-stackable)
				using_player.equipment_manager.items[ending_point.x].change_stack_size.rpc(stackable)
				return_icon(icon)
				if stack_all:
					using_player.equipment_manager.drop_equipment.rpc(icon.inventory_position)
					item.destroy_item.rpc()
			else:
				var prev_item = using_player.equipment_manager.items[ending_point.x]
				var new_item = using_player.equipment_manager.items[icon.inventory_item.inventory_slot]
				var old_slot = icon.inventory_position
				using_player.equipment_manager.drop_equipment.rpc(icon.inventory_position)
				if prev_item : using_player.equipment_manager.drop_equipment.rpc(ending_point.x)
				using_player.equipment_manager.equip_item(new_item, ending_point.x, false)
				if prev_item: using_player.equipment_manager.equip_item(prev_item, old_slot, false)
		
	elif ending_point.y == 1:
		if icon.inventory_item and items.has(icon.inventory_item):  # inventory to inventory
			if icon.inventory_position != ending_point.x:
				inventory_to_inventory.rpc(icon.inventory_item.inventory_slot, ending_point.x)
			
		elif icon.inventory_item.inventory_type == 1:  # hotbar to inventory
			hotbar_to_inventory.rpc(icon.inventory_item.inventory_slot, ending_point.x)
	
	currently_dragging = null


@rpc("any_peer", "call_local")
func inventory_to_hotbar(from : int, to : int):
	var hot_item = using_player.equipment_manager.items[to]
	var stackable = stackable_amount(items[from], hot_item)
	var stack_all = items[from] and stackable == items[from].items_in_stack
	
	if stackable > 0:
		hot_item.change_stack_size(stackable)
		items[from].change_stack_size(-stackable)
		if stack_all:
			drop_item(from, false)
	else:
		if hot_item:
			using_player.equipment_manager.drop_equipment(to)
			set_item(hot_item.get_path(), from)
		var new_item = drop_item(from)
		if new_item: using_player.equipment_manager.handle_equip.rpc(new_item.get_path(), to, false)


@rpc("any_peer", "call_local")
func hotbar_to_inventory(from : int, to : int):
	var item = using_player.equipment_manager.items[from]
	var stackable = stackable_amount(item, items[to])
	var stack_all = stackable == item.items_in_stack
	
	if stackable > 0:
		item.change_stack_size(-stackable)
		items[to].change_stack_size(stackable)
		if stack_all:
			using_player.equipment_manager.drop_equipment(from)
			item.destroy_item()
	else:
		using_player.equipment_manager.drop_equipment(from)
		if items[to] and multiplayer.is_server():
			var new_item = drop_item(to)
			if new_item: using_player.equipment_manager.handle_equip.rpc(new_item.get_path(), from, false)
		set_item(item.get_path(), to)


@rpc("any_peer", "call_local")
func inventory_to_inventory(from : int, to: int):
	var stackable = stackable_amount(items[from], items[to])
	var stack_all = stackable == items[from].items_in_stack
	
	if stackable > 0:
		items[from].change_stack_size(-stackable)
		items[to].change_stack_size(stackable)
		if stack_all:
			drop_item(from, false)
	else: swap_item_positions(from, to)


func on_stack_split(amount : int, icon : InventoryItemIconManager):
	var ending_point = get_hovering_slot()
	rpc_stack_split.rpc(amount, Vector2i(icon.inventory_item.inventory_slot, icon.inventory_item.inventory_type), ending_point)


@rpc("any_peer", "call_local")
func rpc_stack_split(amount, starting_point, ending_point):
	var from_item : InventoryItemData = items[starting_point.x] if starting_point.y == 0 else using_player.equipment_manager.items[starting_point.x].inventory_icon.inventory_item
	
	print(from_item.item_data.item_name, " splitting ", amount)
	
	var target_item = null if ending_point.y == -1 else (items[ending_point.x] if ending_point.y == 1 else using_player.equipment_manager.items[ending_point.x])
	var stackable = min(amount, stackable_amount(from_item, target_item))
	
	var from_item_maybe_actual_item = items[from_item.inventory_slot] if from_item.inventory_type == 0 else using_player.equipment_manager.items[starting_point.x]
	
	if target_item:
		target_item.change_stack_size(stackable)
		from_item_maybe_actual_item.change_stack_size(-stackable)
	else:
		from_item_maybe_actual_item.change_stack_size(-amount)
		if multiplayer.is_server():
			var new_item : Holdable = level_manager.spawn_item_synced(from_item.item_data.prefab_path, using_player.equipment_manager.global_position)
			new_item.override_stack_size.rpc(amount)
			
			if ending_point.y == 0: using_player.equipment_manager.equip_item(new_item, ending_point.x, false)
			elif ending_point.y == 1: set_item.rpc(new_item.get_path(), ending_point.x)


func return_icon(icon : InventoryItemIconManager):
	if icon.inventory_item.inventory_type == 0:
		icon.reparent(inventory_ui_panel.slot_container.get_child(icon.inventory_position))
		icon.position = Vector2.ZERO
	else:
		icon.reparent(ui.hotbar.get_child(icon.inventory_position))
		icon.position = Vector2.ZERO


# checks how many items from a can be put to b
static func stackable_amount(a, b) -> int:
	if a and b and a.item_data == b.item_data and a.stack_size > 1:
		return min(b.stack_size - b.items_in_stack, a.items_in_stack)
	else: return 0


func get_hovering_slot() -> Vector2i: # in form (index, 0=hotbar, 1=opened_inventory), index=-1 means not hovering over slot
	var pos = get_viewport().get_mouse_position()
	
	for slot in ui.hotbar.get_children():
		if check_in_bounds(pos, slot):
				return Vector2i(slot.get_index(), 0)
	
	for slot in inventory_ui_panel.slot_container.get_children():
		if check_in_bounds(pos, slot):
			return Vector2i(slot.get_index(), 1)
	
	return Vector2i(-1,-1)


func check_in_bounds(pos : Vector2, node : Control) -> bool:
	pos -= node.global_position
	if pos.x > 0 and pos.y > 0 and pos.x < node.size.x and pos.y < node.size.y: return true
	else: return false
