extends Control
class_name InventoryItemIconManager

signal started_drag
signal ended_drag
signal stack_split

var item : Holdable

@onready var icon: TextureRect = $Icon
@onready var stack_label: Label = $StackLabel
@onready var name_label: Label = $NameLabel

var hovering : bool = false
var dragging : bool = false

var inventory_position : int
var ui : UIManager


func _ready() -> void:
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_exited)
	if item: item.dropped.connect(on_dropped) # sometimes item is destroyed immediately upon access


func _input(event: InputEvent) -> void:
	if hovering and not dragging and event.is_action_pressed("ui_primary"):
		start_dragging()
	elif dragging and event.is_action_released("ui_primary"):
		stop_dragging()
	elif dragging and event.is_action_pressed("ui_secondary"):
		try_split_stack()


func _process(delta: float) -> void:
	if dragging:
		global_position = get_viewport().get_mouse_position() - size/2


func start_dragging():
	dragging = true
	inventory_position = get_parent().get_index()
	reparent(ui.dragged_icon_holder)
	started_drag.emit()


func stop_dragging():
	dragging = false
	ended_drag.emit()


func try_split_stack():
	if item.stack_size > 1 and item.items_in_stack > 1:
		stack_split.emit(int(item.items_in_stack/2))#, item)


func on_mouse_entered():
	hovering = true


func on_mouse_exited():
	hovering = false


func on_dropped():
	reparent(item)
	visible = false


func rebuild():
	icon.texture = null #TODO: make icons
	stack_label.text = str(item.items_in_stack) if item.stack_size > 1 else ""
	name_label.text = item.item_data.item_name
