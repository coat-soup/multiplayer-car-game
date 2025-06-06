extends Node

class_name EquipmentManager

@export var player : Player
@export var num_slots := 2
var items : Array[Equipment] = []
var cur_slot := 0


func _ready() -> void:
	for i in range(num_slots):
		items.append(null)

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
		equipment.equipped = true
		equipment.interactable.active = false
		items[slot] = equipment
		
		equipment.reparent(self)
		equipment.held_player = player
		equipment.prev_parent = player # for transform
		equipment.position = Vector3.ZERO
		equipment.rotation = Vector3.ZERO
		
		equipment.on_pickedup()
		
		if slot != cur_slot:
			equipment.visible = false
		else:
			equipment.on_held()
		
	else:
		print("could not find equipment")


@rpc("any_peer", "call_local")
func drop_equipment(slot: int):
	if items[slot]:
		items[slot].reparent(get_tree().get_root())
		items[slot].held_player = null
		items[slot].equipped = false
		items[slot].held_by_auth = false
		items[slot].visible = true
		items[slot].interactable.active = true
		items[slot].raycast_position()
		if slot == cur_slot:
			items[slot].on_unheld()
		items[slot].on_dropped()
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
