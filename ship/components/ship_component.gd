extends Node3D

class_name ShipComponent

signal broken
signal fixed


@export var health : Health

const BROKEN_COMPONENT_PARTICLES = preload("res://vfx/broken_component_particles.tscn")
var broken_particles : Node3D = null
var is_broken := false
@export var ship : ShipManager


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


func on_fixed():
	if not is_broken: return
	
	if not health or health.cur_health >= health.max_health/2.0:
			is_broken = false
			fixed.emit()
			
			if broken_particles:
				broken_particles.queue_free()
				broken_particles = null


func get_parent_velocity() -> Vector3:
	if ship:
		return ship.movement_manager.velocity_sync
	return Vector3.ZERO
