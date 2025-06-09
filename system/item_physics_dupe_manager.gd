extends Node3D
class_name ItemPhysicsDupeManager

@export var ship_prefab : PackedScene
@export var ship_manager : ShipManager
var duped_ship : Node3D


func _enter_tree() -> void:
	duped_ship = ship_prefab.instantiate()
	for group in duped_ship.get_groups():
		duped_ship.remove_from_group(group)
	recursive_dupe_setup(duped_ship)
	add_child(duped_ship)


func _ready() -> void:
	for item in get_tree().get_nodes_in_group("item"):
		handle_item_spawn(item)
	
	ship_manager.item_manager.item_added.connect(item_entered_ship)
	ship_manager.item_manager.item_removed.connect(item_left_ship)



func recursive_dupe_setup(node : Node, disable := true):
	var node3d : Node3D = node as Node3D
	if node3d:
		node3d.visible = true
	
	var collider = node as StaticBody3D
	if collider:
		collider.disable_mode = CollisionObject3D.DISABLE_MODE_KEEP_ACTIVE
	if not collider:
		collider = node as CSGShape3D
	if collider:
		if Util.layer_in_mask(collider.collision_layer, 1):
			collider.collision_layer = Util.layer_mask([7])
			collider.collision_mask = Util.layer_mask([7])
	
	var c_comp = node as Door
	if c_comp:
		c_comp.set_script(preload("res://world/props/scripts/door_dupe_linker.gd"))
		c_comp = c_comp as DoorDupeLinker
		c_comp.door = ship_manager.get_node(duped_ship.get_path_to(c_comp)) as Door
		c_comp.setup()
		disable = false
	
	c_comp = node as Elevator
	if c_comp:
		(ship_manager.get_node(duped_ship.get_path_to(c_comp)) as Elevator).moving_to_floor.connect(c_comp.call_to_floor)
		disable = false
	
	if disable:
		node.set_process(false)
		node.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		node.set_process(true)
		node.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# disabling process doesn't work
	if node as MultiplayerSynchronizer:
		node.queue_free()
		return
	
	for child in node.get_children():
		recursive_dupe_setup(child, disable)


func handle_item_spawn(item : Item):
	item.physics_dupe = RigidBody3D.new()
	add_child(item.physics_dupe)
	
	item.dupe_RT = RemoteTransform3D.new()
	item.physics_dupe.add_child(item.dupe_RT)
	item.physics_dupe.contact_monitor = true
	item.physics_dupe.max_contacts_reported = 2
	
	item.physics_dupe.gravity_scale = 0
	item.physics_dupe.linear_damp = 0.1
	item.physics_dupe.angular_damp = 0.1
	
	item.physics_dupe.collision_layer = Util.layer_mask([7])
	item.physics_dupe.collision_mask = Util.layer_mask([7])
	
	for child in item.get_children():
		child = child as CollisionShape3D
		if child:
			item.physics_dupe.add_child(child.duplicate())
	
	item.physics_dupe.position = item.position


func item_entered_ship(item : Item):
	item.physics_dupe.gravity_scale = 1
	item.physics_dupe.position = item.position
	item.physics_dupe.linear_velocity -= ship_manager.movement_manager.velocity_sync
	item.dupe_RT.remote_path = ""


func item_left_ship(item : Item):
	item.physics_dupe.gravity_scale = 0
	item.physics_dupe.global_position = item.global_position
	item.dupe_RT.remote_path = item.get_path()
	item.physics_dupe.linear_velocity += ship_manager.movement_manager.velocity_sync



@rpc("any_peer", "call_local")
func reparent_node_pathbased(node : String, new_parent : String):
	get_tree().get_node(node).reparent(get_tree().root.get_node(new_parent) if new_parent != "" else get_tree().root)
