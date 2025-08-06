extends Item
class_name Holdable

signal triggered
signal trigger_ended

## item added to inventory
signal picked_up
## item removed from inventory
signal dropped
## item moved into hand from inventory or anywhere else (eg picked up, swapped to, unholstered)
signal held
## item moved out of hand/became inactive (eg swapped to different equipment, holstered)
signal put_away

@export var interactable : Interactable

@export var ground_offset := 0.2

var equipped := false
var held_by_auth := false
var held_player : Player = null
var prev_parent : Node3D = null

@export var stack_size : int = 1
@export var items_in_stack : int = 1

@export var interact_holdable := true

@export var raycast_on_startup := true

var prev_layers : int


var inventory_icon : InventoryItemIconManager:
	get:
		if inventory_icon: return inventory_icon
		else:
			inventory_icon = preload("res://ui/scenes/inventory_item_icon.tscn").instantiate() as InventoryItemIconManager
			inventory_icon.ui = ui
			inventory_icon.item = self
			add_child(inventory_icon)
			inventory_icon.rebuild()
			return inventory_icon


func _ready():
	super._ready()
	
	interactable.prompt_text = "Pick up " + item_data.item_name
	if stack_size > 1: interactable.prompt_text += " (x" + str(items_in_stack) + ")"
	interactable.interacted.connect(try_equip)
	triggered.connect(on_triggered)
	trigger_ended.connect(on_trigger_ended)
	#if raycast_on_startup:
		#raycast_position()


func _input(event: InputEvent) -> void:
	if equipped and held_by_auth and held_player.active:
		var button = -1
		var let_go = false
		if event.is_action_pressed("primary_fire"):
			button = 0
		elif event.is_action_pressed("secondary_fire"):
			button = 1
		elif event.is_action_pressed("reload"):
			button = 3
		
		elif event.is_action_released("primary_fire"):
			let_go = true
			button = 0
		elif event.is_action_released("secondary_fire"):
			let_go = true
			button = 1
		elif event.is_action_released("reload"):
			let_go = true
			button = 3
		
		if button != -1:
			if not let_go: triggered.emit(button)
			else: trigger_ended.emit(button)


func try_equip(source):
	source = source as Player
	if source:
		source.equipment_manager.equip_item(self)


@rpc("any_peer", "call_local")
func set_parent_to_scene_path(path : String, zero_transform := false):
	reparent(get_tree().root if path == "" else get_tree().root.get_node(path))
	if zero_transform:
		position = Vector3.ZERO
		rotation = Vector3.ZERO
		
	#if path == "":
		#raycast_position()


@rpc("any_peer", "call_local")
func disable_physics():
	held_in_place = true
	collision_layer = 0
	prev_layers = physics_dupe.collision_layer
	physics_dupe.collision_layer = 0
	
	await get_tree().create_timer(0.1).timeout
	physics_dupe.freeze = true


@rpc("any_peer", "call_local")
func enable_physics():
	held_in_place = false
	collision_layer = 1
	physics_dupe.collision_layer = prev_layers
	physics_dupe.freeze = false


## DEPRECATED
func raycast_position():
	return
	var space_state = get_world_3d().direct_space_state
	
	if not prev_parent: prev_parent = self
	
	var query = PhysicsRayQueryParameters3D.create(global_position, global_position - prev_parent.global_basis.y * 100, Util.layer_mask([1,6]))
	#query.exclude = [self]

	var result := space_state.intersect_ray(query)
	
	if result:
		global_position = result.position + prev_parent.global_basis.y * ground_offset
		if result.normal.dot(global_basis.z) > 0.001:
			look_at(position + result.normal, global_basis.z)
		self.reparent.call_deferred(result.collider as Node3D)


func on_held():
	held.emit()

func on_put_away():
	put_away.emit()

func on_dropped():
	dropped.emit()

func on_picked_up():
	picked_up.emit()

func on_triggered(_button : int):
	pass

func on_trigger_ended(_button : int):
	pass


@rpc("any_peer", "call_local")
func destroy_item():
	inventory_icon.queue_free()
	super.destroy_item()


@rpc("any_peer", "call_local")
func change_stack_size(change : int):
	items_in_stack += change
	
	interactable.prompt_text = "Pick up " + item_data.item_name
	if stack_size > 1: interactable.prompt_text += " (x" + str(items_in_stack) + ")"
	
	inventory_icon.rebuild()
