extends Node
class_name ItemInventory

@export var display_name : String = "Inventory"
@export var dimensions : Vector2i = Vector2i(1,1)

var items : Array[Holdable]

@onready var ui : UIManager = get_tree().get_first_node_in_group("ui") as UIManager

var opened_locally : bool = false
var using_player : Player
@export var interactable : Interactable

var inventory_ui_panel : InventoryUIPanelManager
const INVENTORY_UI_PANEL = preload("res://ui/widgets/inventory_ui_panel.tscn")

var currently_dragging : InventoryItemIconManager


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
	if not multiplayer.is_server(): return
	var accepted = using_player == null
	if accepted:
		using_player = get_tree().get_root().get_node(player_path) as Player
		if not using_player:
			print("Opening player not found for ", get_parent().name, "inventory (path: ", player_path, ")")
	receive_open_response.rpc_id(multiplayer.get_remote_sender_id(), accepted, player_path)


@rpc("any_peer", "call_local")
func receive_open_response(accepted : bool, player_path : String):
	if accepted:
		using_player = get_tree().get_root().get_node(player_path) as Player
		open_inventory_local()
	else:
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
	
	for item in using_player.equipment_manager.items:
		if not item: continue
		item.inventory_icon.started_drag.connect(on_drag_started.bind(item.inventory_icon))
		item.inventory_icon.ended_drag.connect(on_drag_ended.bind(item.inventory_icon))
		item.inventory_icon.stack_split.connect(on_stack_split.bind(item.inventory_icon))
	
	for item in items:
		if not item: continue
		item.inventory_icon.started_drag.connect(on_drag_started.bind(item.inventory_icon))
		item.inventory_icon.ended_drag.connect(on_drag_ended.bind(item.inventory_icon))
		item.inventory_icon.stack_split.connect(on_stack_split.bind(item.inventory_icon))


func close_inventory_local():
	ui.close_inventory_panel(self)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	using_player.active = true
	
	for item in using_player.equipment_manager.items:
		if not item: continue
		item.inventory_icon.started_drag.disconnect(on_drag_started)
		item.inventory_icon.ended_drag.disconnect(on_drag_ended)
		item.inventory_icon.stack_split.disconnect(on_stack_split)
	
	for item in items:
		if not item: continue
		item.inventory_icon.started_drag.disconnect(on_drag_started)
		item.inventory_icon.ended_drag.disconnect(on_drag_ended)
		item.inventory_icon.stack_split.disconnect(on_stack_split)
	
	if currently_dragging: currently_dragging.stop_dragging()
	
	opened_locally = false
	await get_tree().create_timer(0.2).timeout
	interactable.active = true


@rpc("any_peer", "call_local")
func set_item(item_path : String, slot : int, change_physics : bool = true):
	var item : Holdable = get_tree().get_root().get_node(item_path) as Holdable
	if item:
		items[slot] = item
		inventory_ui_panel.put_icon_in_slot(item.inventory_icon, slot)
		item.inventory_icon.visible = true
		
		if change_physics:
			item.visible = false
			item.disable_physics()
			#item.move_item(get_parent().global_position)


@rpc("any_peer", "call_local")
func swap_item_positions(a : int, b : int):
	var item_a = items[a]
	var item_b = items[b]
	
	items[a] = item_b
	if item_b: inventory_ui_panel.put_icon_in_slot(item_b.inventory_icon, a)
	
	items[b] = item_a
	if item_a: inventory_ui_panel.put_icon_in_slot(item_a.inventory_icon, b)


@rpc("any_peer", "call_local")
func drop_item(slot : int, change_physics : bool = true):
	var item = items[slot]
	
	item.inventory_icon.reparent(item)
	item.inventory_icon.visible = false
	if change_physics:
		item.enable_physics()
		item.visible = true
		
		if using_player:
			await get_tree().process_frame
			item.move_item(using_player.equipment_manager.global_position)
	
	items[slot] = null


func on_drag_started(icon : InventoryItemIconManager):
	currently_dragging = icon


func on_drag_ended(icon : InventoryItemIconManager):
	var ending_point = get_hovering_slot()
	
	var stackable = stackable_amount(icon.item, items[ending_point.x] if ending_point.y == 1 else using_player.equipment_manager.items[ending_point.x])
	var stack_all = stackable == icon.item.items_in_stack
	
	if ending_point.y == -1:
		# return to prev slot
		if check_in_bounds(get_viewport().get_mouse_position(), ui.hotbar) or check_in_bounds(get_viewport().get_mouse_position(), inventory_ui_panel.background):
			return_icon(icon)
		
		else: # throw out ## WARNING: disabled with `true or` in previous if because figuring out where to place the item when throwing it out is kind of a pain
			if items.has(icon.item):
				drop_item.rpc(icon.inventory_position)
			elif using_player.equipment_manager.items.has(icon.item):
				using_player.equipment_manager.drop_equipment.rpc(icon.inventory_position)
		
	elif ending_point.y == 0:
		if items.has(icon.item): # inventory to hotbar
			if stackable > 0:
				icon.item.change_stack_size.rpc(-stackable)
				using_player.equipment_manager.items[ending_point.x].change_stack_size.rpc(stackable)
				return_icon(icon)
				if stack_all:
					drop_item.rpc(icon.inventory_position, false)
					icon.item.destroy_item.rpc()
			else:
				drop_item.rpc(icon.inventory_position, false)
				if using_player.equipment_manager.items[ending_point.x]:
					var prev_item = using_player.equipment_manager.items[ending_point.x]
					var old_slot = icon.inventory_position
					using_player.equipment_manager.drop_equipment.rpc(ending_point.x)
					set_item.rpc(prev_item.get_path(), old_slot)
				using_player.equipment_manager.equip_item(icon.item, ending_point.x, false)
			
		elif using_player.equipment_manager.items.has(icon.item): # hotbar to hotbar
			if icon.inventory_position == ending_point.x:
				return_icon(icon)
				return
			if stackable > 0:
				icon.item.change_stack_size.rpc(-stackable)
				using_player.equipment_manager.items[ending_point.x].change_stack_size.rpc(stackable)
				return_icon(icon)
				if stack_all:
					using_player.equipment_manager.drop_equipment.rpc(icon.inventory_position)
					icon.item.destroy_item.rpc()
			else:
				var prev_item = using_player.equipment_manager.items[ending_point.x]
				var old_slot = icon.inventory_position
				using_player.equipment_manager.drop_equipment.rpc(icon.inventory_position)
				using_player.equipment_manager.equip_item(icon.item, ending_point.x, false)
				if prev_item:
					using_player.equipment_manager.equip_item(prev_item, old_slot, false)
		
	elif ending_point.y == 1:
		if items.has(icon.item):  # inventory to inventory
			if icon.inventory_position == ending_point.x:
				return_icon(icon)
				return
			if stackable > 0:
				icon.item.change_stack_size.rpc(-stackable)
				items[ending_point.x].change_stack_size.rpc(stackable)
				return_icon(icon)
				if stack_all:
					drop_item.rpc(icon.inventory_position, false)
					icon.item.destroy_item.rpc()
			else: swap_item_positions.rpc(icon.inventory_position, ending_point.x)
			
		elif using_player.equipment_manager.items.has(icon.item):  # hotbar to inventory
			if stackable > 0:
				icon.item.change_stack_size.rpc(-stackable)
				items[ending_point.x].change_stack_size.rpc(stackable)
				return_icon(icon)
				if stack_all:
					using_player.equipment_manager.drop_equipment.rpc(icon.inventory_position)
					icon.item.destroy_item.rpc()
			else:
				using_player.equipment_manager.drop_equipment.rpc(icon.inventory_position)
				if items[ending_point.x]:
						var prev_item = items[ending_point.x]
						var old_slot = icon.inventory_position
						drop_item.rpc(ending_point.x, false)
						using_player.equipment_manager.equip_item(prev_item, old_slot)
				set_item.rpc(icon.item.get_path(), ending_point.x)
	
	currently_dragging = null


func on_stack_split(amount : int, icon : InventoryItemIconManager):
	rpc_stack_split.rpc(amount, icon.item.get_path())


@rpc("any_peer", "call_local")
func rpc_stack_split(amount, item_path):
	if not multiplayer.is_server(): return
	var icon : InventoryItemIconManager = (get_tree().get_root().get_node(item_path) as Holdable).inventory_icon as InventoryItemIconManager
	
	print(icon.item, " splitting ", amount)
	
	var ending_point = get_hovering_slot()
	
	var target_item = null if ending_point.y == -1 else (items[ending_point.x] if ending_point.y == 1 else using_player.equipment_manager.items[ending_point.x])
	var stackable = min(amount, stackable_amount(icon.item, target_item))
	
	if target_item:
		target_item.change_stack_size.rpc(stackable)
		icon.item.change_stack_size.rpc(-stackable)
	else:
		var new_item = using_player.network_manager.network_manager.level_manager.spawn_item_synced(icon.item.scene_file_path, using_player.equipment_manager.global_position)
		icon.item.change_stack_size.rpc(-amount)
		new_item.change_stack_size.rpc(amount - 1)
		
		await get_tree().create_timer(0.5).timeout
		if ending_point.y == 0: using_player.equipment_manager.equip_item(new_item, ending_point.x, false)
		elif ending_point.y == 1: set_item.rpc(new_item.get_path(), ending_point.x)


func return_icon(icon : InventoryItemIconManager):
	if items.has(icon.item):
		icon.reparent(inventory_ui_panel.slot_container.get_child(icon.inventory_position))
		icon.position = Vector2.ZERO
	elif using_player.equipment_manager.items.has(icon.item):
		icon.reparent(ui.hotbar.get_child(icon.inventory_position))
		icon.position = Vector2.ZERO


# checks how many items from a can be put to b
static func stackable_amount(a : Holdable, b : Holdable) -> int:
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
