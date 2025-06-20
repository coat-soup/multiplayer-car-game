extends Node
class_name ShipComponentManager

@export var ship_manager : ShipManager
var components : Array[ShipComponent]


func _ready() -> void:
	for child in ship_manager.get_children():
		var component = child as ShipComponent
		if component: components.append(component)


func take_damage_at_point(damage : int, point : Vector3, source : int):
	var weights : Array[float] = []
	for c in components:
		if c.health and c.health.cur_health > 0: weights.append(1.0 / c.global_position.distance_to(point))
		else: weights.append(0)
	
	var selected = Util.weighted_random(components, weights)
	print("randomly selected ", components[selected].name)
	if components[selected].health : components[selected].health.take_damage(damage, source) # can sometimes select non-damagable components if all components broken (all weights=0)
