extends Interactable
class_name ItemSnapPoint

signal item_placed(Item)
signal item_removed(Item)

@export var accepted_groups : Array[String]
@export var needs_all : bool = true

var held_item : Item
var prev_p : Vector3
var prev_r : Vector3
@onready var area : Area3D
@export var alternate_prompt : String = ""

var remote_transform : RemoteTransform3D


func _ready() -> void:
	area = self as Node3D as Area3D
	
	remote_transform = RemoteTransform3D.new()
	add_child(remote_transform)
	
	area.body_entered.connect(on_body_entered)
	area.body_exited.connect(on_body_exited)
	
	interacted.connect(on_interacted)
	multiplayer.connected_to_server.connect(on_connect)


func on_connect():
	if not multiplayer.is_server():
		request_initialise_on_load.rpc_id(1)


@rpc("call_local", "any_peer")
func request_initialise_on_load():
	if not multiplayer.is_server(): return
	if held_item:
		initialise_on_load.rpc_id(multiplayer.get_remote_sender_id(), held_item.get_path())


@rpc("call_local", "any_peer")
func initialise_on_load(item_path):
	set_item(item_path)


func on_body_entered(body):
	if held_item: return
	
	body = body as Item
	if body and check_item_accepted(body) and body.tractored:
		body.potential_snap_points.append(self)


func on_body_exited(body):
	body = body as Item
	if body:
		var i = body.potential_snap_points.find(self)
		if i != -1: body.potential_snap_points.remove_at(i)


func check_item_accepted(item : Item) -> bool:
	if needs_all:
		for group in accepted_groups:
			if not item.is_in_group(group):
				#print(item, " not in correct group: ", group)
				return false
		return true
	else:
		for group in accepted_groups:
			if item.is_in_group(group):
				return true
		return false


@rpc("any_peer", "call_local")
func set_item(item_path : String, reset_transform : bool = true):
	#print("%s running set item for %s (auth:%s)" % [get_parent().name, item_path, is_multiplayer_authority()])
	var item_ref = held_item
	
	if held_item:
		var eq = held_item as Holdable
		if eq: eq.picked_up.disconnect(on_equipment_picked_up_manually)
		if reset_transform:
			held_item.move_item(to_global(prev_p))
		remote_transform.remote_path = ""
		held_item.controlling_RT = null
	
	if item_path != "":
		held_item = get_tree().root.get_node(item_path) as Item
		active = false
		
		attach_item(held_item)
		
		if held_item.potential_snap_points.find(self) == -1: held_item.potential_snap_points.append(self) # WARNING: doesn't seem to work for some reason
		
		item_placed.emit(held_item)
		
		var eq = held_item as Holdable
		if eq: eq.picked_up.connect(on_equipment_picked_up_manually)
	else:
		active = true
		held_item = null
		item_removed.emit(item_ref)


func observe(_source: Node3D) -> String:
	return (prompt_text if not held_item else alternate_prompt) if active else ""


func on_equipment_picked_up_manually():
	held_item.snap_point = null
	set_item("", false)


func attach_item(item : Item):
	item.held_in_place = true
	
	prev_p = to_local(item.global_position)
	prev_r = item.global_rotation * global_basis
	
	item.global_position = global_position
	item.move_item(item.global_position)
	#item.physics_dupe.position = item.position
	item.global_rotation = global_rotation
	item.physics_dupe.rotation = item.rotation
	item.snap_point = self
	
	if item.snap_indicator: item.snap_indicator.visible = false
	
	remote_transform.remote_path = item.get_path()
	item.controlling_RT = remote_transform
	remote_transform.position = item.snap_point_offset
	
	await get_tree().process_frame # so rigidbody updates before freezing
	item.physics_dupe.freeze = true


func on_interacted(source : Node):
	if not (source as Player): return
	var eq : EquipmentManager = (source as Player).equipment_manager
	var item = eq.items[eq.cur_slot]
	if item:
		if not check_item_accepted(item):
			item.ui.display_prompt("Only accepts " +  str(accepted_groups))
			return
		eq.drop_equipment.rpc(eq.cur_slot)
		await item.on_dropped
		await get_tree().create_timer(0.1).timeout
		set_item.rpc(item.get_path())
		print("manually setting item to snap point")
		
	print("Player interacted with snap point, holding ", item)
