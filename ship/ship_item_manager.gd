extends Node
class_name ShipItemManager

signal item_added
signal item_removed

@export var ship_manager : ShipManager

var items : Array[Item]

func _ready() -> void:
	ship_manager.gravity_bounds.body_entered.connect(check_item_entered)
	ship_manager.gravity_bounds.body_exited.connect(check_item_left)
	#onboard_check_loop()


func onboard_check_loop():
	var bodies = ship_manager.gravity_bounds.get_overlapping_bodies()
	for body in bodies:
		body = body as Item
		if body:
			if not body.on_ship:
				pass
	
	await get_tree().create_timer(0.5).timeout
	onboard_check_loop()


func check_item_entered(body):
	body = body as Item
	if body:
		add_item(body)


func check_item_left(body):
	body = body as Item
	if body:
		remove_item(body)


func add_item(item : Item):
	items.append(item)
	item.on_ship = ship_manager
	item_added.emit(item)


func remove_item(item : Item):
	items.remove_at(items.find(item))
	item.on_ship = null
	item_removed.emit(item)
