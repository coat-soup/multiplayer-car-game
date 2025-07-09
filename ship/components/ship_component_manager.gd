extends Node
class_name ShipComponentManager

@export var ship_manager : ShipManager
var components : Array[ShipComponent]


func take_damage_at_point(damage : int, point : Vector3, source : int):
	var weights : Array[float] = []
	for c in components:
		if true or c.health and c.health.cur_health > 0: weights.append(1.0 / c.global_position.distance_to(point)) # allow dead things to be selected so your ship isnt completely fucked by one little dude in the corner
		else: weights.append(0)
	
	var selected = Util.weighted_random(components, weights)
	if components[selected].health : components[selected].health.take_damage(damage, source) # can sometimes select non-damagable components if all components broken (all weights=0)
