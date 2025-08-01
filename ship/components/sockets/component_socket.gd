extends Node3D
class_name ComponentSocket

@export var ship : ShipManager
@export var snap_point : ItemSnapPoint


func _ready() -> void:
	snap_point.item_placed.connect(on_component_placed)
	snap_point.item_removed.connect(on_component_removed)
	
	await get_tree().create_timer(0.2).timeout
	try_start_snap()


func try_start_snap():
	var area3D = get_node(get_path_to(snap_point)) as Area3D
	if not area3D:
		print("Socket couldnt find area")
		return
	var overlaps = area3D.get_overlapping_bodies()
	for body in overlaps:
		body = body as ShipComponent
		if body:
			if snap_point.check_item_accepted(body) and not snap_point.held_item:
				snap_point.set_item(body.get_path())
				return


func on_component_placed(item : Item):
	item = item as ShipComponent
	ship.component_manager.install_component(item)


func on_component_removed(item : Item):
	item = item as ShipComponent
	ship.component_manager.uninstall_component(item)
