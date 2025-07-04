extends Control

@export var power_manager : ShipPowerManager

var CAPACITOR_STACK_UI = preload("res://ui/ship_displays/power_system_capacitor_stack.tscn")
@onready var system_container: HBoxContainer = $SystemContainer

@onready var capacitor_usage_label: RichTextLabel = $CapacitorUsageLabel

@export var active_colour : Color
@export var empty_colour : Color


func _ready():
	rebuild()


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
	
	await get_tree().process_frame
	update_capacitors()


func update_capacitors():
	for i in range(len(power_manager.power_systems)):
		for c in range(power_manager.power_systems[i].max_capacitors):
			(system_container.get_child(i).get_child(0).get_child(c) as ColorRect).color = active_colour if power_manager.power_systems[i].assigned_capacitors > c else empty_colour
	
	capacitor_usage_label.text = "[b][color=yellow]%02d[/color][/b] used\n\n[b][color=green]%02d[/color][/b] total" % [power_manager.capacitors - power_manager.unused_capacitors, power_manager.capacitors]
