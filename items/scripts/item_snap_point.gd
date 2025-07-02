extends Area3D
class_name ItemSnapPoint

signal item_placed
signal item_removed

@export var accepted_groups : Array[String]

var held_item : Item
var prev_t : Transform3D


func _ready() -> void:
	body_entered.connect(on_body_entered)
	body_exited.connect(on_body_exited)


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
func set_item(item_path : String):
	if held_item: held_item.physics_dupe.transform = prev_t
	held_item = get_tree().root.get_node(item_path) if item_path != "" else null
	if held_item: prev_t = held_item.physics_dupe.transform
	
	if held_item: item_placed.emit()
	else: item_removed.emit()
