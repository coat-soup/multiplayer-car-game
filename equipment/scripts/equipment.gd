extends Node3D
class_name Equipment

signal triggered
signal trigger_ended

@export var equipment_name : String
@export var interactable : Interactable

@export var ground_offset := 0.2

var equipped := false
var held_by_auth := false
var held_player : Player = null
var prev_parent : Node3D = null

@export var interact_holdable := true

@export var raycast_on_startup := true


func _ready():
	interactable.prompt_text = "Equip " + equipment_name
	interactable.interacted.connect(try_equip)
	triggered.connect(on_triggered)
	trigger_ended.connect(on_trigger_ended)
	if raycast_on_startup:
		raycast_position()


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
		
	if path == "":
		raycast_position()


func raycast_position():
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
	pass

func on_unheld():
	pass

func on_dropped():
	pass

func on_pickedup():
	pass

func on_triggered(_button : int):
	pass

func on_trigger_ended(_button : int):
	pass
