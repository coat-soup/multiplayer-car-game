extends Resource
class_name InventoryItemData

var item_data : ItemData
var stack_size : int
var items_in_stack : int
var inventory_slot : int
var inventory_type : int # 0 = inventory, 1 = hotbar

var ui_icon : InventoryItemIconManager


func _init(item : Holdable, icon_parent : Node, icon : InventoryItemIconManager = null):
	item_data = item.item_data
	stack_size = item.stack_size
	items_in_stack = item.items_in_stack
	
	ui_icon = icon
	if not ui_icon: ui_icon = create_icon(item, icon_parent)


func create_icon(item: Holdable, parent : Node) -> InventoryItemIconManager:
	var icon = preload("res://ui/scenes/inventory_item_icon.tscn").instantiate() as InventoryItemIconManager
	icon.ui = item.ui
	icon.inventory_item = self
	parent.add_child(icon)
	icon.rebuild()
	icon.visible = false
	return icon


func change_stack_size(amount : int):
	print("changing stack size by ", amount)
	items_in_stack += amount
	print("new stack size: ", items_in_stack)
	if ui_icon: ui_icon.rebuild()


func override_stack_size(amount : int):
	items_in_stack = amount
	if ui_icon: ui_icon.rebuild()
