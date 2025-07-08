extends Control

@export var power_manager : ShipPowerManager

var CAPACITOR_STACK_UI = preload("res://ui/ship_displays/power_system_capacitor_stack.tscn")
@onready var system_container: HBoxContainer = $SystemContainer

@onready var capacitor_usage_label: RichTextLabel = $CapacitorUsageLabel

@export var active_colour : Color
@export var empty_colour : Color

@export var display_panel : DisplayConsole

var current_adjusted_stack := -1


func _ready():
	rebuild()


func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		$CursorTest.position = event.position
		if Input.is_action_pressed("ui_primary"):
			var capacitor := get_focused_capacitor(event.position)
			if current_adjusted_stack == -1: current_adjusted_stack = capacitor.x
			if capacitor.x == current_adjusted_stack and capacitor.x != -1 and capacitor.y != -1:
				power_manager.set_system_capacitors(capacitor.x, max(0, min(capacitor.y, power_manager.power_systems[capacitor.x].max_capacitors)))
		if Input.is_action_just_released("ui_primary"):
			current_adjusted_stack = -1


func rebuild():
	for child in system_container.get_children():
		child.queue_free()
	
	for system in power_manager.power_systems:
		var stack = CAPACITOR_STACK_UI.instantiate()
		system_container.add_child(stack)
		for i in range(system.max_capacitors - 1):
			var capacitor = stack.get_child(0).get_child(0).duplicate() as ColorRect
			stack.get_child(0).add_child(capacitor)
		(stack.get_node("Label") as Label).text = system.system_name
		(stack.get_node("Icon") as TextureRect).texture = system.icon
		
		system.capacitors_changed.connect(update_capacitors)
	
	await get_tree().process_frame
	update_capacitors()


func get_focused_capacitor(mouse_pos) -> Vector2i: # form (stack, capacitor)
	var id = Vector2.ONE * -1
	
	for i in range(len(power_manager.power_systems)):
		var x_dist = abs(system_container.get_child(i).global_position.x + system_container.get_child(i).custom_minimum_size.x/2 - mouse_pos.x)
		if x_dist < system_container.get_child(i).custom_minimum_size.x/2:
			id.x = i                                                                                # child order is reversed
			var first_cap := system_container.get_child(i).get_child(0).get_child(power_manager.power_systems[i].max_capacitors-1) as Control
			id.y = (first_cap.global_position.y + first_cap.size.y * 2 - mouse_pos.y) / (first_cap.size.y + 15) # WARNING: 15 is hardcoded separation. change when necessary
			if id.y > power_manager.power_systems[i].max_capacitors + 1: id.y = -1
	
	return id


func update_capacitors():
	for i in range(len(power_manager.power_systems)):
		for c in range(power_manager.power_systems[i].max_capacitors):
			var cap = (system_container.get_child(i).get_child(0).get_child(power_manager.power_systems[i].max_capacitors - 1 - c) as ColorRect)
			cap.color = active_colour if power_manager.power_systems[i].assigned_capacitors > c else empty_colour
	
	capacitor_usage_label.text = "[b][color=yellow]%02d[/color][/b] used\n\n[b][color=green]%02d[/color][/b] total" % [power_manager.capacitors - power_manager.unused_capacitors, power_manager.capacitors]


#func capacitor_slot_clicked
