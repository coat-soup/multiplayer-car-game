extends POI
class_name POIMineCluster

const MINE = preload("res://world/props/scenes/naval_mine.tscn")
@export var num_mines : int = 10
@export var radius : float = 100


func generate(r : RandomNumberGenerator, size_multiplier):
	for n in range(num_mines * size_multiplier):
		var a = MINE.instantiate()
		add_child(a)
		a.position = Util.random_point_in_sphere(radius * size_multiplier, 0.0, r)
		a.rotation = Util.random_point_in_sphere(1.0, 0.0, r)
