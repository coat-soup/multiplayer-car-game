extends Control

@onready var container : GridContainer = $GridContainer
@export var component_manager : ShipComponentManager

var labels = {}

const THEME = preload("res://ui/themes/ship_panel_theme.tres")


func _ready() -> void:
	component_manager.components_changed.connect(rebuild_list)
	rebuild_list()


func get_component_display_text(component : ShipComponent) -> String:
	var health : int = 100 if not component.health else component.health.cur_health
	var color = "#32a852" if health >= 70 else "#a87532" if health > 0 else "#a83232"
	
	var do_rainbow = "" if health != 69 else "[rainbow freq=1.0 sat=0.8 val=0.8 speed=1.0]"
	
	return "%-20s Status: %s[color=%s]%-6s" % [component.component_name, do_rainbow, color, str(health)+"%" if health > 0 else "[b]BROKEN[/b]"]


func rebuild_list():
	for child in container.get_children():
		child.queue_free()
		
	
	for component in component_manager.components:
		var label := RichTextLabel.new()
		label.custom_minimum_size = Vector2(850, 50)
		label.scroll_active = false
		label.bbcode_enabled = true
		label.theme = THEME
		label.text = get_component_display_text(component)
		label.add_theme_font_size_override("normal_font_size",30)
		label.add_theme_font_size_override("bold_font_size",30)
		container.add_child(label)
		if component.health and not labels.has(component):
			component.health.took_damage.connect(update_label.bind(component))
			component.health.healed.connect(update_label.bind(component))
		labels[component] = label

func update_label(component):
	labels[component].text = get_component_display_text(component)
