extends Node3D

class_name EnemyGroundAsset

signal broken
signal fixed


@export var health : Health

const BROKEN_COMPONENT_PARTICLES = preload("res://vfx/particles/broken_component_particles.tscn")
var broken_particles : Node3D = null
var is_broken := false


func _ready():
	if health:
		health.died.connect(on_break)
		health.healed.connect(on_fixed)


func on_break():
	is_broken = true
	broken.emit()
	
	print("creating particles")
	broken_particles = BROKEN_COMPONENT_PARTICLES.instantiate()
	add_child(broken_particles)
	broken_particles.position = Vector3.ZERO
	
	queue_free()


func on_fixed(source_id):
	if not is_broken: return
	
	if not health or health.cur_health >= health.max_health/2.0:
			is_broken = false
			fixed.emit()
			
			if broken_particles:
				broken_particles.queue_free()
				broken_particles = null
