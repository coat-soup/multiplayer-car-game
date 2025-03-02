extends Node3D

class_name Equipment

signal triggered

@export var interactable : Interactable
@export var rigid_body : RigidBody3D

@export var ground_offset := 0.2

var equipped := false
var held_by_auth := false


func _ready():
	interactable.interacted.connect(try_equip)
	raycast_position()


func _input(event: InputEvent) -> void:
	if equipped and held_by_auth and event.is_action_pressed("primary_fire"):
		triggered.emit()
		print(name, " triggered")


func try_equip(source):
	var player = source as Player
	if player:
		player.equipment_manager.equip_item(self)


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

	var query = PhysicsRayQueryParameters3D.create(global_position, global_position - Vector3.UP * 100, Util.layer_mask([1]))
	#query.exclude = [self]

	var result := space_state.intersect_ray(query)
	
	if result:
		global_position = result.position + Vector3.UP * ground_offset
		if result.normal.dot(global_basis.z) > 0.001:
			look_at(position + result.normal, global_basis.z)
