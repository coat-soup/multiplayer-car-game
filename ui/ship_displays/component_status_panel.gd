extends Control

@export var vbox : VBoxContainer
@export var component_manager : ShipComponentManager

var labels = {}

const FONT = preload("res://ui/fonts/HomeVideo-BLG6G.ttf")


func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	rebuild_list()


func get_component_display_text(component : ShipComponent) -> String:
	var health : int = 100 if not component.health else component.health.cur_health
	
	return "%-20s Status: %-6s" % [component.component_name, str(health)+"%" if health > 0 else "BROKEN"]


func rebuild_list():
	for child in vbox.get_children():
		child.queue_free()
	
	for component in component_manager.components:
		var label = Label.new()
		label.add_theme_font_override("font", FONT)
		label.text = get_component_display_text(component)
		vbox.add_child(label)
		labels[component] = label
		if component.health:
			component.health.took_damage.connect(update_label.bind(component))
			component.health.healed.connect(update_label.bind(component))


func update_label(component):
	labels[component].text = get_component_display_text(component)
