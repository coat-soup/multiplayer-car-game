extends Interactable
class_name ItemSnapPoint

signal item_placed
signal item_removed

@export var accepted_groups : Array[String]

var held_item : Item
var prev_t : Transform3D
@onready var area : Area3D
@export var alternate_prompt : String = ""


func _ready() -> void:
	area = self as Node3D as Area3D
	
	area.body_entered.connect(on_body_entered)
	area.body_exited.connect(on_body_exited)
	
	interacted.connect(on_interacted)


func on_body_entered(body):
	if held_item: return
	
	body = body as Item
	if body and check_item_accepted(body):
		body.potential_snap_points.append(self)


func on_body_exited(body):
	if held_item: return
	
	body = body as Item
	if body:
		var i = body.potential_snap_points.find(self)
		if i != -1: body.potential_snap_points.remove_at(i)


func check_item_accepted(item : Item) -> bool:
	for group in accepted_groups:
		if item.is_in_group(group):
			return true
	return false


@rpc("any_peer", "call_local")
func set_item(item_path : String, reset_transform : bool = true):
	print("running set item (auth:%s)" % [is_multiplayer_authority()])
	if held_item:
		var eq = held_item as Equipment
		if eq: eq.picked_up.disconnect(on_equipment_picked_up_manually)
		if reset_transform: held_item.physics_dupe.transform = prev_t
	
	held_item = get_tree().root.get_node(item_path) if item_path != "" else null
	if held_item:
		attach_item(held_item)
		
		prev_t = held_item.physics_dupe.transform
		item_placed.emit()
		
		var eq = held_item as Equipment
		if eq: eq.picked_up.connect(on_equipment_picked_up_manually)
	else:
		item_removed.emit()


func observe(_source: Node3D) -> String:
	return (prompt_text if not held_item else alternate_prompt) if active else ""


func on_equipment_picked_up_manually():
	held_item.snap_point = null
	set_item("", false)


func attach_item(item : Item):
	item.held_in_place = true
		
	item.global_position = global_position
	item.physics_dupe.position = item.position
	item.global_rotation = global_rotation
	item.physics_dupe.rotation = item.rotation
	item.snap_point = self
	
	item.snap_indicator.visible = false
		
	await get_tree().process_frame # so rigidbody updates before freezing
	item.physics_dupe.freeze = true


func on_interacted(source : Node):
	if not (source as Player): return
	var eq : EquipmentManager = (source as Player).equipment_manager
	var item = eq.items[eq.cur_slot]
	if item:
		eq.drop_equipment.rpc(eq.cur_slot)
		await item.on_dropped
		await get_tree().create_timer(0.1).timeout
		set_item.rpc(item.get_path())
		print("manually setting item to snap point")
		
	print("Player interacted with snap point, holding ", item)
