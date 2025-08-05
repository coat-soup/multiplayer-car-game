extends Control
class_name InventoryUIPanelManager

@onready var name_text: Label = $NameText
@onready var background: ColorRect = $Background
@onready var slot_container: GridContainer = $SlotContainer

const INVENTORY_SLOT = preload("res://ui/scenes/inventory_slot.tscn")
const INVENTORY_ITEM_ICON = preload("res://ui/scenes/inventory_item_icon.tscn")

var inventory : ItemInventory
@export var padding : int = 40


func rebuild():
	for child in slot_container.get_children():
		child.queue_free()
	
	name_text.text = inventory.display_name
	
	slot_container.columns = inventory.dimensions.x
	for x in inventory.dimensions.x:
		for y in inventory.dimensions.y:
			var slot = INVENTORY_SLOT.instantiate()
			slot_container.add_child(slot)
	
	slot_container.position = Vector2(padding, padding)
	
	background.set_size(Vector2(padding * 2 + inventory.dimensions.x * ((slot_container.get_child(0) as Control).size.x + slot_container.get_theme_constant("h_separation")),
								padding * 2 + inventory.dimensions.y * ((slot_container.get_child(0) as Control).size.y + slot_container.get_theme_constant("v_separation"))
								))


func put_icon_in_slot(icon : InventoryItemIconManager, slot : int):
	icon.reparent(slot_container.get_child(slot))
	icon.position = Vector2.ZERO
