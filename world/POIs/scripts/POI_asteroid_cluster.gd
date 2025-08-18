extends POI
class_name POIAsteroidCluster

const ASTEROIDS = preload("res://world/props/models/asteroids.tscn")
@export var num_asteroids : int = 10
@export var radius : float = 400
@export var asteroid_size_range : Vector2 = Vector2(0.5, 2.0)


func generate(r : RandomNumberGenerator, size_multiplier):
	asteroid_pass(r, num_asteroids * size_multiplier, size_multiplier, 1.0)
	asteroid_pass(r, num_asteroids * size_multiplier, size_multiplier, 0.1) # small pass


func asteroid_pass(r : RandomNumberGenerator, num, radius_m, size_m):
	for n in range(num):
		var a = ASTEROIDS.instantiate()
		var child = a.get_child(r.randi_range(0, a.get_child_count() - 1))
		for c in a.get_children():
			if c != child: c.queue_free()
		add_child(a)
		a.position = Util.random_point_in_sphere(radius * radius_m, 0.0, r)
		a.rotation = Util.random_point_in_sphere(1.0, 0.0, r)
		a.scale = Vector3.ONE * r.randf_range(asteroid_size_range.x, asteroid_size_range.y) * size_m
