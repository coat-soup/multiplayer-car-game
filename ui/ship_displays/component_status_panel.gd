extends Control

@export var vbox : VBoxContainer
@export var component_manager : ShipComponentManager

var labels = {}

const THEME = preload("res://ui/themes/ship_panel_theme.tres")


func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	rebuild_list()


func get_component_display_text(component : ShipComponent) -> String:
	var health : int = 100 if not component.health else component.health.cur_health
	var color = "#32a852" if health >= 70 else "#a87532" if health > 0 else "#a83232"
	
	var do_rainbow = "" if health != 69 else "[rainbow freq=1.0 sat=0.8 val=0.8 speed=1.0]"
	
	return "%-20s Status: %s[color=%s]%-6s" % [component.component_name, do_rainbow, color, str(health)+"%" if health > 0 else "[b]BROKEN[/b]"]


func rebuild_list():
	for child in vbox.get_children():
		child.queue_free()
	
	for component in component_manager.components:
		var label := RichTextLabel.new()
		label.custom_minimum_size = Vector2(400, 25)
		label.scroll_active = false
		label.bbcode_enabled = true
		label.theme = THEME
		label.text = get_component_display_text(component)
		print(label.text)
		vbox.add_child(label)
		labels[component] = label
		if component.health:
			component.health.took_damage.connect(update_label.bind(component))
			component.health.healed.connect(update_label.bind(component))


func update_label(component):
	labels[component].text = get_component_display_text(component)
